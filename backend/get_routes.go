package main

import (
    "encoding/json"
    "fmt"
    "io"
    "log"
    "net/http"
    "math"
    "firebase.google.com/go/auth"
    "google.golang.org/api/iterator"
    "github.com/google/uuid"
    "strconv"
)

var GOOGLE_API_KEY string
const LAT float64 = 21.229767
const LANG float64 = 81.335884

type DirApiRes struct {
	GeocodedWaypoints []GeocodedWaypoints `json:"geocoded_waypoints"`
	Routes            []Routes            `json:"routes"`
	Status            string              `json:"status"`
}
type GeocodedWaypoints struct {
	GeocoderStatus string   `json:"geocoder_status"`
	PlaceID        string   `json:"place_id"`
	Types          []string `json:"types"`
}
type Northeast struct {
	Lat float64 `json:"lat"`
	Lng float64 `json:"lng"`
}
type Southwest struct {
	Lat float64 `json:"lat"`
	Lng float64 `json:"lng"`
}
type Bounds struct {
	Northeast Northeast `json:"northeast"`
	Southwest Southwest `json:"southwest"`
}
type Distance struct {
	Text  string `json:"text"`
	Value int    `json:"value"`
}
type Duration struct {
	Text  string `json:"text"`
	Value int    `json:"value"`
}
type Coordinates struct {
	Lat float64 `json:"lat"`
	Lng float64 `json:"lng"`
}
type Polyline struct {
	Points string `json:"points"`
}
type Steps struct {
	Distance         Distance      `json:"distance"`
	Duration         Duration      `json:"duration"`
	EndLocation      Coordinates   `json:"end_location"`
	HTMLInstructions string        `json:"html_instructions"`
	Polyline         Polyline      `json:"polyline"`
	StartLocation    Coordinates   `json:"start_location"`
	TravelMode       string        `json:"travel_mode"`
	Maneuver         string        `json:"maneuver,omitempty"`
}
type Legs struct {
	Distance          Distance      `json:"distance"`
	Duration          Duration      `json:"duration"`
	EndAddress        string        `json:"end_address"`
	EndLocation       Coordinates   `json:"end_location"`
	StartAddress      string        `json:"start_address"`
	StartLocation     Coordinates   `json:"start_location"`
	Steps             []Steps       `json:"steps"`
	TrafficSpeedEntry []any         `json:"traffic_speed_entry"`
	ViaWaypoint       []any         `json:"via_waypoint"`
}
type OverviewPolyline struct {
	Points string `json:"points"`
}
type Routes struct {
	Bounds           Bounds           `json:"bounds"`
	Copyrights       string           `json:"copyrights"`
	Legs             []Legs           `json:"legs"`
	OverviewPolyline OverviewPolyline `json:"overview_polyline"`
	Summary          string           `json:"summary"`
	Warnings         []string         `json:"warnings"`
	WaypointOrder    []int            `json:"waypoint_order"`
}

type RouteDetails struct{
    Name string            `json:"name"`
    Coord []Coordinates    `json:"coord"`
    CheckPts []Coordinates `json:"checkpts"`
}

type RouteResponse struct{
    Routes []RouteDetails `json:"routes"`
}

func getWaypoints(lat float64, lang float64, dist float64) []string{
    var waypoints string 
    var wayPointsArray []string
    latDiff :=  (0.12 * dist) / 111.0
    langDiff := (0.12 * dist) / (111.0 * math.Cos(lat * math.Pi / 180.0))

    waypoints = fmt.Sprintf("%f,%f|%f,%f|%f,%f",
        lat + latDiff, lang,
        lat, lang + langDiff,
        lat + latDiff, lang + langDiff,
        )
    wayPointsArray = append(wayPointsArray, waypoints)

    waypoints = fmt.Sprintf("%f,%f|%f,%f|%f,%f",
        lat, lang - langDiff,
        lat, lang + langDiff,
        lat + latDiff, lang - langDiff,
        )
    wayPointsArray = append(wayPointsArray, waypoints)

    waypoints = fmt.Sprintf("%f,%f|%f,%f|%f,%f",
        lat - latDiff, lang,
        lat, lang - langDiff,
        lat - latDiff, lang - langDiff,
        )
    wayPointsArray = append(wayPointsArray, waypoints)
    
    return wayPointsArray
}

func getDirectionsURL(originLat, originLng float64, waypoints string) string {
    return fmt.Sprintf(
        "https://maps.googleapis.com/maps/api/directions/json?origin=%f,%f&destination=%f,%f&waypoints=%s&mode=walking&key=%s",
        originLat, originLng, originLat, originLng, waypoints, GOOGLE_API_KEY)
}

