import 'package:diet_app/components/my_button.dart';
import 'package:diet_app/components/my_textfield.dart';
import 'package:diet_app/components/square_tile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  //text editing controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void signUserIn() async {
    showDialog(
      context: context,
      builder: (context) {
        return const Center(child: CircularProgressIndicator());
      },
    );
    try {
      //sign user in
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      Navigator.pop(context); // close the loading circle
    } on FirebaseAuthException {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Email or Password is incorrect'),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 222, 225, 215),
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 50),
              //logo
              const Icon(Icons.person, size: 100),
              const SizedBox(height: 50),
              // welcome back
              Text(
                'Welcome back! Sign in to continue',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              //username textfield
              MyTextfield(
                controller: emailController,
                hintText: 'Username',
                obscureText: false,
              ),
              const SizedBox(height: 10),
              //password textfield
              MyTextfield(
                controller: passwordController,
                hintText: 'Password',
                obscureText: true,
              ),
              const SizedBox(height: 10),
              //forgot password?
              Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 14,
                  color: const Color.fromARGB(255, 110, 106, 106),
                ),
              ),
              SizedBox(height: 25),
              //sign in button
              MyButton(onTap: signUserIn, text: 'Sign In'),
              const SizedBox(height: 50),
              // or continue with
              Row(
                children: [
                  Expanded(child: Divider(thickness: 0.5, color: Colors.black)),
                  const Text(
                    ' Or continue with',
                    style: TextStyle(
                      color: Color.fromARGB(255, 100, 99, 99),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(child: Divider(thickness: 0.5, color: Colors.black)),
                ],
              ),
              SizedBox(height: 50),
              //google button + apple sign in button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SquareTile(imagePath: 'lib/images/google.png'),
                  SizedBox(width: 25),
                  SquareTile(imagePath: 'lib/images/apple.png'),
                ],
              ),
              const SizedBox(height: 50),
              //not a member? register now
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Not a member?',
                    style: TextStyle(
                      color: Color.fromARGB(255, 100, 99, 99),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      //navigate to register page
                    },
                    child: const Text(
                      'Register now',
                      style: TextStyle(
                        color: Color.fromARGB(255, 213, 134, 54),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
