import 'package:flutter/material.dart';
import 'dart:async';
import 'package:hack_space_temp/Screens/time_manager.dart';

class RunStatsPage extends StatefulWidget {
  @override
  _RunStatsPageState createState() => _RunStatsPageState();
}

class _RunStatsPageState extends State<RunStatsPage> {
  bool _isRunning = true;
  String time = "00:00:00";
  String pace = "0:00 /KM";
  String distance = "0.00 KM";

  @override
  void initState() {
    super.initState();
    TimerManager().startTimer();
    time = _formatTime(TimerManager().currentTime);

    Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        int currentSeconds = TimerManager().currentTime;
        time = _formatTime(currentSeconds);
      });
    });
  }

  String _formatTime(int seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$secs";
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _navigateBackToRecord() {
    // Navigate back to record.dart
    Navigator.of(context).pop();
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
                StatBox(title: "TIME", value: time),
              ],
            ),
          ),
          Divider(thickness: 2),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StatBox(title: "PACE", value: pace),
              ],
            ),
          ),
          Divider(thickness: 2),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StatBox(title: "DISTANCE", value: distance),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Pause Button
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (_isRunning) {
                      TimerManager().stopTimer(); // Pause the timer
                    } else {
                      TimerManager().startTimer(); // Resume the timer
                    }
                    _isRunning = !_isRunning;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRunning ? Colors.orange : Color(0xFF00E5FF),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text(
                  _isRunning ? 'PAUSE' : 'RESUME',
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
              ),
              // Stop Button
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    TimerManager().stopTimer(); // Stop the timer
                    TimerManager().reset(); // Reset the timer to zero
                    _isRunning = false;
                    time = "00:00:00";
                  });
                  _navigateBackToRecord(); // Navigate back to record.dart
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text(
                  'STOP',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
          SizedBox(height: 20), // Add some space at the bottom
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