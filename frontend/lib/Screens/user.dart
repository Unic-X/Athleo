import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hack_space_temp/Screens/components/bottom_nav_bar.dart';
// import 'package:hack_space_temp/Screens/components/my_button.dart';
import 'package:intl/intl.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

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
String advice = '';
Future<String> generateAdvice({
    required double todayDist,
    required int todayTime,
    required Map<String, dynamic> weekAc,
    required int height,
    required int weight,
  }) async {
    String userDataSummary = '''
    Today, you ran a distance of $todayDist meters in $todayTime seconds.
    Your weekly activity summary is: ${weekAc.map((key, value) => MapEntry(key, '${value.toString()} meters'))}.
    Your height is ${height.toStringAsFixed(2)} meters and your weight is ${weight.toStringAsFixed(2)} kilograms.
    ''';

    final model = GenerativeModel(
      model: 'gemini-1.5-pro',
      apiKey: 'AIzaSyACou9Lb1KnQ4GHZtK-ci4_WGZNlfgD2pE',
    );
    
    final prompt = '''
    Based on the following user data, provide personalized health and fitness advice:
    
    $userDataSummary
    
    Please include recommendations for improving fitness, diet tips, and any suggestions for running efficiency.
    ''';

    try {
      final result = await model.generateContent([Content.text(prompt)]);
      return result.text ?? 'No advice generated.';
    } catch (e) {
      print('Error generating content: $e');
      return 'Failed to generate advice. Please try again later.';
    }
  }


// void main() async {
//   await generateAdvice();
// }

List<FriendData> friendLeaderboard = [];

class _UserProfilePageState extends State<UserProfilePage> {
  String? uid = FirebaseAuth.instance.currentUser?.uid;
  String userName = 'Unknown';
  int coins = 0;
  double today_dist = 0;
  int today_time = 0;
  List achievements = [];
  List friends = [];
  List<RunningData> runningData = [];
  bool isLoading = true;
  String errorMessage = '';
  String aiAdvice = '';
  bool isGeneratingAdvice = false;

  @override
  void initState() {
    super.initState();
    _getUserdata();
  }


  String formatDistance(double distance) {
    if (distance >= 1000) {
      return "${(distance / 1000).toStringAsFixed(2)}";  // Convert to KM and truncate to 2 decimal places
    } else {
      return "${distance.toStringAsFixed(2)}";  // Truncate to 2 decimal places
    }
  }

  String formatTime(int seconds) {
    if (seconds >= 60) {
      int minutes = seconds ~/ 60;
      int remainingSeconds = seconds % 60;
      return "${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}";  // Convert to MM:SS format
    } else {
      return "$seconds";  // Display in seconds if less than 60
    }
  }

