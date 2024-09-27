import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hack_space_temp/Screens/map_style.dart';
import 'package:hack_space_temp/Screens/components/scroll_route.dart'; // Import the RouteList component
import 'package:hack_space_temp/Screens/components/bottom_nav_bar.dart'; //import NavBar

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>(); // Controller for Google Map
  final DraggableScrollableController _draggableController =
      DraggableScrollableController(); // Controller for DraggableScrollableSheet

  LatLng currentLocation =
      const LatLng(21.1282267, 81.7653267); // Initial location
  final Set<Marker> markers = {};
  final Set<Polyline> polylines = {}; // Use this to draw the routes
  double initialChildSize = 0.2; // Starting size of the draggable sheet

  // Sample route data
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Home')),
        backgroundColor: const Color(0xFF229DAB),
        automaticallyImplyLeading: false, // Center the Home title
      ),
      body: Stack(
        children: [
          // Map section
          GoogleMap(
            style: MapStyle().uber_style,
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
          // Draggable Scrollable Sheet for RouteList
          DraggableScrollableSheet(
            controller: _draggableController, // Attach the controller
            initialChildSize: initialChildSize, // Use the dynamic initial size
            minChildSize: 0.1, // Minimum size when collapsed
            maxChildSize: 0.8, // Maximum size when expanded
            builder: (context, scrollController) {
              return GestureDetector(
                onTap: _onHandleTap, // Expand to 0.4 when tapping the handle
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
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
                      // Grey handle
                      Container(
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      // RouteList
                      Expanded(
                        child: RouteList(
                          routes: routes,
                          scrollController:
                              scrollController, // Pass the controller
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
      // Use the BottomNavBar component
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
