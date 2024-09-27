import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hack_space_temp/Screens/components/bottom_nav_bar.dart'; //import NavBar

class UserProfilePage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Progression'),
        backgroundColor: const Color(0xFF229DAB),
      ),
      body: Container(
        color: const Color(0xFFFFFCF0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between Hello and the coin box
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Padding inside the box
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 57, 39, 61), // Background color for the box
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5), // Shadow color
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3), // Shadow position
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/greek-coin.png', // Path to your coin image asset
                          width: 24,
                          height: 24,
                        ),
                        const SizedBox(width: 5), // Space between image and coin amount
                        Text(
                          '$coins',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // White text for better visibility on dark background
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 70),
              Row(
                mainAxisAlignment: MainAxisAlignment.start, // Aligns both boxes to the left
                children: [
                  _buildStat("Distance", "12.56 mi", const Color(0xFFf3e035)),
                  const SizedBox(width: 10), // Space between the two boxes
                  _buildStat("Time", "1h 40m", const Color(0xFFDF5C31)),
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
                            return Text(
                              index >= 0 && index < runningData.length
                                  ? runningData[index].day
                                  : '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            );
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
                      border: Border.all(color: Colors.grey, width: 1),
                    ),
                    minX: 0,
                    maxX: runningData.length - 1.toDouble(),
                    minY: 0,
                    maxY: runningData.map((data) => data.distance).reduce((a, b) => a > b ? a : b) + 1, // Dynamic maxY
                    lineBarsData: [
                      LineChartBarData(
                        spots: runningData.asMap().entries.map((entry) {
                          return FlSpot(entry.key.toDouble(), entry.value.distance);
                        }).toList(),
                        isCurved: false,
                        color: const Color(0xFF229DAB), // Line color
                        barWidth: 2.5,
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF229DAB).withOpacity(0.3),
                              const Color(0xFF229DAB).withOpacity(0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        dotData: FlDotData(
                          show: true,
                          checkToShowDot: (spot, barData) {
                            return true; // Show dots for all spots
                          },
                          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
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
              // const SizedBox(height: 20),
              // Center(
              //   child: Text(
              //     'Coins: $coins',
              //     style: const TextStyle(
              //       fontSize: 18,
              //       fontWeight: FontWeight.bold,
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
  return Container(
    padding: const EdgeInsets.all(12), // Padding inside the box
    decoration: BoxDecoration(
      color: const Color(0xFF0F1C25), // Black background for the box
      borderRadius: BorderRadius.circular(10),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.5), // Shadow color
          spreadRadius: 2,
          blurRadius: 5,
          offset: const Offset(0, 3), // Shadow position
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Align content to the left
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16, // Smaller font size for the value
            fontWeight: FontWeight.bold,
            color: color, // Original color for the value
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70, // White for the label text
          ),
        ),
      ],
    ),
  );
}

}

class RunningData {
  final String day;
  final double distance;

  RunningData(this.day, this.distance);
}

// Example usage:
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    List<RunningData> runningData = [
      RunningData('Mon', 5.2),
      RunningData('Tue', 3.8),
      RunningData('Wed', 6.1),
      RunningData('Thu', 4.5),
      RunningData('Fri', 7.3),
      RunningData('Sat', 8.2),
      RunningData('Sun', 5.9),
    ];

    return MaterialApp(
      home: UserProfilePage(
        userName: 'John Doe',
        coins: 120,
        runningData: runningData,
      ),
    );
  }
}
