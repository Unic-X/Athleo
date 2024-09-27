import 'package:flutter/material.dart';
import 'package:hack_space_temp/Screens/record.dart';
import 'package:hack_space_temp/Screens/welcome.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hack_space_temp/Screens/map.dart';
import 'package:hack_space_temp/Screens/login/manage_user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const Athleo());
}

class Athleo extends StatelessWidget {
  const Athleo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthPage(),
      routes: {
        '/map': (context) => const MapScreen(),
        '/record': (context) => const RecordScreen(),
      },
      title: "Fence Mate",
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
    );
  }
}
