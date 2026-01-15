import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddMealFormPage extends StatefulWidget {
  final bool isFavorite;
  const AddMealFormPage({super.key, this.isFavorite = false});

  @override
  State<AddMealFormPage> createState() => _AddMealFormPageState();
}

class _AddMealFormPageState extends State<AddMealFormPage> {
  final _formKey = GlobalKey<FormState>();

  String _type = 'Breakfast';
  String _name = '';
  double _grams = 0;
  double _kcal = 0;
  double _protein = 0;
  double _fats = 0;
  double _carbs = 0;
  File? _selectedImage;
  List<Map<String, dynamic>> portions = [];
  final TextEditingController portionNameController = TextEditingController();
  final TextEditingController portionGramsController = TextEditingController();

  final List<String> mealTypes = [
    'Breakfast',
    'II Breakfast',
    'Lunch',
    'Dessert',
    'Dinner',
    'Snack',
  ];

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          _selectedImage = File(picked.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error selecting image: $e')));
    }
  }

  void saveMeal() {
    try {
      if (_formKey.currentState!.validate()) {
        _formKey.currentState!.save();

        // przekazanie danych do poprzedniego ekranu
        Navigator.pop(context, {
          'type': _type,
          'name': _name,
          'grams': _grams,
          'kcal': _kcal,
          'protein': _protein,
          'fats': _fats,
          'carbs': _carbs,
          'image': _selectedImage, // obraz opcjonalny
          if (widget.isFavorite) 'portions': portions,
        });
      }
    } catch (e, stack) {
      debugPrint('Error while saving meal: $e');
      debugPrint(stack.toString());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving meal: $e')));
    }
  }

  double _parseDouble(String? value) {
    if (value == null || value.trim().isEmpty) return 0.0;
    return double.tryParse(value) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Meal Manually')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _type,
                items:
                    mealTypes
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                onChanged: (val) => setState(() => _type = val!),
                decoration: const InputDecoration(labelText: 'Type of meal'),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Name of meal'),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Please enter a name'
                            : null,
                onSaved: (value) => _name = value!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Amount in grams'),
                keyboardType: TextInputType.number,
                validator:
                    (value) =>
                        value == null || double.tryParse(value) == null
                            ? 'Please enter a number'
                            : null,
                onSaved: (value) => _grams = _parseDouble(value),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Calories'),
                keyboardType: TextInputType.number,
                validator:
                    (value) =>
                        value == null || double.tryParse(value) == null
                            ? 'Please enter a number'
                            : null,
                onSaved: (value) => _kcal = _parseDouble(value),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Protein (g)'),
                keyboardType: TextInputType.number,
                validator:
                    (value) =>
                        value == null || double.tryParse(value) == null
                            ? 'Please enter a number'
                            : null,
                onSaved: (value) => _protein = _parseDouble(value),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Fats (g)'),
                keyboardType: TextInputType.number,
                validator:
                    (value) =>
                        value == null || double.tryParse(value) == null
                            ? 'Please enter a number'
                            : null,
                onSaved: (value) => _fats = _parseDouble(value),
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Carbohydrates (g)',
                ),
                keyboardType: TextInputType.number,
                validator:
                    (value) =>
                        value == null || double.tryParse(value) == null
                            ? 'Please enter a number'
                            : null,
                onSaved: (value) => _carbs = _parseDouble(value),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo),
                label: const Text('Add image from gallery'),
              ),
              if (_selectedImage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Image.file(_selectedImage!, height: 150),
                ),
              const SizedBox(height: 20),
              if (widget.isFavorite) ...[
                const Text(
                  "Portions (optional, for favorite meals)",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                ...portions.map((p) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(p['description']),
                      subtitle: Text("${p['gram_weight']} g"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() => portions.remove(p));
                        },
                      ),
                    ),
                  );
                }).toList(),

                TextFormField(
                  controller: portionNameController,
                  decoration: const InputDecoration(
                    labelText: "Portion description",
                    hintText: "e.g. 1 sandwich, 1 cup, 1 slice",
                  ),
                ),
                TextFormField(
                  controller: portionGramsController,
                  decoration: const InputDecoration(
                    labelText: "Grams per portion",
                    hintText: "e.g. 120",
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final desc = portionNameController.text.trim();
                    final grams = double.tryParse(
                      portionGramsController.text.trim(),
                    );
                    if (desc.isEmpty || grams == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Enter valid portion data"),
                        ),
                      );
                      return;
                    }
                    setState(() {
                      portions.add({"description": desc, "gram_weight": grams});
                      portionNameController.clear();
                      portionGramsController.clear();
                    });
                  },
                  child: const Text("Add Portion"),
                ),
              ],
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: saveMeal,
                child: const Text('Save Meal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
