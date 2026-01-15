import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'meal_details.dart';
import 'package:diet_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> meals = [];
  Set<int> favoriteMealIds = {};
  double totalKcal = 0;
  double totalProtein = 0;
  double totalFats = 0;
  double totalCarbs = 0;
  double? dailyCalorieGoal;
  double? proteinGoal;
  double? fatGoal;
  double? carbGoal;
  DateTime selectedDate = DateTime.now();
  int activeIndex = 0;

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
      final prefs = await SharedPreferences.getInstance();

      final double? kcal = prefs.getDouble('kcal');
      final double? protein = prefs.getDouble('protein');
      final double? fats = prefs.getDouble('fats');
      final double? carbs = prefs.getDouble('carbs');

      if (kcal != null && protein != null && fats != null && carbs != null) {
        setState(() {
          dailyCalorieGoal = kcal;
          proteinGoal = protein;
          fatGoal = fats;
          carbGoal = carbs;
        });

        print('Goals loaded from SharedPreferences');
        return;
      }

      // 🔸 Jeśli brak lokalnych danych — pobierz z backendu
      final data = await ApiService.getUserProfile();
      if (data != null && data['calculated'] != null) {
        final calculated = data['calculated'];

        final kcalValue = (calculated['kcal'] as num?)?.toDouble() ?? 0.0;
        final proteinValue = (calculated['protein'] as num?)?.toDouble() ?? 0.0;
        final fatsValue = (calculated['fats'] as num?)?.toDouble() ?? 0.0;
        final carbsValue = (calculated['carbs'] as num?)?.toDouble() ?? 0.0;

        // 🔹 Zapisz do SharedPreferences
        await prefs.setDouble('kcal', kcalValue);
        await prefs.setDouble('protein', proteinValue);
        await prefs.setDouble('fats', fatsValue);
        await prefs.setDouble('carbs', carbsValue);

        // 🔹 Ustaw w stanie
        setState(() {
          dailyCalorieGoal = kcalValue;
          proteinGoal = proteinValue;
          fatGoal = fatsValue;
          carbGoal = carbsValue;
        });

        print('Goals fetched from API and saved locally');
      }
    } catch (e) {
      print('Error loading user goals: $e');
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
                'favorite_id': meal['favorite_id'] ?? 0,
                'is_favorite': (meal['favorite_id'] ?? 0) != 0,
              };
            }).toList();

        setState(() {
          meals = loadedMeals;
          totalKcal = meals.fold(0.0, (sum, m) => sum + (m['kcal'] as double));
          totalKcal = double.parse(totalKcal.toStringAsFixed(2));
          totalProtein = meals.fold(
            0.0,
            (sum, m) => sum + (m['protein'] as double),
          );
          totalProtein = double.parse(totalProtein.toStringAsFixed(2));
          totalFats = meals.fold(0.0, (sum, m) => sum + (m['fats'] as double));
          totalFats = double.parse(totalFats.toStringAsFixed(2));
          totalCarbs = meals.fold(
            0.0,
            (sum, m) => sum + (m['carbs'] as double),
          );
          totalCarbs = double.parse(totalCarbs.toStringAsFixed(2));
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

  Future<void> _pickDateFromCalendar() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      await loadMeals();
      await loadUserGoals();
    }
  }

  Future<void> toggleFavorite(Map<String, dynamic> meal) async {
    int mealId = meal['id'];

    try {
      final response = await ApiService.toggleFavorite(mealId);

      if (response['is_favorite'] != null) {
        setState(() {
          meal['is_favorite'] = response['is_favorite'];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['is_favorite']
                  ? "Added to favorites"
                  : "Removed from favorites",
            ),
          ),
        );
      }
    } catch (e) {
      print('Error toggling favorite: $e');
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
    final String formattedDate = DateFormat(
      'EEEE, d MMMM y',
    ).format(selectedDate);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // PANEL Z WYKRESAMI
            SizedBox(
              height: 260,
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _getActiveLabel(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_left, size: 28),
                            onPressed: () {
                              setState(() {
                                activeIndex = (activeIndex - 1) % 4;
                                if (activeIndex < 0) activeIndex = 3;
                              });
                            },
                          ),
                          Expanded(child: Center(child: _buildActiveCircle())),
                          IconButton(
                            icon: const Icon(Icons.arrow_right, size: 28),
                            onPressed: () {
                              setState(() {
                                activeIndex = (activeIndex + 1) % 4;
                              });
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 5),

                      _buildMiniCirclesRow(activeIndex),
                    ],
                  ),
                ),
              ),
            ),

            // --- DNI TYGODNIA ---
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
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
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Container(
                              width: 40,
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
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_month_sharp, size: 30),
                  onPressed: _pickDateFromCalendar,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // --- LISTA POSIŁKÓW ---
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(12),
              child:
                  meals.isEmpty
                      ? const Center(child: Text('No meals added yet.'))
                      : _buildMealsList(meals),
            ),
          ],
        ),
      ),
    );
  }

  String _getActiveLabel() {
    switch (activeIndex) {
      case 0:
        return "Calories";
      case 1:
        return "Protein";
      case 2:
        return "Fats";
      case 3:
        return "Carbs";
      default:
        return "";
    }
  }

  Widget _buildActiveCircle() {
    switch (activeIndex) {
      case 0:
        return _buildBigCircle("kcal", totalKcal, dailyCalorieGoal ?? 2000);
      case 1:
        return _buildBigCircle("g", totalProtein, proteinGoal ?? 1);
      case 2:
        return _buildBigCircle("g", totalFats, fatGoal ?? 1);
      case 3:
        return _buildBigCircle("g", totalCarbs, carbGoal ?? 1);
      default:
        return Container();
    }
  }

  Widget _buildBigCircle(String label, double value, double goal) {
    final percent = (value / goal).clamp(0.0, 1.0);

    return CircularPercentIndicator(
      radius: 40.0,
      lineWidth: 10.0,
      animation: true,
      percent: percent,
      circularStrokeCap: CircularStrokeCap.round,
      backgroundColor: Colors.grey.shade300,
      progressColor: Colors.amber[300]!,
      center: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value.toStringAsFixed(0),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            "/ ${goal.toStringAsFixed(0)}",
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          Text(label, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildMiniCirclesRow(int activeIndex) {
    // Tworzymy listę 3 elementów po activeIndex (z zawijaniem modulo 4)
    List<int> indices = List.generate(3, (i) => (activeIndex + 1 + i) % 4);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: indices.map((idx) => _buildMiniCircle(idx)).toList(),
    );
  }

  Widget _buildMiniCircle(int index) {
    late String label;
    late String fullLabel;
    late double value;
    late double goal;

    switch (index) {
      case 0:
        label = "kcal";
        fullLabel = "Calories";
        value = totalKcal;
        goal = dailyCalorieGoal ?? 2000;
        break;
      case 1:
        label = "g";
        fullLabel = "Protein";
        value = totalProtein;
        goal = proteinGoal ?? 1;
        break;
      case 2:
        label = "g";
        fullLabel = "Fats";
        value = totalFats;
        goal = fatGoal ?? 1;
        break;
      case 3:
        label = "g";
        fullLabel = "Carbs";
        value = totalCarbs;
        goal = carbGoal ?? 1;
        break;
    }

    final percent = (value / goal).clamp(0.0, 1.0);

    return Column(
      children: [
        Text(
          fullLabel,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        CircularPercentIndicator(
          radius: 20,
          lineWidth: 4,
          percent: percent,
          backgroundColor: Colors.grey.shade300,
          progressColor: Colors.amber[200]!,
          animation: true,
          center: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label.length > 3 ? label.substring(0, 1) : label,
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMealsList(List<Map<String, dynamic>> meals) {
    // Kolejność sekcji
    final List<String> order = [
      'Breakfast',
      'Second Breakfast',
      'Lunch',
      'Dessert',
      'Dinner',
      'Snack',
    ];

    // Grupowanie posiłków wg type
    Map<String, List<Map<String, dynamic>>> grouped = {
      for (var key in order) key: [],
    };

    for (var meal in meals.reversed) {
      final type = meal['type'] ?? 'Other';
      if (grouped.containsKey(type)) {
        grouped[type]!.add(meal);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          order.map((type) {
            final list = grouped[type]!;
            if (list.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text(
                  type,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Lista posiłków w danej sekcji
                ...list.map((meal) {
                  final String mealType = meal['type'];
                  final IconData icon = _getMealIcon(mealType);
                  final bool isFavorite = meal['is_favorite'] ?? false;

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: Icon(icon, size: 32),
                      trailing: IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : null,
                        ),
                        onPressed: () => toggleFavorite(meal),
                      ),
                      title: Text(
                        mealType,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meal['name'],
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text('${meal['kcal']} kcal'),
                        ],
                      ),
                      onTap: () async {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => MealDetailsScreen(
                                  meal: meal,
                                  fromFavorites: false,
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
                }),
              ],
            );
          }).toList(),
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