func radians(degrees float64) float64 {
    return degrees * math.Pi / 180
}

func sphericalDistance(lat1, lng1, lat2, lng2 float64) float64 {
    const R = 6371.0

    lat1Rad := radians(lat1)
    lat2Rad := radians(lat2)
    lng1Rad := radians(lng1)
    lng2Rad := radians(lng2)

    distance := math.Acos((math.Sin(lat1Rad) * math.Sin(lat2Rad)) +
        (math.Cos(lat1Rad) * math.Cos(lat2Rad) * math.Cos(lng2Rad - lng1Rad))) * R

    return distance
}

func fetchRoutes(lat float64, lng float64, dist float64) []RouteDetails {
    var paths []RouteDetails
    wayPointsArray := getWaypoints(lat, lng, dist)
    
    for pi := range(wayPointsArray){
        url := getDirectionsURL(lat, lng, wayPointsArray[pi]);

        resp, err := http.Get(url)
        if err != nil {
            log.Fatalf("Failed to make request: %v", err)
        }
        defer resp.Body.Close()

        body, err := io.ReadAll(resp.Body)
        if err != nil {
            log.Fatalf("Failed to make request: %v", err)
        }

        var result DirApiRes
        if err := json.Unmarshal(body, &result); err != nil {
            fmt.Println("Cannot unmarshall body")
        }

        var coords []Coordinates
        if(len(result.Routes) == 0){
            continue;
        }
        for j := range(result.Routes[0].Legs){
            for s := range(result.Routes[0].Legs[j].Steps){
                pos := result.Routes[0].Legs[j].Steps[s].EndLocation
                coords = append(coords, pos)
            }
        }
        if(len(coords) > 0){
            coords = append(coords, coords[0])
        }
        routeDetails := RouteDetails{
            Name: fmt.Sprintf("Route %d",pi),
            Coord: coords,
        }
        paths = append(paths, routeDetails)
    }
    
    return paths
}

func storeRoutes(routes []RouteDetails){
    for i := range(routes){
        routeId := uuid.New().String()
        for j := 0; j < len(routes[i].Coord); j += 10 {
            var avgCoord struct{
                Coord Coordinates
            }
            avgCoord.Coord.Lat = 0.0
            avgCoord.Coord.Lng = 0.0
          
            var nearCoords []Coordinates
            if(j + 10 >= len(routes[i].Coord)){
                nearCoords = routes[i].Coord[j:]
            }else{
                nearCoords = routes[i].Coord[j:j+10]
            }
            for k := range(nearCoords){
                avgCoord.Coord.Lat = (avgCoord.Coord.Lat*float64(k) + nearCoords[k].Lat)/float64(k+1)
                avgCoord.Coord.Lng = (avgCoord.Coord.Lng*float64(k) + nearCoords[k].Lng)/float64(k+1)
            }

            _, _, err := fsClient.Collection("avgCoords").Add(ctx, map[string]interface{}{
                "avgCoord": map[string]float64{
                    "lat": avgCoord.Coord.Lat,
                    "lng": avgCoord.Coord.Lng,
                },
                "routeId": routeId,
            })
            if(err != nil){
                log.Fatalf("Failed adding routes: %v", err)
            }
            
        }
        routeData, err := json.Marshal(routes[i])
        if err != nil {
            log.Fatalf("Failed to marshal routes: %v", err)
        }
        _, _, err = fsClient.Collection("routes").Add(ctx, map[string]interface{}{
            "routeId": routeId,
            "route": string(routeData),
        })
        if(err != nil){
            log.Fatalf("Failed adding routes: %v", err)
        }
    }
}

