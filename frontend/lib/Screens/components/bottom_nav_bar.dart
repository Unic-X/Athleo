import 'package:flutter/material.dart';
import 'package:hack_space_temp/Screens/map.dart';
import 'package:hack_space_temp/Screens/milestone.dart';
import 'package:hack_space_temp/Screens/record.dart';
import 'package:hack_space_temp/Screens/user.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isOnHomeScreen = ModalRoute.of(context)?.settings.name == '/map';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10), // Adjust padding for better spacing
      margin: const EdgeInsets.all(15), // Add margin around the navbar
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8), // Slightly transparent background
        borderRadius:
            BorderRadius.circular(30), // Rounded corners for the container
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2), // Subtle shadow effect
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3), // Shadow position
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceEvenly, // Space out buttons evenly
        children: <Widget>[
          IconButton(
            onPressed: isOnHomeScreen
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MapScreen()),
                    );
                  },
            icon: const Icon(Icons.home,
                color: const Color(0xFF2CD6E9)), // White icon color for contrast
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RecordScreen()),
              );
            },
            icon: const Icon(Icons.fiber_manual_record, color:const Color(0xFF2CD6E9)),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfilePage(
                    userName: 'John Doe',
                    coins: 120,
                    runningData: [
                      RunningData('Mon', 5.2),
                      RunningData('Tue', 3.8),
                      RunningData('Wed', 6.1),
                      RunningData('Thu', 0),
                      RunningData('Fri', 7.3),
                      RunningData('Sat', 8.2),
                      RunningData('Sun', 0),
                    ],
                  ),
                ),
              );
            },
            icon: const Icon(Icons.person, color:const Color(0xFF2CD6E9)),
          ),
        ],
      ),
    );
  }
}
