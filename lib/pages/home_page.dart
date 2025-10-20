import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'meal_details.dart';
import 'package:diet_app/services/api_service.dart';
import 'package:diet_app/widgets/add_meal_button.dart';

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

  @override
  void initState() {
    super.initState();
    loadMeals();
    loadUserGoals();
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat('dd.MM.yyyy').format(selectedDate);

    return Stack(
      children: [
        Padding(
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
                              await loadUserGoals();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
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
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(8),
                        child:
                            meals.isEmpty
                                ? const Center(
                                  child: Text('No meals added yet.'),
                                )
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
                                            Text(
                                              '${reversedMeal['kcal']} kcal',
                                            ),
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
        Positioned(
          bottom: 20,
          right: 20,
          child: AddMealButton(
            onMealSaved: (meal, [imageFile]) async {
              await loadMeals();
              await loadUserGoals();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('New meal added successfully!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ),
      ],
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
