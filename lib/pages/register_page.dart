import 'package:diet_app/components/my_button.dart';
import 'package:diet_app/components/my_textfield.dart';
import 'package:diet_app/components/square_tile.dart';
import 'package:diet_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:diet_app/pages/login_page.dart';

class RegisterPage extends StatefulWidget {
  final Function()? onTap;
  const RegisterPage({super.key, this.onTap});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  //text editing controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureText = true;
  bool _obscureTextConfirm = true;

  Future<void> signUserUp() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showErrorMessage('Fill in all fields');
      return;
    }

    if (password != confirmPassword) {
      _showErrorMessage('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await AuthService.register(email, password);

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      } else {
        _showErrorMessage('Registration failed');
      }
    } catch (e) {
      _showErrorMessage('Error: $e');
    }

    setState(() => _isLoading = false);
  }

  void _showErrorMessage(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 222, 225, 215),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 50),
                //logo
                const Icon(Icons.person, size: 100),
                const SizedBox(height: 50),
                // welcome back
                Text(
                  'Let\'s create an account',
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
                  hintText: 'Email',
                  obscureText: false,
                ),
                const SizedBox(height: 10),
                //password textfield
                MyTextfield(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: _obscureText,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                ),
                //confirm password textfield
                const SizedBox(height: 10),
                MyTextfield(
                  controller: confirmPasswordController,
                  hintText: 'Confirm Password',
                  obscureText: _obscureTextConfirm,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureTextConfirm
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureTextConfirm = !_obscureTextConfirm;
                      });
                    },
                  ),
                ),
                SizedBox(height: 25),
                //sign in button
                _isLoading
                    ? const CircularProgressIndicator()
                    : MyButton(onTap: signUserUp, text: 'Sign Up'),
                const SizedBox(height: 50),
                // or continue with
                Row(
                  children: [
                    Expanded(
                      child: Divider(thickness: 0.5, color: Colors.black),
                    ),
                    const Text(
                      ' Or continue with',
                      style: TextStyle(
                        color: Color.fromARGB(255, 100, 99, 99),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Divider(thickness: 0.5, color: Colors.black),
                    ),
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
                      'Already have an account?',
                      style: TextStyle(
                        color: Color.fromARGB(255, 100, 99, 99),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      },
                      child: const Text(
                        'Login now',
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
      ),
    );
  }
}
