import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:diet_app/services/api_service.dart';
import 'package:diet_app/pages/confirm_meal_screen.dart';
import 'package:diet_app/pages/add_meal_form_page.dart';

class AddMealButton extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic> meal, [File? imageFile])?
  onMealSaved;

  const AddMealButton({super.key, this.onMealSaved});

  @override
  State<AddMealButton> createState() => _AddMealButtonState();
}

class _AddMealButtonState extends State<AddMealButton> {
  final ImagePicker _picker = ImagePicker();

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
  }

  Future<Map<String, dynamic>> _analyzeMeal(
    File imageFile,
    String method,
  ) async {
    try {
      if (method == 'gemini') {
        // Gemini od razu zwraca pełne makro
        return await ApiService.analyzeMealImage(imageFile);
      } else {
        // Własny model: zwraca 5 najprawdopodobniejszych nazw
        return await ApiService.analyzeMealImageCustom(imageFile);
      }
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

  Future<String?> _selectFoodLabel(List<String> labels) async {
    return showDialog<String>(
      context: context,
      builder:
          (_) => SimpleDialog(
            title: const Text('Select your meal'),
            children:
                labels
                    .map(
                      (label) => SimpleDialogOption(
                        child: Text(label),
                        onPressed: () => Navigator.pop(context, label),
                      ),
                    )
                    .toList(),
          ),
    );
  }

  Future<Map<String, dynamic>?> _selectPortion(
    Map<String, dynamic> foodInfo,
  ) async {
    final portions = foodInfo['portions'] as List<dynamic>? ?? [];
    Map<String, dynamic>? selectedPortion =
        portions.isNotEmpty ? portions[0] : null;
    int portionCount = 1;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Select portion'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (portions.isNotEmpty)
                  DropdownButton<Map<String, dynamic>>(
                    value: selectedPortion,
                    items:
                        portions.map((p) {
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: p as Map<String, dynamic>,
                            child: Text(
                              '${p['description']} (${p['gram_weight']} g)',
                            ),
                          );
                        }).toList(),
                    onChanged: (v) => selectedPortion = v,
                  )
                else
                  Text('No portion data available, using 100g default'),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Portion count'),
                  onChanged:
                      (v) => portionCount = int.tryParse(v) ?? portionCount,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed:
                    () => Navigator.pop(context, {
                      'portion_weight':
                          selectedPortion != null
                              ? selectedPortion!['gram_weight']
                              : 100,
                      'portion_count': portionCount,
                    }),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Future<void> _handleImagePick(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return;
    final imageFile = File(pickedFile.path);

    final choice = await showDialog<String>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Choose analysis method'),
            content: const Text('How do you want to analyze this meal?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'gemini'),
                child: const Text('Gemini'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'custom'),
                child: const Text('My Model'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'cancel'),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
    if (choice == null || choice == 'cancel') return;

    _showLoadingDialog();

    Map<String, dynamic> analysisResult;

    if (choice == 'gemini') {
      analysisResult = await _analyzeMeal(imageFile, 'gemini');
    } else {
      // Custom model
      final labels = await _analyzeMeal(
        imageFile,
        'custom',
      ); // np. ["pizza", "burger", ...]
      if (!mounted) return;
      Navigator.of(context).pop(); // zamknij loader
      final selectedLabel = await _selectFoodLabel(
        List<String>.from(labels['labels'] ?? []),
      );
      if (selectedLabel == null) return;

      // Pobranie info o posiłku
      _showLoadingDialog();
      final foodInfo = await ApiService.getFoodInfo(selectedLabel);
      if (!mounted) return;
      Navigator.of(context).pop(); // zamknij loader

      // Wybór porcji
      final portionData = await _selectPortion(foodInfo);
      if (portionData == null) return;

      _showLoadingDialog();
      // Obliczenie makro
      analysisResult = await ApiService.calculateMacro(
        foodName: selectedLabel,
        portionWeight: portionData['portion_weight'],
        portionCount: portionData['portion_count'],
      );
      if (!mounted) return;
      Navigator.of(context).pop(); // zamknij loader
    }

    if (!mounted) return;
    final confirmedMeal = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => ConfirmMealScreen(mealData: analysisResult),
      ),
    );

    if (confirmedMeal != null) {
      final savedMeal = await ApiService.saveMeal(confirmedMeal, imageFile);

      if (mounted) {
        Navigator.of(context).pop(); // ← TU zamykasz loader
        widget.onMealSaved?.call(savedMeal, imageFile);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take a photo'),
            onTap: () => _handleImagePick(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo),
            title: const Text('Choose from gallery'),
            onTap: () => _handleImagePick(ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Add manually'),
            onTap: () async {
              // Czekaj na dane z formularza
              final manualMeal = await Navigator.push<Map<String, dynamic>>(
                context,
                MaterialPageRoute(builder: (_) => const AddMealFormPage()),
              );

              if (manualMeal != null && manualMeal.isNotEmpty) {
                try {
                  final imageFile = manualMeal['image'] as File?;
                  manualMeal.remove(
                    'image',
                  ); // nie chcemy przesyłać File w JSON

                  final savedMeal = await ApiService.saveMeal(
                    manualMeal,
                    imageFile,
                  );

                  if (!mounted) return;
                  Navigator.of(context).pop(); // zamknij loader

                  // wywołanie callbacka (np. odświeżenie ekranu)
                  widget.onMealSaved?.call(savedMeal, imageFile);
                } catch (e) {
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving meal: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
