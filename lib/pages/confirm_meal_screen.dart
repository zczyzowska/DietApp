import 'package:flutter/material.dart';

class ConfirmMealScreen extends StatefulWidget {
  final Map<String, dynamic> mealData;
  final bool isFavorite;

  const ConfirmMealScreen({
    super.key,
    required this.mealData,
    this.isFavorite = false,
  });

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

  List<Map<String, dynamic>> portions = [];

  final List<String> mealTypes = [
    'Breakfast',
    'II Breakfast',
    'Lunch',
    'Dessert',
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
    _type = widget.mealData['type'] ?? 'Breakfast';

    if (widget.isFavorite && widget.mealData['portions'] != null) {
      portions = List<Map<String, dynamic>>.from(widget.mealData['portions']);
    }
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
        if (widget.isFavorite) 'portions': portions,
      };
      Navigator.pop(context, result);
    }
  }

  void _cancel() {
    Navigator.pop(context, null);
  }

  void _addPortion() {
    setState(() {
      portions.add({'description': '', 'gram_weight': 0.0});
    });
  }

  void _removePortion(int index) {
    setState(() {
      portions.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isNameEmpty = _nameController.text.trim().isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Meal')),
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
              if (isNameEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'Could not recognize meal name, please enter it manually.',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name of meal'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the name of the meal';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _gramsController,
                decoration: const InputDecoration(labelText: 'Amount in grams'),
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
                decoration: const InputDecoration(labelText: 'Calories'),
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
                decoration: const InputDecoration(labelText: 'Protein (g)'),
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
                decoration: const InputDecoration(labelText: 'Fats (g)'),
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
                decoration: const InputDecoration(
                  labelText: 'Carbohydrates (g)',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final number = double.tryParse(value ?? '');
                  if (number == null || number < 0) {
                    return 'Please enter a non-negative number';
                  }
                  return null;
                },
              ),
              if (widget.isFavorite) ...[
                const SizedBox(height: 20),
                const Text(
                  'Portions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: portions.length,
                  itemBuilder: (context, index) {
                    final portion = portions[index];
                    final descController = TextEditingController(
                      text: portion['description'],
                    );
                    final gramsController = TextEditingController(
                      text: portion['gram_weight'].toString(),
                    );
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: descController,
                                decoration: const InputDecoration(
                                  labelText: 'Description',
                                ),
                                onChanged:
                                    (val) => portion['description'] = val,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 80,
                              child: TextFormField(
                                controller: gramsController,
                                decoration: const InputDecoration(
                                  labelText: 'Grams',
                                ),
                                keyboardType: TextInputType.number,
                                onChanged:
                                    (val) =>
                                        portion['gram_weight'] =
                                            double.tryParse(val) ?? 0,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removePortion(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                TextButton.icon(
                  onPressed: _addPortion,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Portion'),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _confirm,
                    child: const Text('Confirm'),
                  ),
                  OutlinedButton(
                    onPressed: _cancel,
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
