import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hack_space_temp/Screens/map_style.dart';
import 'package:hack_space_temp/Screens/components/scroll_route.dart';
import 'package:hack_space_temp/Screens/components/bottom_nav_bar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:ui' as ui;
import 'dart:convert';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  BitmapDescriptor? customMarkerIcon;

  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  final DraggableScrollableController _draggableController =
      DraggableScrollableController();

  LatLng currentLocation = const LatLng(21.1282267, 81.7653267);
  final Set<Marker> markers = {};
  final Set<Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  StreamSubscription<Position>? positionStream;

  double initialChildSize = 0.2;
  double _currentZoom = 14.0;

  List<Map<String, dynamic>> routes = [];
  int? selectedRouteIndex;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    getRoutes();
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
    positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
        polylineCoordinates.add(currentLocation);
        _updateMarkerAndCamera();
        _updatePolylines();
        _checkNearbyCheckpoints();
      });
    });
  }

  void _updateMarkerAndCamera() async {
    markers.removeWhere((marker) => marker.markerId.value == 'currentPos');
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

  void getRoutes() async {
    final url = Uri.parse(
        'http://54.147.52.167:5000/getroutes?lat=${currentLocation.latitude}&lng=${currentLocation.longitude}&dist=10');

    final user = FirebaseAuth.instance.currentUser!;
    final idToken = await user.getIdToken();

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          routes = List<Map<String, dynamic>>.from(data['routes'].map((route) {
            return {
              'name': route['name'],
              'coordinates': List<LatLng>.from(route['coord']
                  .map((coord) => LatLng(coord['lat'], coord['lng']))),
              'checkpoints': List<LatLng>.from(route['checkpts']
                  .map((coord) => LatLng(coord['lat'], coord['lng']))),
            };
          }));
        });
      } else {
        print('Failed to load routes. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching routes: $e');
    }

    _updatePolylines();
  }

  Future<void> _loadCustomMarker() async {
    final ByteData data =
        await DefaultAssetBundle.of(context).load('assets/marker.png');
    final Uint8List bytes = data.buffer.asUint8List();
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 120);
    final ui.FrameInfo fi = await codec.getNextFrame();
    final image = await fi.image.toByteData(format: ui.ImageByteFormat.png);

    setState(() {
      customMarkerIcon =
          BitmapDescriptor.fromBytes(image!.buffer.asUint8List());
    });
  }

  void _updatePolylines() {
    setState(() {
      polylines.clear();
      markers.removeWhere((marker) =>
          marker.markerId.value.startsWith('arrow_') ||
          marker.markerId.value.startsWith('checkpoint_'));

      for (int i = 0; i < routes.length; i++) {
        List<LatLng> coordinates = routes[i]['coordinates'];
        polylines.add(Polyline(
          polylineId: PolylineId('route_$i'),
          points: coordinates,
          color: i == selectedRouteIndex ? Colors.blue : Colors.grey,
          width: i == selectedRouteIndex ? 5 : 3,
        ));

        // Add direction arrow
        if (coordinates.length >= 2) {
          _addDirectionArrow(coordinates, i);
        }

        // Add checkpoint markers only for the selected route
        if (i == selectedRouteIndex) {
          for (LatLng checkpoint in routes[i]['checkpoints']) {
            markers.add(Marker(
              markerId: MarkerId(
                  'checkpoint_${i}_${checkpoint.latitude}_${checkpoint.longitude}'),
              position: checkpoint,
              icon: customMarkerIcon ?? BitmapDescriptor.defaultMarker,
            ));
          }
        }
      }
    });
  }

  void _addDirectionArrow(List<LatLng> coordinates, int routeIndex) {
    for (int i = 0; i < coordinates.length - 1; i += coordinates.length ~/ 4) {
      LatLng start = coordinates[i];
      LatLng end = coordinates[i + 1];

      LatLng middlePoint = LatLng(
        (start.latitude + end.latitude) / 2,
        (start.longitude + end.longitude) / 2,
      );

      double rotation = _calculateRotation(start, end);
      markers.add(Marker(
        markerId: MarkerId('arrow_${routeIndex}_$i'),
        position: middlePoint,
        icon: customMarkerIcon ?? BitmapDescriptor.defaultMarker,
        rotation: rotation,
        anchor: Offset(0.5, 0.5),
      ));
    }
  }

  double _calculateRotation(LatLng start, LatLng end) {
    return (atan2(
              end.longitude - start.longitude,
              end.latitude - start.latitude,
            ) *
            180 /
            pi) -
        90;
  }

  void _checkNearbyCheckpoints() {
    if (selectedRouteIndex == null) return;

    List<LatLng> checkpoints = routes[selectedRouteIndex!]['checkpoints'];
    for (LatLng checkpoint in checkpoints) {
      double distance = Geolocator.distanceBetween(
        currentLocation.latitude,
        currentLocation.longitude,
        checkpoint.latitude,
        checkpoint.longitude,
      );

      if (distance <= 20) {
        print("Checkpoint reached!");
        // You can add more logic here, like showing a notification or updating UI
      }
    }
  }

  void selectRoute(int index) {
    setState(() {
      selectedRouteIndex = index;
      _updatePolylines();
    });
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
    controller.animateCamera(CameraUpdate.zoomIn());
  }

  void _zoomOut() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.zoomOut());
  }

  void _goToUserPos() async {
    final GoogleMapController controller = await _controller.future;
    setState(() {
      controller.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: currentLocation, zoom: _currentZoom)));
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
            child: Icon(Icons.location_on),
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
                          onRouteSelected: selectRoute,
                          selectedRouteIndex: selectedRouteIndex,
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
