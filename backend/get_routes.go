package main

import (
    "encoding/json"
    "fmt"
    "io"
    "log"
    "net/http"
    "math"
    "firebase.google.com/go/auth"
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

func getWaypoints(lat float64, lang float64) []string{
    var waypoints string 
    var wayPointsArray []string
    latDiff := 0.3 / 111.0
    langDiff := 0.3 / (111.0 * math.Cos(lat * math.Pi / 180.0))

    waypoints = fmt.Sprintf("%f,%f|%f,%f|%f,%f",
        lat + latDiff, lang,
        lat, lang + langDiff,
        lat + latDiff, lang + langDiff,
        )
    wayPointsArray = append(wayPointsArray, waypoints)

    waypoints = fmt.Sprintf("%f,%f|%f,%f|%f,%f",
        lat - latDiff, lang,
        lat, lang + langDiff,
        lat - latDiff, lang + langDiff,
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

func fetchRoutes(lat float64, lng float64) []RouteDetails {
    var paths []RouteDetails
    wayPointsArray := getWaypoints(lat, lng)
    
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

func getCenter(routes []RouteDetails){
    for i := range(routes){
        for j := 0; j < len(routes[i].Coord); j += 5 {
            var avgCoord Coordinates
            avgCoord.Lat = 0.0
            avgCoord.Lng = 0.0
            nearCoords := routes[i].Coord[j:j+5]
            for k := range(nearCoords){
                avgCoord.Lat = (avgCoord.Lat*float64(k) + nearCoords[k].Lat)/float64(k+1)
                avgCoord.Lng = (avgCoord.Lng*float64(k) + nearCoords[k].Lng)/float64(k+1)
            }
            _, _, err := fsClient.Collection("routes").Add(ctx, map[string]interface{}{
                "avgCoord": avgCoord,
                "routes":   routes,
            })
            if(err != nil){
                log.Fatalf("Failed adding routes: %v", err)
            }
        }
    }
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
    
    fmt.Println(GOOGLE_API_KEY)

    lat := queryParams.Get("lat")
    latfloat,_ := strconv.ParseFloat(lat, 64);
    lng := queryParams.Get("lng")
    lngfloat,_ := strconv.ParseFloat(lng, 64);
    
    routes := fetchRoutes(latfloat, lngfloat)

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

    //getCenter(routes)

    w.Header().Set("Content-Type", "application/json")
    w.Write(jsonRes)
}
