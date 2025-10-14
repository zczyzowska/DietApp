import 'package:flutter/material.dart';
import 'confirm_meal_screen.dart';
import 'package:diet_app/services/api_service.dart';

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
    final key = widget.meal['image_url'];
    if (key != null) {
      final url = await ApiService.getMealImageUrl(key);
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
      final success = await ApiService.editMeal(
        widget.meal['id'],
        confirmedMeal,
      );

      if (success && context.mounted) {
        Navigator.pop(context, true); // informuje poprzedni ekran
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not update meal')));
      }
    }
  }

  Future<void> _deleteMeal(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (BuildContext dialogContext) => AlertDialog(
            title: const Text('Delete Meal'),
            content: const Text('Are you sure you want to delete this meal?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final success = await ApiService.deleteMeal(widget.meal['id']);

      if (success && context.mounted) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not delete meal')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.meal;

    return Scaffold(
      appBar: AppBar(title: Text(data['name'] ?? 'Meal Details')),
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
            Text('Type: ${data['type']}'),
            Text('Grams: ${data['grams'].toString()} g'),
            Text('Calories: ${data['kcal'].toString()} kcal'),
            Text('Protein: ${data['protein'].toString()} g'),
            Text('Fats: ${data['fats'].toString()} g'),
            Text('Carbs: ${data['carbs'].toString()} g'),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _editMeal(context),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _deleteMeal(context),
                  icon: const Icon(Icons.delete),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  label: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
