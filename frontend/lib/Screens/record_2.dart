import 'package:flutter/material.dart';
import 'dart:async';
import 'package:hack_space_temp/Screens/time_manager.dart'; // Ensure you import your TimerManager

class RunStatsPage extends StatefulWidget {
  @override
  _RunStatsPageState createState() => _RunStatsPageState();
}

class _RunStatsPageState extends State<RunStatsPage> {
  bool _isRunning = true; // State variable to manage timer
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Toggle Button
              Container(
                decoration: BoxDecoration(
                  color: _isRunning?Color(0xFF00E5FF).withOpacity(1.0):Colors.black.withOpacity(1.0),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.all(15),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (_isRunning) {
                        TimerManager().stopTimer(); // Stop the timer
                      } else {
                        TimerManager().startTimer(); // Start the timer
                      }
                      _isRunning = !_isRunning; // Toggle the running state
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(20),
                    backgroundColor: _isRunning ? Colors.black : Color(0xFF00E5FF), // Change color based on state
                  ),
                  child: Text(
                    _isRunning ? 'PAUSE' : 'RESUME',
                    style: TextStyle(
                      fontSize: 18,
                      color: _isRunning ? Color(0xFF00E5FF) : Colors.black, // Change text color based on state
                    ),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color:Colors.red.withOpacity(1.0),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.all(15),
                child: ElevatedButton(
                  onPressed: () {
                    TimerManager().stopTimer(); // Stop the timer
                    TimerManager().reset(); // Reset the timer to 0
                    Navigator.pop(context); // Go back to RecordScreen
                },
                style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(20),
                backgroundColor: Colors.red, // Red color for the stop button
                  ),
                  child: Text('STOP',style: TextStyle(fontSize: 18, color: Colors.white), // Change text color as needed
                  ),
                ),
              ),
            ], //children
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
