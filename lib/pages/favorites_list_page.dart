import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import 'meal_details.dart';

class FavoriteMealsListPage extends StatefulWidget {
  final String mealType;

  const FavoriteMealsListPage({required this.mealType, super.key});

  @override
  _FavoriteMealsListPageState createState() => _FavoriteMealsListPageState();
}

class _FavoriteMealsListPageState extends State<FavoriteMealsListPage> {
  List<Map<String, dynamic>> favoriteMeals = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadFavoriteMeals();
  }

  Future<void> loadFavoriteMeals() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final meals = await ApiService.getFavorites(type: widget.mealType);
      setState(() => favoriteMeals = meals);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading favorites: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> removeFavorite(int id) async {
    final success = await ApiService.deleteFavorite(id);
    if (success) {
      setState(() => favoriteMeals.removeWhere((meal) => meal['id'] == id));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to remove favorite meal')),
      );
    }
  }

  Future<void> addToHistory(
    Map<String, dynamic> meal,
    double grams,
    DateTime date,
  ) async {
    final success = await ApiService.addFavoriteToHistory(
      meal['id'],
      grams: grams,
      date: date.toIso8601String(),
    );

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Added to history')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to add to history')));
    }
  }

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

  Future<void> addToHistoryDialog(Map<String, dynamic> meal) async {
    final gramController = TextEditingController();
    final portionCountController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    Map<String, dynamic>? selectedPortion;

    await showDialog(
      context: context,
      builder: (context) {
        final hasPortions =
            meal['portions'] != null && (meal['portions'] as List).isNotEmpty;

        return StatefulBuilder(
          builder:
              (context, setState) => AlertDialog(
                title: Text('Add "${meal['name']}" to history'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasPortions)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Select portion:'),
                          ...meal['portions'].map<Widget>((p) {
                            return RadioListTile<Map<String, dynamic>>(
                              title: Text(
                                '${p['description']} (${p['gram_weight']} g)',
                              ),
                              value: p,
                              groupValue: selectedPortion,
                              onChanged:
                                  (val) =>
                                      setState(() => selectedPortion = val),
                            );
                          }).toList(),
                          TextField(
                            controller: portionCountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'),
                              ),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Portion count',
                              hintText: 'Enter number of portions',
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text('Or enter custom grams:'),
                        ],
                      ),
                    TextField(
                      controller: gramController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Grams',
                        hintText: 'Enter meal weight (g)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Date: ${selectedDate.toLocal().toString().split(' ')[0]}',
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              selectedDate = picked;
                              if (mounted) setState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      double grams;

                      if (hasPortions && selectedPortion != null) {
                        final countText = portionCountController.text.trim();
                        double count = double.tryParse(countText) ?? 1;
                        grams = selectedPortion!['gram_weight'] * count;
                      } else {
                        final gramsText = gramController.text.trim();
                        if (gramsText.isEmpty ||
                            double.tryParse(gramsText) == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter valid grams'),
                            ),
                          );
                          return;
                        }
                        grams = double.parse(gramsText);
                      }

                      Navigator.pop(context);
                      await addToHistory(meal, grams, selectedDate);
                    },
                    child: const Text('Add'),
                  ),
                ],
              ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Favorites: ${widget.mealType}')),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : favoriteMeals.isEmpty
              ? const Center(child: Text('There are no favorite meals yet.'))
              : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: favoriteMeals.length,
                itemBuilder: (context, index) {
                  final meal = favoriteMeals[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: Icon(_getMealIcon(meal['type']), size: 32),
                      title: Text(meal['name']),
                      subtitle: Text('${meal['kcal']} kcal'),
                      trailing: IconButton(
                        icon: Icon(Icons.add, color: Colors.grey[600]),
                        onPressed: () => addToHistoryDialog(meal),
                      ),
                      onTap: () async {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => MealDetailsScreen(
                                  meal: meal,
                                  fromFavorites: true,
                                ),
                          ),
                        );

                        if (updated == true) {
                          await loadFavoriteMeals();
                        }
                      },
                    ),
                  );
                },
              ),
    );
  }
}
