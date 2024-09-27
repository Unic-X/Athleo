import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hack_space_temp/Screens/components/error_dialog.dart';
import 'package:hack_space_temp/Screens/components/my_button.dart';
import 'package:hack_space_temp/Screens/components/my_textfield.dart';
import 'package:hack_space_temp/Screens/components/square_tile.dart';


class Register_Page extends StatefulWidget {
  final Function()? onTap;
  const Register_Page({super.key, required this.onTap});

  @override
  State<Register_Page> createState() => _Register_Page();
}

class _Register_Page extends State<Register_Page> {
  final realusernameController =
      TextEditingController(); // Added for the real username
  final usernameController = TextEditingController(); // For email
  final passwordController = TextEditingController(); // For password

  // sign user in method
  void signUserIn() async {
    showDialog(
        context: context,
        builder: (context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        });

    try {
      // Create the user
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: usernameController.text,
              password: passwordController.text);

      // Get the user ID (UID)
      String uid = userCredential.user!.uid;

      // Store the username in Firestore using the UID
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'username':
            realusernameController.text, // Store the real username in Firestore
        'email': usernameController.text,
        'week_ac': {
          "mon": 0,
          "tue": 0,
          "wed": 0,
          "thu": 0,
          "fri": 0,
          "sat": 0,
          "sun": 0,
        },
        'coins':0,
        'today_dist':0.0,
        'today_time':0,
        'weight': 70,
        'height': 170,
        'achievements': [],
        'friends':[]// Optionally, store the email as well
      });

      Navigator.pop(context); // Close the progress indicator
    } catch (e) {
      // Handle errors (e.g., display error messages)
      showErrorDialog(context, e.toString());
    }
  }

  @override
  void dispose() {
    // Don't forget to dispose of the controllers when the widget is disposed
    realusernameController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // logo
                const Icon(
                  Icons.lock,
                  size: 100,
                ),

                const SizedBox(height: 30),

                // Create an account text
                Text(
                  'Create an account',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 24),

                // Username textfield
                MyTextField(
                  controller: realusernameController, // Corrected
                  hintText: 'Username',
                  obscureText: false,
                ),
                const SizedBox(height: 10),

                // Email textfield
                MyTextField(
                  controller: usernameController, // Email controller
                  hintText: 'Email',
                  obscureText: false,
                ),

                const SizedBox(height: 10),

                // Password textfield
                MyTextField(
                  controller: passwordController, // Password controller
                  hintText: 'Password',
                  obscureText: true,
                ),

                const SizedBox(height: 25),

                // Sign up button
                MyButton(
                  text: "Sign Up",
                  onTap: signUserIn,
                ),

                const SizedBox(height: 50),

                // Or continue with
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                          thickness: 0.5,
                          color: Colors.grey[400],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                          'Or continue with',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          thickness: 0.5,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 50),

                // Google and Apple sign-in buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    SquareTile(imagePath: 'lib/images/google.png'),
                    SizedBox(width: 25),
                    SquareTile(imagePath: 'lib/images/apple.png'),
                  ],
                ),

                const SizedBox(height: 50),

                // Already have an account? Sign in
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
