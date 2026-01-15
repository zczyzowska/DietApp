import 'package:flutter/material.dart';
import 'confirm_meal_screen.dart';
import 'package:diet_app/services/api_service.dart';

class MealDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> meal;
  final bool fromFavorites;

  const MealDetailsScreen({
    super.key,
    required this.meal,
    this.fromFavorites = false,
  });

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
    Map<String, dynamic>? confirmedMeal;

    confirmedMeal = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ConfirmMealScreen(
              mealData: widget.meal,
              isFavorite: widget.fromFavorites,
            ),
      ),
    );

    if (confirmedMeal != null) {
      bool success = false;

      if (widget.fromFavorites) {
        success = await ApiService.updateFavorite(
          widget.meal['id'],
          confirmedMeal,
        );
      } else {
        success = await ApiService.editMeal(widget.meal['id'], confirmedMeal);
      }

      if (success && context.mounted) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.fromFavorites
                  ? 'Could not update favorite meal'
                  : 'Could not update meal',
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteMeal(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Delete meal'),
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
      final success =
          widget.fromFavorites
              ? await ApiService.deleteFavorite(widget.meal['id'])
              : await ApiService.deleteMeal(widget.meal['id']);

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
      appBar: AppBar(title: Text(data['name'] ?? 'Meal details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl!,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(height: 20),

            /// ---- MEAL DETAILS CARD ----
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Meal details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    infoRow('Type', data['type'], Icons.category),
                    infoRow('Weight', '${data['grams']} g', Icons.scale),
                    infoRow(
                      'Calories',
                      '${data['kcal']} kcal',
                      Icons.local_fire_department,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// ---- MACROS CARD ----
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Macronutrients',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        macroItem('Protein', data['protein'], 'g'),
                        macroItem('Fats', data['fats'], 'g'),
                        macroItem('Carbs', data['carbs'], 'g'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            /// ---- PORTIONS ----
            if (widget.fromFavorites &&
                data['portions'] != null &&
                (data['portions'] as List).isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'Available portions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    (data['portions'] as List).map<Widget>((p) {
                      return Chip(
                        label: Text(
                          '${p['description']} (${p['gram_weight']} g)',
                        ),
                      );
                    }).toList(),
              ),
            ],

            const SizedBox(height: 24),

            /// ---- ACTION BUTTONS ----
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _editMeal(context),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteMeal(context),
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------- HELPERS ----------

Widget infoRow(String label, String value, IconData icon) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Text(value, style: TextStyle(color: Colors.grey[700])),
      ],
    ),
  );
}

Widget macroItem(String label, dynamic value, String unit) {
  return Column(
    children: [
      Text(
        '$value$unit',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: Colors.grey[600])),
    ],
  );
}
