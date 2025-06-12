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
  String _type = 'Śniadanie';
  String _name = '';
  int _grams = 0;
  int _kcal = 0;
  int _protein = 0;
  int _fats = 0;
  int _carbs = 0;
  File? _selectedImage;

  final List<String> mealTypes = [
    'Śniadanie',
    'II Śniadanie',
    'Obiad',
    'Deser',
    'Kolacja',
    'Przekąska',
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
      appBar: AppBar(title: const Text('Dodaj posiłek ręcznie')),
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
                decoration: const InputDecoration(labelText: 'Typ posiłku'),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nazwa posiłku'),
                validator:
                    (value) =>
                        value == null || value.isEmpty ? 'Podaj nazwę' : null,
                onSaved: (value) => _name = value!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Ilość w gramach'),
                keyboardType: TextInputType.number,
                validator:
                    (value) =>
                        value == null || int.tryParse(value) == null
                            ? 'Podaj liczbę'
                            : null,
                onSaved: (value) => _grams = int.parse(value!),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Kalorie'),
                keyboardType: TextInputType.number,
                validator:
                    (value) =>
                        value == null || int.tryParse(value) == null
                            ? 'Podaj liczbę'
                            : null,
                onSaved: (value) => _kcal = int.parse(value!),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Białko (g)'),
                keyboardType: TextInputType.number,
                onSaved: (value) => _protein = int.parse(value!),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Tłuszcze (g)'),
                keyboardType: TextInputType.number,
                onSaved: (value) => _fats = int.parse(value!),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Węglowodany (g)'),
                keyboardType: TextInputType.number,
                onSaved: (value) => _carbs = int.parse(value!),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo),
                label: const Text('Dodaj zdjęcie z galerii'),
              ),
              if (_selectedImage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Image.file(_selectedImage!, height: 150),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: saveMeal,
                child: const Text('Zapisz posiłek'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
