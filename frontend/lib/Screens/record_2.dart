import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: RunStatsPage(),
    );
  }
}

class RunStatsPage extends StatefulWidget {
  @override
  _RunStatsPageState createState() => _RunStatsPageState();
}

class _RunStatsPageState extends State<RunStatsPage> {
  // Initial default values
  String time = "00:00:00";
  String pace = "0:00 /KM";
  String distance = "0.00 KM";

  // This function can be modified to fetch data from the backend
  void updateStats(String newTime, String newPace, String newDistance) {
    setState(() {
      time = newTime;
      pace = newPace;
      distance = newDistance;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StatBox(
                  title: "TIME",
                  value: time,
                ),
              ],
            ),
          ),
          Divider(thickness: 2),  // Line between sections
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StatBox(
                  title: "PACE",
                  value: pace,
                ),
              ],
            ),
          ),
          Divider(thickness: 2),  // Line between sections
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StatBox(
                  title: "DISTANCE",
                  value: distance,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StatBox extends StatelessWidget {
  final String title;
  final String value;

  StatBox({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            color: Color(0xFF0F1C25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}