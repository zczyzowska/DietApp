import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'add_meal_form_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'confirm_meal_screen.dart';
import 'meal_details.dart';
import 'package:diet_app/components/load_images_to_s3.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser!;
  List<Map<String, dynamic>> meals = [];
  int totalKcal = 0;
  int totalProtein = 0;
  int totalFats = 0;
  int totalCarbs = 0;
  int? dailyCalorieGoal;
  int? proteinGoal;
  int? fatGoal;
  int? carbGoal;
  DateTime selectedDate = DateTime.now();

  IconData _getMealIcon(String type) {
    switch (type) {
      case 'Śniadanie':
        return Icons.breakfast_dining;
      case 'II Śniadanie':
        return Icons.bakery_dining;
      case 'Obiad':
        return Icons.dinner_dining;
      case 'Deser':
        return Icons.icecream;
      case 'Kolacja':
        return Icons.brunch_dining;
      case 'Przekąska':
        return Icons.cookie;
      default:
        return Icons.restaurant;
    }
  }

  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  Future<void> loadUserGoals() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
      final data = doc.data();

      if (data != null && data['calculated'] != null) {
        final calculated = data['calculated'];

        setState(() {
          dailyCalorieGoal =
              calculated['calories'] is int
                  ? calculated['calories']
                  : int.tryParse('${calculated['calories']}');

          proteinGoal =
              calculated['protein'] is int
                  ? calculated['protein']
                  : int.tryParse('${calculated['protein']}');

          fatGoal =
              calculated['fats'] is int
                  ? calculated['fats']
                  : int.tryParse('${calculated['fats']}');

          carbGoal =
              calculated['carbs'] is int
                  ? calculated['carbs']
                  : int.tryParse('${calculated['carbs']}');
        });
      }
    } catch (e) {
      print('Błąd przy ładowaniu danych profilu: $e');
    }
  }

  Future<void> loadMealsFromFirestore() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final date = DateFormat('yyyy-MM-dd').format(selectedDate);

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('meals')
              .doc(date)
              .collection('items')
              .get();

      final loadedMeals =
          snapshot.docs.map((doc) {
            final data = doc.data();

            // Upewniamy się, że każdy posiłek ma wymagane dane i parsujemy
            return {
              'id': doc.id,
              'type': data['type'] ?? 'Nieznany',
              'name': data['name'] ?? 'Bez nazwy',
              'grams': data['grams'] ?? 0,
              'kcal': int.tryParse(data['kcal'].toString()) ?? 0,
              'protein': int.tryParse(data['protein'].toString()) ?? 0,
              'fats': int.tryParse(data['fats'].toString()) ?? 0,
              'carbs': int.tryParse(data['carbs'].toString()) ?? 0,
              'imageKey': data['imageKey'],
            };
          }).toList();

      setState(() {
        meals = loadedMeals;
        totalKcal = meals.fold(0, (suma, meal) {
          final kcal = meal['kcal'];
          return suma +
              (kcal is int ? kcal : int.tryParse(kcal.toString()) ?? 0);
        });
        totalProtein = meals.fold(0, (suma, meal) {
          final protein = meal['protein'];
          return suma +
              (protein is int
                  ? protein
                  : int.tryParse(protein.toString()) ?? 0);
        });
        totalFats = meals.fold(0, (suma, meal) {
          final fat = meal['fats'];
          return suma + (fat is int ? fat : int.tryParse(fat.toString()) ?? 0);
        });
        totalCarbs = meals.fold(0, (suma, meal) {
          final carbs = meal['carbs'];
          return suma +
              (carbs is int ? carbs : int.tryParse(carbs.toString()) ?? 0);
        });
      });

      print("Załadowano ${loadedMeals.length} posiłków z Firestore.");
    } catch (e) {
      print("Błąd przy ładowaniu danych z Firestore: $e");
    }
  }

  Future<void> saveMealToFirestore(
    Map<String, dynamic> meal, [
    File? imageFile,
  ]) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (imageFile != null) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final imageKey = await uploadImageToS3(imageFile, fileName);
      if (imageKey != null) {
        meal['imageKey'] = imageKey;
      }
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('meals')
        .doc(date)
        .collection('items')
        .add(meal);
  }

  Future<Map<String, dynamic>> analyzeImageWithGemini(File imageFile) async {
    final uri = Uri.parse(
      'https://diet-app-backend-rdbj.onrender.com/analyze-meal',
    );

    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );

    try {
      final response = await request.send();
      final resBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(resBody);

        if (data['result'] == null) {
          return {
            'name': '',
            'grams': 0,
            'kcal': 0,
            'protein': 0,
            'fats': 0,
            'carbs': 0,
          };
        }

        String rawResult = data['result'];

        // Usuń markdown z odpowiedzi
        String cleanedResult =
            rawResult
                .replaceAll(RegExp(r'```json\n'), '')
                .replaceAll(RegExp(r'\n```'), '')
                .trim();

        final result = json.decode(cleanedResult);
        return result;
      } else {
        print('Błąd: ${response.statusCode}, treść: $resBody');
        return {
          'name': '',
          'grams': 0,
          'kcal': 0,
          'protein': 0,
          'fats': 0,
          'carbs': 0,
        };
      }
    } catch (e) {
      print('Błąd połączenia: $e');
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

    final analysisResult = await analyzeImageWithGemini(imageFile);

    if (mounted) Navigator.of(context).pop();

    if (!mounted) return;

    final confirmedMeal = await _navigateToConfirmScreen(analysisResult);

    if (!mounted) return;

    if (confirmedMeal != null) {
      await saveMealToFirestore(confirmedMeal, imageFile);
      await loadMealsFromFirestore();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anulowano dodawanie posiłku')),
        );
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
    print(FirebaseAuth.instance.currentUser);
    loadMealsFromFirestore();
    loadUserGoals();
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat('dd.MM.yyyy').format(selectedDate);

    return Scaffold(
      backgroundColor: const Color(0xFFE4E0E0),
      appBar: AppBar(
        title: const Text('Serene Health'),
        actions: [
          IconButton(onPressed: signUserOut, icon: const Icon(Icons.logout)),
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
              title: const Text('Profil'),
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
              title: Text('Statystyki', style: TextStyle(color: Colors.grey)),
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
                      'Stan na dzień: $formattedDate',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('• ${meals.length} posiłków'),
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
                                'Makroskładniki:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('• Białko: $totalProtein / $proteinGoal g'),
                              Text('• Tłuszcze: $totalFats / $fatGoal g'),
                              Text('• Węglowodany: $totalCarbs / $carbGoal g'),
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
                            await loadMealsFromFirestore(); // ← przeładuj dane dla nowego dnia
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
                              ? const Center(
                                child: Text('Brak dodanych posiłków'),
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
                                          await loadMealsFromFirestore();
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
                    title: const Text('Zrób zdjęcie'),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Opcja jeszcze nieaktywna'),
                        ),
                      );
                    },
                  ),
                  Builder(
                    builder:
                        (localContext) => ListTile(
                          leading: const Icon(Icons.photo),
                          title: const Text('Wybierz z galerii'),
                          onTap: () {
                            Navigator.pop(context);
                            _handleImagePick();
                          },
                        ),
                  ),

                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Dodaj ręcznie'),
                    onTap: () async {
                      Navigator.pop(context);
                      final result = await Navigator.push<Map<String, dynamic>>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddMealFormPage(),
                        ),
                      );
                      if (result != null) {
                        await saveMealToFirestore(result);
                        await loadMealsFromFirestore();
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
