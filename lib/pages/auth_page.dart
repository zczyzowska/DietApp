import 'package:diet_app/pages/login_or_register_page.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'package:diet_app/services/auth_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final token = await AuthService.getToken();

    if (token == null) {
      setState(() {
        _isLoading = false;
        _isLoggedIn = false;
      });
      return;
    }

    try {
      final authService = AuthService();
      final isValid = await authService.verifyToken(token);

      setState(() {
        _isLoading = false;
        _isLoggedIn = isValid;
      });
    } catch (e) {
      print('Error verifying token: $e');
      await AuthService.removeToken();
      setState(() {
        _isLoading = false;
        _isLoggedIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return _isLoggedIn ? const HomePage() : const LoginOrRegisterPage();
  }
}
