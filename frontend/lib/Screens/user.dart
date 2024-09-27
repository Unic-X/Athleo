import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hack_space_temp/Screens/components/bottom_nav_bar.dart';
import 'package:hack_space_temp/Screens/components/my_button.dart';
import 'package:intl/intl.dart';

class UserProfilePage extends StatefulWidget {
  final String userName;
  final int coins;
  final List<RunningData> runningData;

  const UserProfilePage({
    Key? key,
    required this.userName,
    required this.coins,
    required this.runningData,
  }) : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  String? uid = FirebaseAuth.instance.currentUser?.uid;
  String userName = 'Unknown';
  List<RunningData> runningData = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _getUsername();
  }

  void _getUsername() async {
    if (uid == null) {
      setState(() {
        isLoading = false;
        errorMessage = 'User not authenticated';
      });
      return;
    }

    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          userName = data['username'] ?? 'Unknown';
          runningData = _parseRunningData(data['week_ac']);
          isLoading = false;
        });
      } else {
        // setState(() {
        //   isLoading = false;
        //   errorMessage = 'User document not found';
        // });
      }
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load user data';
      });
    }
  }

  List<RunningData> _parseRunningData(Map<String, dynamic> data) {
    print("Data content: $data");

    List<RunningData> result = [];
    DateTime now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      DateTime date = now.subtract(Duration(days: i));
      String dayKey = DateFormat('E').format(date).toLowerCase();
      double distance = (data[dayKey] as num?)?.toDouble() ?? 0.0;
      result.add(RunningData(date, distance));
      print("Day: $dayKey, Distance: $distance");
    }

    print("Parsed running data: $result");
    return result;
  }

  @override
  Widget build(BuildContext context) {
    void _logOut() {
      FirebaseAuth.instance.signOut();
      Navigator.pushNamed(context, '/login');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Progression'),
        backgroundColor: const Color(0xFF229DAB),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child:
                      Text(errorMessage, style: TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  child: Container(
                    color: const Color(0xFFFFFCF0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Hello, $userName",
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 57, 39, 61),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.5),
                                      spreadRadius: 2,
                                      blurRadius: 5,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Image.asset(
                                      'assets/greek-coin.png',
                                      width: 24,
                                      height: 24,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '${widget.coins}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 70),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              _buildStat("Distance", "12.56 mi",
                                  const Color(0xFFf3e035)),
                              const SizedBox(width: 10),
                              _buildStat(
                                  "Time", "1h 40m", const Color(0xFFDF5C31)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            height: 250,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F1C25),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: LineChart(
                              LineChartData(
                                gridData: FlGridData(show: false),
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        int index = value.toInt();
                                        if (index >= 0 &&
                                            index < runningData.length) {
                                          return Text(
                                            DateFormat('E').format(
                                                runningData[index].date),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          );
                                        }
                                        return const Text('');
                                      },
                                      reservedSize: 22,
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          value.toStringAsFixed(0),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        );
                                      },
                                      reservedSize: 30,
                                    ),
                                  ),
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(
                                  show: true,
                                  border:
                                      Border.all(color: Colors.grey, width: 1),
                                ),
                                minX: 0,
                                maxX: runningData.length - 1.toDouble(),
                                minY: 0,
                                maxY: runningData.isNotEmpty
                                    ? runningData
                                            .map((data) => data.distance)
                                            .reduce((a, b) => a > b ? a : b) +
                                        1
                                    : 10,
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: runningData
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                      return FlSpot(entry.key.toDouble(),
                                          entry.value.distance);
                                    }).toList(),
                                    isCurved: false,
                                    color: const Color(0xFF229DAB),
                                    barWidth: 2.5,
                                    belowBarData: BarAreaData(
                                      show: true,
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFF229DAB)
                                              .withOpacity(0.3),
                                          const Color(0xFF229DAB)
                                              .withOpacity(0.0),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                    dotData: FlDotData(
                                      show: true,
                                      getDotPainter:
                                          (spot, percent, barData, index) =>
                                              FlDotCirclePainter(
                                        radius: 4,
                                        color: const Color(0xFFffffff),
                                        strokeWidth: 1.5,
                                        strokeColor: const Color(0xFF229DAB),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          MyButton(
                            text: "Log Out",
                            onTap: _logOut,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1C25),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class RunningData {
  final DateTime date;
  final double distance;

  RunningData(this.date, this.distance);

  @override
  String toString() => 'RunningData(date: $date, distance: $distance)';
}
