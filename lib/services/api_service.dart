import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:5000';
  //static const String baseUrl = 'https://serene-health-backend.onrender.com';

  static Future<Map<String, dynamic>?> updateUserProfile(
    Map<String, dynamic> profileData,
  ) async {
    final token = await AuthService.getToken();

    final url = Uri.parse('$baseUrl/profile');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await http.post(
      url,
      headers: headers,
      body: json.encode(profileData),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data;
    } else {
      print('Error saving profile: ${response.body}');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getUserProfile() async {
    final token = await AuthService.getToken();

    final url = Uri.parse('$baseUrl/profile');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data;
    } else {
      print('Error getting profile: ${response.body}');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getMeals(String? date) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('$baseUrl/meals${date != null ? '?date=$date' : ''}');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['meals']);
    } else {
      throw Exception('Error fetching meals: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> toggleFavorite(int mealId) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('$baseUrl/favorites/$mealId/toggle-favorite');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(response.body));
    } else {
      throw Exception('Error toggling favorite: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>?> getMealById(String mealId) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('$baseUrl/meals/$mealId');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Map<String, dynamic>.from(data['meal']);
    } else {
      print('Error fetching meal: ${response.body}');
      return null;
    }
  }

  static Future<Map<String, dynamic>> addMeal(Map<String, dynamic> meal) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('$baseUrl/meals');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final response = await http.post(
      uri,
      headers: headers,
      body: json.encode(meal),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body)['meal'];
    } else {
      throw Exception('Error adding meal: ${response.body}');
    }
  }

  static Future<bool> editMeal(
    int mealId,
    Map<String, dynamic> mealData,
  ) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('$baseUrl/meals/$mealId');
    final response = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(mealData),
    );

    return response.statusCode == 200;
  }

  static Future<bool> deleteMeal(int mealId) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('$baseUrl/meals/$mealId');
    final response = await http.delete(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }

  static Future<String?> uploadMealImage(
    File imageFile,
    String category,
  ) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('$baseUrl/meals/images/upload');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );
    request.fields['category'] = category;

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['image_url'];
    } else {
      throw Exception('Error uploading image: ${response.body}');
    }
  }

  static Future<String?> getMealImageUrl(String imageUrl) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('$baseUrl/meals/images/get_signed_url?key=$imageUrl');

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['image_url'];
    } else {
      throw Exception('Error fetching signed URL: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> analyzeMealImage(File imageFile) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('$baseUrl/meals/analyze-meal');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(response.body));
    } else {
      throw Exception('Error analyzing image: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> analyzeMealImageCustom(
    File imageFile,
  ) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('$baseUrl/food-analysis/analyze-image');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(response.body));
    } else {
      throw Exception('Error analyzing image: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> getFoodInfo(String foodName) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse(
      '$baseUrl/food-analysis/food-info?food_name=$foodName',
    );

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(response.body));
    } else {
      throw Exception('Error fetching food info: ${response.body}');
    }
  }

  // Obliczenie makro dla wybranej porcji
  static Future<Map<String, dynamic>> calculateMacro({
    required String foodName,
    required int portionWeight,
    int portionCount = 1,
  }) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('$baseUrl/food-analysis/calculate-macro');

    final body = json.encode({
      'food_name': foodName,
      'portion_weight': portionWeight,
      'portion_count': portionCount,
    });

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(response.body));
    } else {
      throw Exception('Error calculating macro: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> saveMeal(
    Map<String, dynamic> meal, [
    File? imageFile,
  ]) async {
    try {
      String? imageUrl;

      if (imageFile != null) {
        imageUrl = await uploadMealImage(imageFile, 'meal');
        if (imageUrl != null) {
          meal['image_url'] = imageUrl;
        }
      }

      final savedMeal = await addMeal(meal);
      return savedMeal;
    } catch (e) {
      throw Exception('Error saving meal: $e');
    }
  }

  static Future<Map<String, dynamic>> saveFavorite(
    Map<String, dynamic> favorite, [
    File? imageFile,
  ]) async {
    try {
      String? imageUrl;

      if (imageFile != null) {
        imageUrl = await uploadMealImage(imageFile, 'favorite');
        if (imageUrl != null) {
          favorite['image_url'] = imageUrl;
        }
      }

      final savedFavorite = await addFavorite(favorite);
      return savedFavorite;
    } catch (e) {
      throw Exception('Error saving favorite: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getFavorites({String? type}) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse(
      '$baseUrl/favorites${type != null ? '?type=$type' : ''}',
    );
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Error fetching favorites: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> addFavorite(
    Map<String, dynamic> favorite,
  ) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('$baseUrl/favorites/');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final response = await http.post(
      uri,
      headers: headers,
      body: json.encode(favorite),
    );

    if (response.statusCode == 201) {
      return {'message': 'Favorite added'};
    } else {
      throw Exception('Error adding favorite: ${response.body}');
    }
  }

  static Future<bool> updateFavorite(int id, Map<String, dynamic> data) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('$baseUrl/favorites/$id');
    final response = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );
    return response.statusCode == 200;
  }

  static Future<bool> deleteFavorite(int id) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('$baseUrl/favorites/$id');
    final response = await http.delete(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200;
  }

  static Future<bool> addFavoriteToHistory(
    int id, {
    double? grams,
    String? date,
  }) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('$baseUrl/favorites/$id/add-to-history');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        if (grams != null) 'grams': grams,
        if (date != null) 'date': date,
      }),
    );
    return response.statusCode == 201;
  }

  static Future<Map<String, dynamic>> getWeeklyStats(String date) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('$baseUrl/stats/weekly?date=$date');

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(response.body));
    } else {
      throw Exception('Error fetching weekly stats: ${response.body}');
    }
  }
}