func cachedRoutes(lat float64, lng float64) []RouteDetails {
    var routes []RouteDetails

    const offset = 0.001

    upLat := lat + offset
    downLat := lat - offset
    leftLng := lng - offset
    rightLng := lng + offset

    coordinates := []struct {
        Lat float64
        Lng float64
    }{
        {upLat, lng},
        {downLat, lng},
        {lat, rightLng},
        {lat, leftLng},
    }

    iter := fsClient.Collection("avgCoords").
        Where("avgCoord.lat", "<=", coordinates[0].Lat).
        Where("avgCoord.lat", ">=", coordinates[1].Lat).
        Where("avgCoord.lng", "<=", coordinates[2].Lng).
        Where("avgCoord.lng", ">=", coordinates[3].Lng).
        Documents(ctx)

    routeIds := map[string]bool{}

    for {
        doc, err := iter.Next()
        if err == iterator.Done {
            break
        }
        if err != nil {
            log.Fatalf("Failed to fetch avgCoords: %v", err)
        }

        routeId := doc.Data()["routeId"].(string)
        routeIds[routeId] = true
    }

    for routeId := range routeIds {
        routeDoc, err := fsClient.Collection("routes").Where("routeId", "==", routeId).Documents(ctx).Next()
        if err == iterator.Done {
            continue
        }
        if err != nil {
            log.Fatalf("Failed to fetch routes for routeId %s: %v", routeId, err)
        }

        var route RouteDetails
        routeData := routeDoc.Data()["route"].(string)
        if err := json.Unmarshal([]byte(routeData), &route); err != nil {
            log.Fatalf("Failed to unmarshal route data: %v", err)
        }

        routes = append(routes, route)
    }

    return routes
}

func setCheckpoints(routes []RouteDetails) {
    const checkpointDistance = 1.0

    for i := range routes {
        var totalDistance float64 = 0
        var lastCheckpointIndex int = 0

        for j := 1; j < len(routes[i].Coord); j++ {
            lat1 := routes[i].Coord[j-1].Lat
            lng1 := routes[i].Coord[j-1].Lng
            lat2 := routes[i].Coord[j].Lat
            lng2 := routes[i].Coord[j].Lng
            segmentDistance := sphericalDistance(lat1, lng1, lat2, lng2)

            totalDistance += segmentDistance

            if totalDistance >= checkpointDistance {
                routes[i].CheckPts = append(routes[i].CheckPts, routes[i].Coord[j])
                lastCheckpointIndex = j
                totalDistance = 0
            }
        }

        if lastCheckpointIndex < len(routes[i].Coord)-1 {
            routes[i].CheckPts = append(routes[i].CheckPts, routes[i].Coord[len(routes[i].Coord)-1])
        }

        fmt.Printf("Route %d has %d checkpoints\n", i+1, len(routes[i].CheckPts))
    }
}

func verifyIDToken(idToken string) (*auth.Token, error) {
	token, err := authClient.VerifyIDToken(ctx, idToken)
	if err != nil {
		return nil, err
	}
	return token, nil
}

func getRoutes(w http.ResponseWriter, req *http.Request){

    authHeader := req.Header.Get("Authorization")
	if authHeader == "" {
		http.Error(w, "Missing Authorization Header", http.StatusUnauthorized)
		return
	}

	token := authHeader[len("Bearer "):]

	verifiedToken, err := verifyIDToken(token)
	if err != nil {
		http.Error(w, "Invalid Token", http.StatusUnauthorized)
		return
	}

	fmt.Printf("Authenticated user UID: %s\n", verifiedToken.UID)

    queryParams := req.URL.Query()
    
    lat := queryParams.Get("lat")
    lng := queryParams.Get("lng")
    dist := queryParams.Get("dist")
    latfloat,_ := strconv.ParseFloat(lat, 64);
    lngfloat,_ := strconv.ParseFloat(lng, 64);
    distfloat,_ := strconv.ParseFloat(dist, 64);

  
    var routes []RouteDetails
    isCached := true
    routes = cachedRoutes(latfloat, lngfloat)
    if(len(routes) == 0){
        isCached = false
        routes = fetchRoutes(latfloat, lngfloat, distfloat)
    }

    fmt.Println("No of paths", len(routes))
    for i := range(routes){
        var totalDistance float64 = 0
        for j := range(routes[i].Coord){
            if(j != 0){
                lat1 := routes[i].Coord[j-1].Lat
                lng1 := routes[i].Coord[j-1].Lng
                lat2 := routes[i].Coord[j].Lat
                lng2 := routes[i].Coord[j].Lng
                totalDistance += sphericalDistance(lat1, lng1, lat2, lng2)
            }
            fmt.Printf("%v,%v,#FF0000,circle,H\n", routes[i].Coord[j].Lat, routes[i].Coord[j].Lng)
        }
        fmt.Printf("Total Distance in km :- %.2f\n", totalDistance)
        fmt.Println()
    }

    setCheckpoints(routes)
    res := RouteResponse{Routes: routes}
    jsonRes, err := json.Marshal(res)
    if(err != nil){
        w.WriteHeader(http.StatusInternalServerError)
        fmt.Fprintf(w, "Failed to generate JSON")
        return
    }

    if(isCached == false){
        storeRoutes(routes)
    }

    w.Header().Set("Content-Type", "application/json")
    w.Write(jsonRes)
}
