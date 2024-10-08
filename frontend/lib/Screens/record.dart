import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hack_space_temp/Screens/record_2.dart';
import 'package:hack_space_temp/Screens/map_style.dart';
import 'package:hack_space_temp/Screens/time_manager.dart';
import 'package:geolocator/geolocator.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});
  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  final DraggableScrollableController _draggableController =
      DraggableScrollableController();
  final StreamController<double> _distanceStreamController = StreamController<double>.broadcast();
  

  LatLng currentLocation = const LatLng(21.1282267, 81.7653267);
  final Set<Marker> markers = {};
  final Set<Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  StreamSubscription<Position>? positionStream;

  double initialChildSize = 0.2;
  double _currentZoom = 14.0;

  double _totalDistance = 0.0;
  bool _isFollowingUser = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _listenToLocationChanges();
    _drawSelectedRoute();
  }

  @override
  void dispose() {
    _distanceStreamController.close();
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


  List<LatLng> checkpoints = selectedRoute['checkpoints']; // Get the checkpoints


  void _listenToLocationChanges() {
  Timer.periodic(const Duration(seconds: 3), (timer) async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print(selectedRoute);
      
      setState(() {
        LatLng newLocation = LatLng(position.latitude, position.longitude);

        // Check if the user is within 20 meters of any checkpoint
        for (LatLng checkpoint in checkpoints) {
          double distanceToCheckpoint = Geolocator.distanceBetween(
            newLocation.latitude, newLocation.longitude, 
            checkpoint.latitude, checkpoint.longitude
          );
          if (distanceToCheckpoint <= 20) {
            coinsCollected++;
            checkpoints.remove(checkpoint); // Remove the checkpoint after collecting the coin
            print('Coin collected! Total coins: $coinsCollected');
          }
        }

        if (polylineCoordinates.isNotEmpty) {
          _totalDistance += _calculateDistance(
            polylineCoordinates.last, 
            newLocation
          );
        }
        currentLocation = newLocation;
        polylineCoordinates.add(currentLocation);
        _updateMarker();
        _updatePolylines();
        _distanceStreamController.add(_totalDistance);
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  });
}

  double _calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude, 
      start.longitude, 
      end.latitude, 
      end.longitude
    );
  }

  void _printDistance() {
    print('Total distance traveled: ${_totalDistance.toStringAsFixed(2)} meters');
  }

  void _updateMarker() {
    setState(() {
      markers.removeWhere((marker) => marker.markerId.value == 'currentPos');
      markers.add(
        Marker(
          markerId: const MarkerId('currentPos'),
          position: currentLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    });
  }

  void _updateMarkerAndCamera() async {
    _updateMarker();

    if (_isFollowingUser) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: currentLocation, zoom: _currentZoom),
      ));
    }
  }

  void _updatePolylines() {
    setState(() {
      polylines.removeWhere((polyline) => polyline.polylineId.value == 'userRoute');
      polylines.add(Polyline(
        polylineId: const PolylineId('userRoute'),
        points: polylineCoordinates,
        color: Colors.blue,
        width: 5,
      ));
    });
  }

  void _drawSelectedRoute() {
    if (selectedRoute.isNotEmpty) {
      setState(() {
        polylines.add(Polyline(
          polylineId: const PolylineId('selectedRoute'),
          points: List<LatLng>.from(selectedRoute['coordinates']),
          color: Colors.red,
          width: 5,
        ));
        
        for (LatLng checkpoint in selectedRoute['checkpoints']) {
          markers.add(Marker(
            markerId: MarkerId('checkpoint_${checkpoint.latitude}_${checkpoint.longitude}'),
            position: checkpoint,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ));
        }
      });
    }
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
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: currentLocation, zoom: _currentZoom),
    ));
    setState(() {
      _isFollowingUser = true;
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
            child: const Icon(Icons.location_on),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "zoomIn",
            mini: true,
            child: const Icon(Icons.add),
            onPressed: _zoomIn,
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "zoomOut",
            mini: true,
            child: const Icon(Icons.remove),
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
        title: Text(
          selectedRoute.isNotEmpty ? selectedRoute['name'] : 'Record Your Run',
          style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF229DAB),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
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
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            onCameraMove: (CameraPosition position) {
              setState(() {
                _isFollowingUser = false;
              });
            },
          ),
          _buildZoomControls(),
          Positioned(
            bottom: 87,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF112939),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.all(15),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => RunStatsPage(distanceStream: _distanceStreamController.stream),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          const begin = Offset(0.0, 1.0);
                          const end = Offset.zero;
                          const curve = Curves.easeInOut;
                          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                          var offsetAnimation = animation.drive(tween);
                          return SlideTransition(
                            position: offsetAnimation,
                            child: child,
                          );
                        },
                        transitionDuration: const Duration(milliseconds: 300),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(20),
                    backgroundColor: const Color(0xFFFFFCF0),
                  ),
                  child: const Text('START',
                      style: TextStyle(fontSize: 18, color: Colors.black)),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.all(15),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF112939),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    onPressed: () {
                      // Handle sport button press
                    },
                    backgroundColor: const Color(0xFFFFFCF0),
                    child: const Icon(Icons.sports),
                  ),
                  FloatingActionButton(
                    onPressed: () {
                      // Handle sensor button press
                    },
                    backgroundColor: const Color(0xFFFFFCF0),
                    child: const Icon(Icons.sensors),
                  ),
                  FloatingActionButton(
                    onPressed: () {
                      // Handle music button press
                    },
                    backgroundColor: const Color(0xFFFFFCF0),
                    child: const Icon(Icons.music_note),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}