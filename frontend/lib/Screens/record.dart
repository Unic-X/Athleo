import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hack_space_temp/Screens/record_2.dart'; // Adjust the import path accordingly

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});
  @override
  State<RecordScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<RecordScreen> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>(); // Controller for Google Map
  final DraggableScrollableController _draggableController =
      DraggableScrollableController(); // Controller for DraggableScrollableSheet

  LatLng currentLocation =
      const LatLng(21.1282267, 81.7653267); // Initial location
  final Set<Marker> markers = {};
  final Set<Polyline> polylines = {}; // Use this to draw the routes
  double initialChildSize = 0.2; // Starting size of the draggable sheet

  @override
  void initState() {
    super.initState();
    setMarker();
  }

  void setMarker() async {
    markers.add(
      Marker(
        markerId: MarkerId('currentPos'),
        position: currentLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    );
  }

  // Function to handle map tap and collapse the sheet
  void _onMapTap() {
    setState(() {
      initialChildSize = 0.1; // Collapse the sheet when map is tapped
    });
    _draggableController.animateTo(
      0.1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  // Function to handle expanding the sheet to 0.4 when clicking the handle
  void _onHandleTap() {
    setState(() {
      initialChildSize = 0.4; // Expand to 40% of the screen
    });
    _draggableController.animateTo(
      0.4,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  // Placeholder functions for each map interaction button
  void _toggleCompass() {
    // Logic to toggle compass
  }

  void _toggleLayers() {
    // Logic to toggle map layers
  }

  void _zoomIn() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.zoomIn());
  }

  void _zoomOut() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.zoomOut());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record',
            style: TextStyle(fontSize: 22)), // Title for Run Screen
        backgroundColor: const Color(0xFF229DAB),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings), // Settings button
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map section
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: currentLocation,
              zoom: 14,
            ),
            markers: markers,
            polylines: polylines,
            onTap: (LatLng location) => _onMapTap(), // Collapse on map tap
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),
          // Floating buttons for map actions (like the side panel in the image)
          Positioned(
            right: 10,
            top: 100,
            child: Column(
              children: [
                FloatingActionButton(
                  mini: true,
                  onPressed: _toggleCompass,
                  child: Icon(Icons.explore), // Compass button
                ),
                SizedBox(height: 10),
                FloatingActionButton(
                  mini: true,
                  onPressed: _toggleLayers,
                  child: Icon(Icons.layers), // Toggle map layers
                ),
                SizedBox(height: 10),
                FloatingActionButton(
                  mini: true,
                  onPressed: _zoomIn,
                  child: Icon(Icons.add), // Zoom in button
                ),
                SizedBox(height: 10),
                FloatingActionButton(
                  mini: true,
                  onPressed: _zoomOut,
                  child: Icon(Icons.remove), // Zoom out button
                ),
              ],
            ),
          ),
          // Start Button Section
          Positioned(
            bottom: 87, // Positioned near the bottom of the screen
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(
                      1.0), // Distinct background color to separate from map
                  shape: BoxShape.circle, // Circular container for Start button
                ),
                padding: const EdgeInsets.all(10), // Padding around the circle
                margin: const EdgeInsets.all(15), //margin around the circle
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => RunStatsPage(),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          const begin = Offset(0.0, 1.0); // Start at the bottom
                          const end = Offset.zero;        // End at the top (default position)
                          const curve = Curves.easeInOut; // Smooth transition curve

                          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                          var offsetAnimation = animation.drive(tween);

                          return SlideTransition(
                            position: offsetAnimation,
                            child: child,
                          );
                        },
                        transitionDuration: Duration(milliseconds: 300), // Transition speed
                      ),
                    );

                  },
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(20),
                    backgroundColor:
                        const Color(0xFF00E5FF), // Blue Start button
                  ),
                  child: const Text('START',
                      style: TextStyle(fontSize: 18, color: Colors.black)),
                ),
              ),
            ),
          ),
          // Bottom buttons (Sport, Sensor, Music) like in your image
          Positioned(
            bottom:
                0, // Adjust the bottom positioning to match the image layout
            left: 0,
            right: 0,
            child: Container(
              margin:
                  const EdgeInsets.all(15), // Add margin around the bottom bar
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(1.0),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceEvenly, // Space out buttons evenly
                children: [
                  FloatingActionButton(
                    onPressed: () {
                      // Handle sport button press
                    },
                    child: Icon(Icons.sports), // Icon for sport
                    backgroundColor: const Color(0xFF00E5FF),
                  ),
                  FloatingActionButton(
                    onPressed: () {
                      // Handle sensor button press
                    },
                    child: Icon(Icons.sensors), // Icon for sensor
                    backgroundColor: const Color(0xFF00E5FF),
                  ),
                  FloatingActionButton(
                    onPressed: () {
                      // Handle music button press
                    },
                    child: Icon(Icons.music_note), // Icon for music
                    backgroundColor: const Color(0xFF00E5FF),
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
