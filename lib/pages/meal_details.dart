import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'confirm_meal_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:diet_app/components/load_images_to_s3.dart';

class MealDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> meal;

  const MealDetailsScreen({super.key, required this.meal});

  @override
  State<MealDetailsScreen> createState() => _MealDetailsScreenState();
}

class _MealDetailsScreenState extends State<MealDetailsScreen> {
  String? imageUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSignedImageUrl();
  }

  Future<void> _loadSignedImageUrl() async {
    setState(() => isLoading = true);
    final key = widget.meal['imageKey'];
    if (key != null) {
      final url = await fetchSignedUrl(key);
      setState(() {
        imageUrl = url;
        isLoading = false;
      });
    } else {
      setState(() {
        imageUrl = null;
        isLoading = false;
      });
    }
  }

  Future<void> _editMeal(BuildContext context) async {
    final confirmedMeal = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConfirmMealScreen(mealData: widget.meal),
      ),
    );

    if (confirmedMeal != null) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('meals')
          .doc(date)
          .collection('items')
          .doc(widget.meal['id'])
          .update(confirmedMeal);

      if (context.mounted) {
        Navigator.pop(context, true); // ← zwraca true do poprzedniego widoku
      }
    }
  }

  Future<void> _deleteMeal(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Usuń posiłek'),
          content: const Text('Czy na pewno chcesz usunąć ten posiłek?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Nie'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Tak'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('meals')
          .doc(date)
          .collection('items')
          .doc(widget.meal['id'])
          .delete();

      if (context.mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.meal;

    return Scaffold(
      appBar: AppBar(title: Text(data['name'] ?? 'Posiłek')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (isLoading)
              const CircularProgressIndicator()
            else if (imageUrl != null)
              Image.network(imageUrl!, height: 200)
            else
              const SizedBox(),

            const SizedBox(height: 20),
            Text('Typ: ${data['type']}'),
            Text('Gramy: ${data['grams']} g'),
            Text('Kalorie: ${data['kcal']} kcal'),
            Text('Białko: ${data['protein']} g'),
            Text('Tłuszcze: ${data['fats']} g'),
            Text('Węglowodany: ${data['carbs']} g'),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _editMeal(context),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edytuj'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _deleteMeal(context),
                  icon: const Icon(Icons.delete),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  label: const Text('Usuń'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
