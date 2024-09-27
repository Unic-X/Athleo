import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hack_space_temp/Screens/map_style.dart';
import 'package:hack_space_temp/Screens/components/scroll_route.dart';
import 'package:hack_space_temp/Screens/components/bottom_nav_bar.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  final DraggableScrollableController _draggableController = DraggableScrollableController();

  LatLng currentLocation = const LatLng(21.1282267, 81.7653267);
  final Set<Marker> markers = {};
  final Set<Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  StreamSubscription<Position>? positionStream;

  double initialChildSize = 0.2;
  double _currentZoom = 14.0;

  final List<Map<String, dynamic>> routes = [
    {
      'title': 'Miwok Loop',
      'distance': '8.5mi',
      'duration': '2h 42min',
      'elevation': '1,447 ft',
    },
    {
      'title': 'Valley Trail to Seaside',
      'distance': '7.3mi',
      'duration': '2h 15min',
      'elevation': '1,200 ft',
    },
    {
      'title': 'Marin Headlands Trail',
      'distance': '5.4mi',
      'duration': '1h 50min',
      'elevation': '900 ft',
    },
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _listenToLocationChanges();
  }

  @override
  void dispose() {
    positionStream?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      currentLocation = LatLng(position.latitude, position.longitude);
      _updateMarkerAndCamera();
    });
  }

  void _listenToLocationChanges() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        setState(() {
          currentLocation = LatLng(position.latitude, position.longitude);
          polylineCoordinates.add(currentLocation);
          _updateMarkerAndCamera();
          _updatePolylines();
        });
      }
    );
  }

  void _updateMarkerAndCamera() async {
    markers.clear();
    markers.add(
      Marker(
        markerId: const MarkerId('currentPos'),
        position: currentLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    );

    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: currentLocation, zoom: _currentZoom),
    ));
  }

  void _updatePolylines() {
    polylines.clear();
    polylines.add(Polyline(
      polylineId: const PolylineId('userTrail'),
      points: polylineCoordinates,
      color: Colors.blue,
      width: 5,
    ));
  }

  void _onMapTap() {
    setState(() {
      initialChildSize = 0.1;
    });
    _draggableController.animateTo(
      0.1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _onHandleTap() {
    setState(() {
      initialChildSize = 0.4;
    });
    _draggableController.animateTo(
      0.4,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _zoomIn() async {
    final GoogleMapController controller = await _controller.future;
    setState(() {
      _currentZoom = _currentZoom + 1;
      if (_currentZoom > 20) _currentZoom = 20;
    });
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: currentLocation, zoom: _currentZoom),
    ));
  }

  void _zoomOut() async {
    final GoogleMapController controller = await _controller.future;
    setState(() {
      _currentZoom = _currentZoom - 1;
      if (_currentZoom < 1) _currentZoom = 1;
    });
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: currentLocation, zoom: _currentZoom),
    ));
  }

  void _goToUserPos() async{
    final GoogleMapController controller = await _controller.future;
    setState(() {
      controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: currentLocation, zoom: _currentZoom)
      ));
    });
  }

  Widget _buildZoomControls() {
    return Positioned(
      top: 16,
      right: 16,
      child: Column(
        children: [
          FloatingActionButton(
            mini: true,
            onPressed: _goToUserPos,
            child: Icon(Icons.location_on), // Compass button
          ),
          SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "zoomIn",
            mini: true,
            child: Icon(Icons.add),
            onPressed: _zoomIn,
          ),
          SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "zoomOut",
            mini: true,
            child: Icon(Icons.remove),
            onPressed: _zoomOut,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Home')),
        backgroundColor: const Color(0xFF229DAB),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          GoogleMap(
            style: MapStyle().uber_style,
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: currentLocation,
              zoom: _currentZoom,
            ),
            markers: markers,
            polylines: polylines,
            onTap: (LatLng location) => _onMapTap(),
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),
          _buildZoomControls(),
          DraggableScrollableSheet(
            controller: _draggableController,
            initialChildSize: initialChildSize,
            minChildSize: 0.1,
            maxChildSize: 0.8,
            builder: (context, scrollController) {
              return GestureDetector(
                onTap: _onHandleTap,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      Expanded(
                        child: RouteList(
                          routes: routes,
                          scrollController: scrollController,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}