import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteList extends StatelessWidget {
  final List<Map<String, dynamic>> routes;
  final ScrollController scrollController;
  final Function(int) onRouteSelected;
  final int? selectedRouteIndex;

  const RouteList({
    Key? key,
    required this.routes,
    required this.scrollController,
    required this.onRouteSelected,
    this.selectedRouteIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.builder(
      controller: scrollController,
      itemCount: routes.length,
      itemBuilder: (context, index) {
        final route = routes[index];
        final isSelected = index == selectedRouteIndex;

        return SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            color: isSelected ? theme.primaryColorLight : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ListTile(
                    leading: Icon(Icons.map, color: theme.primaryColor),
                    title: Text(route['name']),
                    subtitle: Text(
                      '${route['coordinates'].length} points | ${route['checkpoints'].length} checkpoints',
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => onRouteSelected(index),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor:
                              isSelected ? theme.primaryColor : null,
                        ),
                        child: Text(isSelected ? 'Selected' : 'Select Route'),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          // Implement route details view
                          // You can add a new screen or dialog to show more details about the route
                        },
                        style: ElevatedButton.styleFrom(elevation: 0),
                        child: Text('See Details'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
