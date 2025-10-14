import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'add_meal_form_page.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'confirm_meal_screen.dart';
import 'meal_details.dart';
import 'profile_page.dart';
import 'login_page.dart';
import 'package:diet_app/services/api_service.dart';
import 'package:diet_app/services/auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> meals = [];
  double totalKcal = 0;
  double totalProtein = 0;
  double totalFats = 0;
  double totalCarbs = 0;
  double? dailyCalorieGoal;
  double? proteinGoal;
  double? fatGoal;
  double? carbGoal;
  DateTime selectedDate = DateTime.now();

  IconData _getMealIcon(String type) {
    switch (type) {
      case 'Breakfast':
        return Icons.breakfast_dining;
      case 'Second Breakfast':
        return Icons.bakery_dining;
      case 'Lunch':
        return Icons.dinner_dining;
      case 'Dessert':
        return Icons.icecream;
      case 'Dinner':
        return Icons.brunch_dining;
      case 'Snack':
        return Icons.cookie;
      default:
        return Icons.restaurant;
    }
  }

  Future<void> loadUserGoals() async {
    try {
      final data =
          await ApiService.getUserProfile(); // 🔹 GET /profile z backendu

      if (data != null && data['calculated'] != null) {
        final calculated = data['calculated'];

        setState(() {
          dailyCalorieGoal =
              calculated['kcal'] is double
                  ? calculated['kcal']
                  : double.tryParse('${calculated['kcal']}');

          proteinGoal =
              calculated['protein'] is double
                  ? calculated['protein']
                  : double.tryParse('${calculated['protein']}');

          fatGoal =
              calculated['fats'] is double
                  ? calculated['fats']
                  : double.tryParse('${calculated['fats']}');

          carbGoal =
              calculated['carbs'] is double
                  ? calculated['carbs']
                  : double.tryParse('${calculated['carbs']}');
        });
      }
    } catch (e) {
      print('Error loading user profile data: $e');
    }
  }

  Future<void> loadMeals() async {
    try {
      String date = DateFormat('yyyy-MM-dd').format(selectedDate);
      final data = await ApiService.getMeals(
        date,
      ); // GET /meals?date=yyyy-MM-dd

      if (data.isNotEmpty) {
        final loadedMeals =
            (data as List).map((meal) {
              return {
                'id': meal['id'],
                'type': meal['type'] ?? 'Not specified',
                'name': meal['name'] ?? 'Not specified',
                'grams': (meal['grams'] ?? 0).toDouble(),
                'kcal': (meal['kcal'] ?? 0).toDouble(),
                'protein': (meal['protein'] ?? 0).toDouble(),
                'fats': (meal['fats'] ?? 0).toDouble(),
                'carbs': (meal['carbs'] ?? 0).toDouble(),
                'image_url': meal['image_url'],
              };
            }).toList();

        setState(() {
          meals = loadedMeals;
          totalKcal = meals.fold(0.0, (sum, m) => sum + (m['kcal'] as double));
          totalProtein = meals.fold(
            0.0,
            (sum, m) => sum + (m['protein'] as double),
          );
          totalFats = meals.fold(0.0, (sum, m) => sum + (m['fats'] as double));
          totalCarbs = meals.fold(
            0.0,
            (sum, m) => sum + (m['carbs'] as double),
          );
        });

        print("${loadedMeals.length} meals have been loaded.");
      } else {
        // jeśli brak danych — wyczyść widok
        setState(() {
          meals = [];
          totalKcal = 0.0;
          totalProtein = 0.0;
          totalFats = 0.0;
          totalCarbs = 0.0;
        });

        print("No meals found for $date — view cleared.");
      }
    } catch (e) {
      print("Error loading data from backend: $e");

      // w razie błędu też lepiej wyczyścić widok, by uniknąć starych danych
      setState(() {
        meals = [];
        totalKcal = 0.0;
        totalProtein = 0.0;
        totalFats = 0.0;
        totalCarbs = 0.0;
      });
    }
  }

  Future<void> saveMeal(Map<String, dynamic> meal, [File? imageFile]) async {
    try {
      if (imageFile != null) {
        final imageUrl = await ApiService.uploadMealImage(
          imageFile,
        ); // POST /meals/upload
        if (imageUrl != null) {
          meal['image_url'] = imageUrl;
        }
      }

      await ApiService.addMeal(meal); // POST /meals
    } catch (e) {
      print("Error saving meal: $e");
    }
  }

  Future<Map<String, dynamic>> analyzeMealImage(File imageFile) async {
    try {
      final result = await ApiService.analyzeMealImage(
        imageFile,
      ); // POST /analyze-meal
      return result;
    } catch (e) {
      print('Error analyzing image: $e');
      return {
        'name': '',
        'grams': 0,
        'kcal': 0,
        'protein': 0,
        'fats': 0,
        'carbs': 0,
      };
    }
  }

  Future<void> _handleImagePick() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    final imageFile = File(pickedFile.path);

    _showLoadingDialog();

    final analysisResult = await analyzeMealImage(imageFile);

    if (mounted) Navigator.of(context).pop();

    if (!mounted) return;

    final confirmedMeal = await _navigateToConfirmScreen(analysisResult);

    if (!mounted) return;

    if (confirmedMeal != null) {
      await saveMeal(confirmedMeal, imageFile);
      await loadMeals();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cancelled adding meal')));
      }
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
  }

  Future<Map<String, dynamic>?> _navigateToConfirmScreen(
    Map<String, dynamic> data,
  ) {
    return Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => ConfirmMealScreen(mealData: data)),
    );
  }

  @override
  void initState() {
    super.initState();
    loadMeals();
    loadUserGoals();
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat('dd.MM.yyyy').format(selectedDate);

    return Scaffold(
      backgroundColor: const Color(0xFFE4E0E0),
      appBar: AppBar(
        title: const Text('Serene Health'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              AuthService.signUserOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            Container(
              height: 80,
              padding: const EdgeInsets.all(16.0),
              alignment: Alignment.centerLeft,
              child: const Text(
                'Menu',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            // Zakładka Profil
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              },
            ),
            // Zakładka Statystyki (na razie nieaktywna)
            const ListTile(
              leading: Icon(Icons.bar_chart, color: Colors.grey),
              title: Text('Statistics', style: TextStyle(color: Colors.grey)),
              enabled: false,
            ),
          ],
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'For: $formattedDate',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('• ${meals.length} meals'),
                    Text(
                      dailyCalorieGoal != null
                          ? '• $totalKcal kcal / $dailyCalorieGoal kcal'
                          : '• $totalKcal kcal / 2000 kcal',
                    ),
                    if (dailyCalorieGoal != null &&
                        proteinGoal != null &&
                        fatGoal != null &&
                        carbGoal != null)
                      if (dailyCalorieGoal != null &&
                          proteinGoal != null &&
                          fatGoal != null &&
                          carbGoal != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Macronutrients:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('• Protein: $totalProtein / $proteinGoal g'),
                              Text('• Fats: $totalFats / $fatGoal g'),
                              Text('• Carbs: $totalCarbs / $carbGoal g'),
                            ],
                          ),
                        ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Column(
                children: [
                  // MINI KALENDARZ
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        final day = DateTime.now().subtract(
                          Duration(days: 4 - index),
                        );
                        final isSelected =
                            DateFormat('yyyy-MM-dd').format(day) ==
                            DateFormat('yyyy-MM-dd').format(selectedDate);

                        return GestureDetector(
                          onTap: () async {
                            setState(() {
                              selectedDate = day;
                            });
                            await loadMeals();
                            await loadUserGoals(); // ← przeładuj dane dla nowego dnia
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Container(
                              width: 50,
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? Colors.amber[200]
                                        : Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${day.day}',
                                style: TextStyle(
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // LISTA POSIŁKÓW
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(8),
                      child:
                          meals.isEmpty
                              ? const Center(child: Text('No meals added yet.'))
                              : ListView.builder(
                                itemCount: meals.length,
                                itemBuilder: (context, index) {
                                  final reversedIndex =
                                      meals.length - 1 - index;
                                  final reversedMeal = meals[reversedIndex];

                                  final String type = reversedMeal['type'];
                                  final IconData icon = _getMealIcon(type);

                                  return Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    child: ListTile(
                                      leading: Icon(icon, size: 32),
                                      title: Text(
                                        type,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            reversedMeal['name'],
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text('${reversedMeal['kcal']} kcal'),
                                        ],
                                      ),
                                      onTap: () async {
                                        final updated = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => MealDetailsScreen(
                                                  meal: reversedMeal,
                                                ),
                                          ),
                                        );

                                        if (updated == true) {
                                          await loadMeals();
                                          await loadUserGoals();
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (BuildContext context) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: const Text('Take a photo'),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('This option is not available yet.'),
                        ),
                      );
                    },
                  ),
                  Builder(
                    builder:
                        (localContext) => ListTile(
                          leading: const Icon(Icons.photo),
                          title: const Text('Choose from gallery'),
                          onTap: () {
                            Navigator.pop(context);
                            _handleImagePick();
                          },
                        ),
                  ),

                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Add manually'),
                    onTap: () async {
                      Navigator.pop(context);
                      final result = await Navigator.push<Map<String, dynamic>>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddMealFormPage(),
                        ),
                      );
                      if (result != null) {
                        await saveMeal(result);
                        await loadMeals();
                      }
                    },
                  ),
                ],
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class MealTile extends StatelessWidget {
  final String title;
  final String description;

  const MealTile({super.key, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(title: Text(title), subtitle: Text(description)),
    );
  }
}
