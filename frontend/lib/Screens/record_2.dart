import 'package:flutter/material.dart';
import 'dart:async';
import 'package:hack_space_temp/Screens/time_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class RunStatsPage extends StatefulWidget {
  final Stream<double> distanceStream;

  RunStatsPage({Key? key, required this.distanceStream}) : super(key: key);

  @override
  _RunStatsPageState createState() => _RunStatsPageState();
}

class _RunStatsPageState extends State<RunStatsPage> {
  bool _isRunning = true;
  String time = "00:00:00";
  String pace = "0:00 /KM";
  String distance = "0.00 KM";
  late StreamSubscription<double> _distanceSubscription;
  double _totalDistance = 0.0;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    TimerManager().startTimer();
    time = _formatTime(TimerManager().currentTime);

    _distanceSubscription = widget.distanceStream.listen((newDistance) {
      setState(() {
        _totalDistance = newDistance;
        distance = (newDistance / 1000).toStringAsFixed(2) + " KM";
        _updatePace(newDistance, TimerManager().currentTime);
      });
    });

    Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        int currentSeconds = TimerManager().currentTime;
        time = _formatTime(currentSeconds);
        _updatePace(_totalDistance, currentSeconds);
      });
    });
  }

  void _updatePace(double distanceInMeters, int seconds) {
    if (distanceInMeters > 0 && seconds > 0) {
      double paceInMinutesPerKm = (seconds / 60) / (distanceInMeters / 1000);
      int paceMinutes = paceInMinutesPerKm.floor();
      int paceSeconds = ((paceInMinutesPerKm - paceMinutes) * 60).round();
      pace = "$paceMinutes:${paceSeconds.toString().padLeft(2, '0')} /KM";
    }
  }

  String _formatTime(int seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$secs";
  }

  String _getCurrentDayAbbreviation() {
    return DateFormat('E').format(DateTime.now()).toLowerCase();
  }
  
  Future<void> _pushDataToFirebase() async {
  final User? user = _auth.currentUser;
  if (user != null) {
    final String uid = user.uid;
    final int currentTime = TimerManager().currentTime;
    final String currentDay = _getCurrentDayAbbreviation();
    
    final DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
    
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(userDoc);
      
      if (!snapshot.exists) {
        throw Exception("User document does not exist!");
      }
      
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      int currentCoins = data['coins'] ?? 0; // Get existing coins
      
      // Update weekly activity data
      Map<String, dynamic> weekAc = data['week_ac'] ?? {
        "mon": 0,
        "tue": 0,
        "wed": 0,
        "thu": 0,
        "fri": 0,
        "sat": 0,
        "sun": 0,
      };
      weekAc[currentDay] = (weekAc[currentDay] ?? 0) + _totalDistance;
      
      transaction.update(userDoc, {
        'today_dist': _totalDistance,
        'today_time': currentTime,
        'week_ac': weekAc,
        'coins': currentCoins + coinsCollected, // Add the collected coins to the total
      });
    });
    
    print('Data pushed to Firebase: Distance: $_totalDistance, Time: $currentTime, Coins: $coinsCollected');
  } else {
    print('No user logged in');
  }
}


  

  void _stopRunAndPushData() async {

    
    setState(() {
      _isRunning = false;
      TimerManager().stopTimer();
    });
    
    await _pushDataToFirebase();
    
    TimerManager().reset();
    _navigateBackToRecord();
  }

  void _navigateBackToRecord() {
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
              // Pause/Resume Button
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (_isRunning) {
                      TimerManager().stopTimer();
                    } else {
                      TimerManager().startTimer();
                    }
                    _isRunning = !_isRunning;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,

                  side: BorderSide(color: Colors.black, width: 5),

                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: Icon(
                  _isRunning ? Icons.pause : Icons.play_arrow,
                  color: Colors.black,
                  size: 30,
                ),
              ),
              // Stop Button

              ElevatedButton(
                onPressed: _stopRunAndPushData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.black, width: 5),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Icon(
                  Icons.stop,
                  color: Colors.black,
                  size: 30,
                ),
              ),

            ],
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _distanceSubscription.cancel();
    super.dispose();
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