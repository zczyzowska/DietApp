import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const String _baseUrl = 'http://10.0.2.2:5000';
  //static const _baseUrl = 'https://serene-health-backend.onrender.com';

  static Future<bool> isTokenValid() async {
    final token = await getToken();
    if (token == null) return false;
    return !JwtDecoder.isExpired(token);
  }

  static Future<bool> ensureValidToken() async {
    final token = await getToken();
    if (token == null) return false;

    if (JwtDecoder.isExpired(token)) {
      await signUserOut();
      return false;
    }
    return true;
  }

  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt', value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'jwt');
  }

  static Future<void> removeToken() async {
    await _storage.delete(key: 'jwt');
  }

  Future<bool> verifyToken(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/auth/verify'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200;
  }

  static Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final token = data['access_token'];
      await saveToken(token);
      return true;
    } else {
      return false;
    }
  }

  static Future<void> signUserOut() async {
    await removeToken();
  }

  static Future<bool> register(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    return response.statusCode == 201;
  }

  static Future<Map<String, dynamic>?> getUserProfile() async {
    final token = await getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$_baseUrl/users/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return null;
    }
  }
}
