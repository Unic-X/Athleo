import 'package:flutter/material.dart';
import 'dart:async';
import 'package:hack_space_temp/Screens/time_manager.dart'; // Ensure you import your TimerManager

class RunStatsPage extends StatefulWidget {
  @override
  _RunStatsPageState createState() => _RunStatsPageState();
}

class _RunStatsPageState extends State<RunStatsPage> {
  String time = "00:00:00";
  String pace = "0:00 /KM";
  String distance = "0.00 KM";

  @override
  void initState() {
    super.initState();
    TimerManager().startTimer(); // Start the timer
    time = _formatTime(TimerManager().currentTime);

    // Update the time every second
    Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        int currentSeconds = TimerManager().currentTime;
        time = _formatTime(currentSeconds);
      });
    });
  }

  // Helper function to format seconds to HH:MM:SS
  String _formatTime(int seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$secs";
  }

  @override
  void dispose() {
    super.dispose();
    // Optionally stop the timer when the page is disposed
    // TimerManager().stopTimer();
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
          Divider(thickness: 2),
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
          Divider(thickness: 2),
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