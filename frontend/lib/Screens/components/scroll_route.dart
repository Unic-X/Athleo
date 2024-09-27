import 'package:flutter/material.dart';

class RouteList extends StatelessWidget {
  final List<Map<String, dynamic>> routes;
  final ScrollController scrollController; // Add scroll controller

  const RouteList(
      {Key? key, required this.routes, required this.scrollController})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Access the current theme

    return ListView.builder(
      controller: scrollController, // Use the passed scroll controller
      itemCount: routes.length,
      itemBuilder: (context, index) {
        final route = routes[index];
        return SizedBox(
          width: MediaQuery.of(context).size.width * 0.85, // Responsive width
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  10, 10, 10, 0), // Add padding inside card
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ListTile(
                    leading: Icon(Icons.map, color: theme.primaryColor),
                    title: Text(route['title']),
                    subtitle: Text(
                      '${route['distance']} | ${route['duration']} | ${route['elevation']}',
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(elevation: 0),
                        child: Text('Save'),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {},
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
