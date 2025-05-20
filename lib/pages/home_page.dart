import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'add_meal_form_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser!;
  List<Map<String, dynamic>> meals = [];
  int totalKcal = 0;

  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  Future<void> loadMealsFromFirestore() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());

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

            // Upewniamy się, że każdy posiłek ma wymagane dane i parsujemy kcal
            return {
              'type': data['type'] ?? 'Nieznany',
              'name': data['name'] ?? 'Bez nazwy',
              'grams': data['grams'] ?? 0,
              'kcal': int.tryParse(data['kcal'].toString()) ?? 0,
            };
          }).toList();

      setState(() {
        meals = loadedMeals;
        totalKcal = meals.fold(0, (suma, meal) {
          final kcal = meal['kcal'];
          return suma +
              (kcal is int ? kcal : int.tryParse(kcal.toString()) ?? 0);
        });
      });

      print("Załadowano ${loadedMeals.length} posiłków z Firestore.");
    } catch (e) {
      print("Błąd przy ładowaniu danych z Firestore: $e");
    }
  }

  Future<void> saveMealToFirestore(Map<String, dynamic> meal) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('meals')
        .doc(date) // możesz grupować po dacie
        .collection('items')
        .add(meal);
  }

  @override
  void initState() {
    super.initState();
    print(FirebaseAuth.instance.currentUser);
    loadMealsFromFirestore(); // <-- automatyczne pobranie danych po starcie
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat(
      'dd.MM.yyyy',
    ).format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFE4E0E0),
      appBar: AppBar(
        title: const Text('Diet App'),
        actions: [
          IconButton(onPressed: signUserOut, icon: const Icon(Icons.logout)),
        ],
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
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('• ${meals.length} posiłków'),
                    Text('• $totalKcal kcal / 2000 kcal'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  meals.isEmpty
                      ? const Center(child: Text('Brak dodanych posiłków'))
                      : ListView.builder(
                        itemCount: meals.length,
                        itemBuilder: (context, index) {
                          final meal = meals[index];
                          return MealTile(
                            title: '${meal['type']} - ${meal['name']}',
                            description:
                                '${meal['grams']} g, ${meal['kcal']} kcal',
                          );
                        },
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
                  ListTile(
                    leading: const Icon(Icons.photo),
                    title: const Text('Wybierz z galerii'),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Opcja jeszcze nieaktywna'),
                        ),
                      );
                    },
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
                        await loadMealsFromFirestore(); // <-- aktualizacja UI po zapisie
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