  void _getUserdata() async {
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
          userName =
              userName[0].toUpperCase() + userName.substring(1).toLowerCase();
          runningData = _parseRunningData(data['week_ac']);
          coins = data['coins'];
          today_dist = data['today_dist'];
          today_time = data['today_time'];
          achievements = data['achievements'];
          friends = data['friends'];
        });

        // Fetch friends' data
        await _fetchFriendsData();
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'User document not found';
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load user data';
      });
    }
  }

  Future<void> _fetchFriendsData() async {
    List<FriendData> fetchedFriends = [];

    for (String friendUid in friends) {
      try {
        DocumentSnapshot friendDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(friendUid)
            .get();

        if (friendDoc.exists) {
          Map<String, dynamic> friendData = friendDoc.data() as Map<String, dynamic>;

          // Ensure today_dist is treated as double
          double todayDist = (friendData['today_dist'] as num?)?.toDouble() ?? 0.0;
          int todayTime = friendData['today_time'] ?? 0;

          fetchedFriends.add(
            FriendData(
              // uid: friendUid,
              username: friendData['username'],
              todayDist: todayDist,
              todayTime: todayTime,
            ),
          );
        }
      } catch (e) {
        print("Error fetching friend data for UID $friendUid: $e");
      }
    }

    fetchedFriends.sort((a, b) => b.todayDist.compareTo(a.todayDist));  // Sort by distance

    setState(() {
      friendLeaderboard = fetchedFriends;
      isLoading = false;
    });
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
        title: const Text(
          'Your Progression',
          style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF229DAB),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logOut,
          ),
        ],
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
                                  fontFamily: 'Comfortaa',
                                  fontSize: 28,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                  letterSpacing: 0.5,
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
                                      '$coins',
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
                              _buildStat('Distance', formatDistance(today_dist),
                                  const Color(0xFFf3e035)),
                              const SizedBox(width: 10),
                              _buildStat('Time', formatTime(today_time),
                                  const Color(0xFFDF5C31)),
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
                          const SizedBox(height: 30),
                          _buildLeaderboard(),  // Leaderboard added here
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

  Widget _buildLeaderboard() {
  // Create a combined leaderboard list with the user and friends
  List<FriendData> fullLeaderboard = [
    FriendData(username: userName, todayDist: today_dist, todayTime: today_time)
  ]..addAll(friendLeaderboard);

  // Sort the leaderboard based on distance
  fullLeaderboard.sort((a, b) => b.todayDist.compareTo(a.todayDist));

  return Container(
    decoration: BoxDecoration(
      color: Colors.white, // Background color for the leaderboard
      borderRadius: BorderRadius.circular(12), // Rounded corners
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.5), // Shadow color
          spreadRadius: 2, // Spread radius
          blurRadius: 5, // Blur radius
          offset: const Offset(0, 3), // Shadow offset
        ),
      ],
    ),
    padding: const EdgeInsets.all(16), // Padding for the container
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Leaderboard',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        fullLeaderboard.isEmpty
            ? const Text(
                "No data to show.",
                style: TextStyle(color: Colors.grey),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: fullLeaderboard.length,
                itemBuilder: (context, index) {
                  final participant = fullLeaderboard[index];
                  return ListTile(
                    leading: Text(
                      '#${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    title: Text(
                      participant.username == userName
                          ? 'You'
                          : participant.username,
                    ),
                    subtitle: Text(
                      'Distance: ${formatDistance(participant.todayDist)}, Time: ${formatTime(participant.todayTime)}',
                    ),
                    tileColor: participant.username == userName
                        ? Colors.yellow.withOpacity(0.2) // Highlight the user
                        : null,
                  );
                },
              ),
        const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: isGeneratingAdvice ? null : () async {
                setState(() {
                  isGeneratingAdvice = true;
                });
                try {
                  DocumentSnapshot userDoc =
                    await FirebaseFirestore.instance.collection('users').doc(uid).get();
                  Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
                  String generatedAdvice = await generateAdvice(
                    todayDist: today_dist,
                    todayTime: today_time,
                    weekAc: data['week_ac'],
                    height: data['height'],
                    weight: data['weight'],
                  );
                  setState(() {
                    aiAdvice = generatedAdvice;
                    isGeneratingAdvice = false;
                  });
                } catch (e) {
                  print('Error generating advice: $e');
                  setState(() {
                    aiAdvice = 'Failed to generate advice. Please try again later.';
                    isGeneratingAdvice = false;
                  });
                }
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF229DAB),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: isGeneratingAdvice
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'AI Coach',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            ),
          ),
          if (aiAdvice.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI Coach Advice:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    aiAdvice,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }




}

class FriendData {
  // final String uid;
  final String username;
  final double todayDist;
  final int todayTime;

  FriendData({
    // required this.uid,
    required this.username,
    required this.todayDist,
    required this.todayTime,
  });
}


class RunningData {
  final DateTime date;
  final double distance;

  RunningData(this.date, this.distance);

  @override
  String toString() => 'RunningData(date: $date, distance: $distance)';
}