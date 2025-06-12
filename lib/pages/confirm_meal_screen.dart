import 'package:flutter/material.dart';

class ConfirmMealScreen extends StatefulWidget {
  final Map<String, dynamic> mealData;

  ConfirmMealScreen({required this.mealData});

  @override
  _ConfirmMealScreenState createState() => _ConfirmMealScreenState();
}

class _ConfirmMealScreenState extends State<ConfirmMealScreen> {
  late TextEditingController _nameController;
  late TextEditingController _gramsController;
  late TextEditingController _kcalController;
  late TextEditingController _proteinController;
  late TextEditingController _fatsController;
  late TextEditingController _carbsController;
  String _type = 'Śniadanie';
  final _formKey = GlobalKey<FormState>();

  final List<String> mealTypes = [
    'Śniadanie',
    'II Śniadanie',
    'Obiad',
    'Deser',
    'Kolacja',
    'Przekąska',
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
        'grams': int.parse(_gramsController.text),
        'kcal': int.parse(_kcalController.text),
        'protein': int.parse(_proteinController.text),
        'fats': int.parse(_fatsController.text),
        'carbs': int.parse(_carbsController.text),
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
      appBar: AppBar(title: Text('Potwierdź dane')),
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
                decoration: const InputDecoration(labelText: 'Typ posiłku'),
              ),
              if (isNameEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'Nie udało się rozpoznać posiłku. Proszę wpisać dane lub anulować i spróbować ponownie.',
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nazwa posiłku'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Wprowadź nazwę posiłku';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _gramsController,
                decoration: InputDecoration(labelText: 'Ilość w gramach'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final number = int.tryParse(value ?? '');
                  if (number == null || number <= 0) {
                    return 'Podaj liczbę większą od zera';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _kcalController,
                decoration: InputDecoration(labelText: 'Kalorie'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final number = int.tryParse(value ?? '');
                  if (number == null || number <= 0) {
                    return 'Podaj liczbę większą od zera';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _proteinController,
                decoration: InputDecoration(labelText: 'Białko (g)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final number = int.tryParse(value ?? '');
                  if (number == null || number < 0) {
                    return 'Podaj liczbę nieujemną';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _fatsController,
                decoration: InputDecoration(labelText: 'Tłuszcze (g)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final number = int.tryParse(value ?? '');
                  if (number == null || number < 0) {
                    return 'Podaj liczbę nieujemną';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _carbsController,
                decoration: InputDecoration(labelText: 'Węglowodany (g)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final number = int.tryParse(value ?? '');
                  if (number == null || number < 0) {
                    return 'Podaj liczbę nieujemną';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(onPressed: _confirm, child: Text('Zapisz')),
                  OutlinedButton(onPressed: _cancel, child: Text('Anuluj')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
