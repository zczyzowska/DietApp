import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddMealFormPage extends StatefulWidget {
  const AddMealFormPage({super.key});

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

  final List<String> mealTypes = [
    'Breakfast',
    'II Breakfast',
    'Lunch',
    'Desert',
    'Dinner',
    'Snack',
  ];

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  void saveMeal() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      Navigator.pop(context, {
        'type': _type,
        'name': _name,
        'grams': _grams,
        'kcal': _kcal,
        'protein': _protein,
        'fats': _fats,
        'carbs': _carbs,
        'image': _selectedImage, // przekazujemy obraz
      });
    }
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
                onSaved: (value) => _grams = double.parse(value!),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Calories'),
                keyboardType: TextInputType.number,
                validator:
                    (value) =>
                        value == null || double.tryParse(value) == null
                            ? 'Please enter a number'
                            : null,
                onSaved: (value) => _kcal = double.parse(value!),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Protein (g)'),
                keyboardType: TextInputType.number,
                onSaved: (value) => _protein = double.parse(value!),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Fats (g)'),
                keyboardType: TextInputType.number,
                onSaved: (value) => _fats = double.parse(value!),
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Carbohydrates (g)',
                ),
                keyboardType: TextInputType.number,
                onSaved: (value) => _carbs = double.parse(value!),
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
