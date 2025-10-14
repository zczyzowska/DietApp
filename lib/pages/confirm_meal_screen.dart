import 'package:flutter/material.dart';

class ConfirmMealScreen extends StatefulWidget {
  final Map<String, dynamic> mealData;

  const ConfirmMealScreen({super.key, required this.mealData});

  @override
  State<ConfirmMealScreen> createState() => _ConfirmMealScreenState();
}

class _ConfirmMealScreenState extends State<ConfirmMealScreen> {
  late TextEditingController _nameController;
  late TextEditingController _gramsController;
  late TextEditingController _kcalController;
  late TextEditingController _proteinController;
  late TextEditingController _fatsController;
  late TextEditingController _carbsController;
  String _type = 'Breakfast';
  final _formKey = GlobalKey<FormState>();

  final List<String> mealTypes = [
    'Breakfast',
    'II Breakfast',
    'Lunch',
    'Desert',
    'Dinner',
    'Snack',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.mealData['name']);
    _gramsController = TextEditingController(
      text: widget.mealData['grams'].toString(),
    );
    _kcalController = TextEditingController(
      text: widget.mealData['kcal'].toString(),
    );
    _proteinController = TextEditingController(
      text: widget.mealData['protein']?.toString() ?? '0',
    );
    _fatsController = TextEditingController(
      text: widget.mealData['fats']?.toString() ?? '0',
    );
    _carbsController = TextEditingController(
      text: widget.mealData['carbs']?.toString() ?? '0',
    );
  }

  void _confirm() {
    if (_formKey.currentState?.validate() ?? false) {
      final result = {
        'type': _type,
        'name': _nameController.text.trim(),
        'grams': double.parse(_gramsController.text),
        'kcal': double.parse(_kcalController.text),
        'protein': double.parse(_proteinController.text),
        'fats': double.parse(_fatsController.text),
        'carbs': double.parse(_carbsController.text),
      };
      Navigator.pop(context, result);
    }
  }

  void _cancel() {
    Navigator.pop(context, null);
  }

  @override
  Widget build(BuildContext context) {
    final bool isNameEmpty = _nameController.text.trim().isEmpty;

    return Scaffold(
      appBar: AppBar(title: Text('Validate Meal')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
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
              if (isNameEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'Could not recognize meal name, please enter it manually.',
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name of meal'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the name of the meal';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _gramsController,
                decoration: InputDecoration(labelText: 'Amount in grams'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final number = double.tryParse(value ?? '');
                  if (number == null || number <= 0) {
                    return 'Please enter a number greater than zero';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _kcalController,
                decoration: InputDecoration(labelText: 'Calories'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final number = double.tryParse(value ?? '');
                  if (number == null || number <= 0) {
                    return 'Please enter a number greater than zero';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _proteinController,
                decoration: InputDecoration(labelText: 'Protein (g)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final number = double.tryParse(value ?? '');
                  if (number == null || number < 0) {
                    return 'Please enter a non-negative number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _fatsController,
                decoration: InputDecoration(labelText: 'Fats (g)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final number = double.tryParse(value ?? '');
                  if (number == null || number < 0) {
                    return 'Please enter a non-negative number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _carbsController,
                decoration: InputDecoration(labelText: 'Carbohydrates (g)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final number = double.tryParse(value ?? '');
                  if (number == null || number < 0) {
                    return 'Please enter a non-negative number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(onPressed: _confirm, child: Text('Confirm')),
                  OutlinedButton(onPressed: _cancel, child: Text('Cancel')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
