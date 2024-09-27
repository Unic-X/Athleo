import 'package:flutter/material.dart';
import 'package:hack_space_temp/Screens/map.dart';
import 'package:hack_space_temp/Screens/record.dart';
import 'package:hack_space_temp/Screens/user.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isOnHomeScreen = ModalRoute.of(context)?.settings.name == '/map';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      margin: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
            icon: const Icon(Icons.home, color: Color(0xFF2CD6E9)),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RecordScreen()),
              );
            },
            icon:
                const Icon(Icons.fiber_manual_record, color: Color(0xFF2CD6E9)),
          ),
          IconButton(
            onPressed: () {
              final now = DateTime.now();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfilePage(
                    userName: 'John Doe',
                    coins: 120,
                    runningData: [
                      RunningData(now.subtract(const Duration(days: 6)), 5.2),
                      RunningData(now.subtract(const Duration(days: 5)), 3.8),
                      RunningData(now.subtract(const Duration(days: 4)), 6.1),
                      RunningData(now.subtract(const Duration(days: 3)), 0),
                      RunningData(now.subtract(const Duration(days: 2)), 7.3),
                      RunningData(now.subtract(const Duration(days: 1)), 8.2),
                      RunningData(now, 0),
                    ],
                  ),
                ),
              );
            },
            icon: const Icon(Icons.person, color: Color(0xFF2CD6E9)),
          ),
        ],
      ),
    );
  }
}
