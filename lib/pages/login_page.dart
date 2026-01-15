import 'package:diet_app/components/my_button.dart';
import 'package:diet_app/components/my_textfield.dart';
import 'package:diet_app/components/square_tile.dart';
import 'package:flutter/material.dart';
import 'package:diet_app/services/auth_service.dart';
import 'main_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  final Function()? onTap;
  const LoginPage({super.key, this.onTap});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureText = true;

  Future<void> signUserIn() async {
    setState(() => _isLoading = true);

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fill in all fields')));
      setState(() => _isLoading = false);
      return;
    }

    try {
      final success = await AuthService.login(email, password);

      if (success) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid email or password')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login error: $e')));
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 223, 215, 225),
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
                _isLoading
                    ? const CircularProgressIndicator()
                    : MyButton(onTap: signUserIn, text: 'Sign In'),
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
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterPage(),
                          ),
                        );
                      },
                      child: Text(
                        'Register now',
                        style: TextStyle(
                          color: Colors.indigo[400],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
