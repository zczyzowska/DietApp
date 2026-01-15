import 'package:flutter/material.dart';
import 'favorites_list_page.dart';
import 'add_meal_form_page.dart';
import 'package:diet_app/services/api_service.dart';
import 'dart:io';

class FavoritesGridPage extends StatefulWidget {
  const FavoritesGridPage({super.key});

  @override
  State<FavoritesGridPage> createState() => _FavoritesGridPageState();
}

class _FavoritesGridPageState extends State<FavoritesGridPage> {
  static const List<String> mealTypes = [
    'Breakfast',
    'II Breakfast',
    'Lunch',
    'Dessert',
    'Dinner',
    'Snack',
  ];

  Future<void> _addFavoriteMeal(BuildContext context) async {
    final manualMeal = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddMealFormPage(isFavorite: true),
      ),
    );

    if (manualMeal != null && manualMeal.isNotEmpty) {
      try {
        final imageFile = manualMeal['image'] as File?;
        manualMeal.remove('image');

        await ApiService.saveFavorite(manualMeal, imageFile);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Favorite meal saved successfully!')),
        );

        // 👇 po prostu odśwież widok
        setState(() {});
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving favorite meal: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Meals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add_outlined),
            onPressed: () => _addFavoriteMeal(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: mealTypes.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final type = mealTypes[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FavoriteMealsListPage(mealType: type),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    type,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
