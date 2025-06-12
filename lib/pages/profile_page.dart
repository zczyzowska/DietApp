import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final userId = FirebaseAuth.instance.currentUser!.uid;

  final TextEditingController _nameController = TextEditingController();
  String? _gender;
  int? _age;
  double? _height;
  double? _weight;
  String _activityLevel = 'niska';
  String _goal = 'utrzymać wagę';
  double? _targetWeight;

  Map<String, dynamic>? _calculatedData;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _nameController.text = data['name'] ?? '';
        _gender = data['gender'];
        _age = data['age'];
        _height = (data['height'] as num?)?.toDouble();
        _weight = (data['weight'] as num?)?.toDouble();
        _activityLevel = data['activityLevel'] ?? 'niska';
        _goal = data['goal'] ?? 'utrzymać wagę';
        _targetWeight = (data['targetWeight'] as num?)?.toDouble();
        _calculatedData = data['calculated'] as Map<String, dynamic>?;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final bmr =
        _gender == 'kobieta'
            ? 655 + (9.6 * _weight!) + (1.8 * _height!) - (4.7 * _age!)
            : 66 + (13.7 * _weight!) + (5 * _height!) - (6.8 * _age!);

    final activityMultipliers = {
      'niska': 1.2,
      'umiarkowana': 1.5,
      'wysoka': 1.8,
    };

    double maintenanceCalories =
        bmr * (activityMultipliers[_activityLevel] ?? 1.2);

    double targetCalories;
    if (_goal == 'schudnąć') {
      targetCalories = maintenanceCalories - 500;
    } else if (_goal == 'przytyć') {
      targetCalories = maintenanceCalories + 300;
    } else {
      targetCalories = maintenanceCalories;
    }

    final protein = _weight! * 2.0;
    final fat = _weight! * 1.0;
    final carbs = (targetCalories - (protein * 4 + fat * 9)) / 4;

    final calculated = {
      'calories': targetCalories.round(),
      'protein': protein.round(),
      'fats': fat.round(),
      'carbs': carbs.round(),
    };

    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'name': _nameController.text,
      'gender': _gender,
      'age': _age,
      'height': _height,
      'weight': _weight,
      'activityLevel': _activityLevel,
      'goal': _goal,
      'targetWeight': _targetWeight,
      'calculated': calculated,
    });

    setState(() {
      _calculatedData = calculated;
      _isEditing = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profil zapisany')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil użytkownika')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _isEditing ? _buildForm() : _buildProfileSummary(),
      ),
    );
  }

  Widget _buildProfileSummary() {
    if (_gender == null || _age == null || _height == null || _weight == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Brak personalizacji profilu',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => setState(() => _isEditing = true),
            child: const Text('Edytuj profil'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Imię: ${_nameController.text}'),
        Text('Płeć: $_gender'),
        Text('Wiek: $_age lat'),
        Text('Wzrost: ${_height!.toStringAsFixed(1)} cm'),
        Text('Waga: ${_weight!.toStringAsFixed(1)} kg'),
        Text('Aktywność: $_activityLevel'),
        Text('Cel: $_goal'),
        if (_targetWeight != null)
          Text('Waga docelowa: ${_targetWeight!.toStringAsFixed(1)} kg'),
        const SizedBox(height: 16),
        if (_calculatedData != null) ...[
          const Text(
            'Zapotrzebowanie dzienne:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text('Kalorie: ${_calculatedData!['calories']} kcal'),
          Text('Białko: ${_calculatedData!['protein']} g'),
          Text('Tłuszcze: ${_calculatedData!['fats']} g'),
          Text('Węglowodany: ${_calculatedData!['carbs']} g'),
        ],
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => setState(() => _isEditing = true),
          child: const Text('Edytuj profil'),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Imię'),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _gender,
            items:
                ['kobieta', 'mężczyzna']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
            onChanged: (val) => setState(() => _gender = val),
            decoration: const InputDecoration(labelText: 'Płeć'),
            validator: (val) => val == null ? 'Wybierz płeć' : null,
          ),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Wiek'),
            keyboardType: TextInputType.number,
            initialValue: _age?.toString(),
            onChanged: (val) => _age = int.tryParse(val),
          ),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Wzrost (cm)'),
            keyboardType: TextInputType.number,
            initialValue: _height?.toString(),
            onChanged: (val) => _height = double.tryParse(val),
          ),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Waga (kg)'),
            keyboardType: TextInputType.number,
            initialValue: _weight?.toString(),
            onChanged: (val) => _weight = double.tryParse(val),
          ),
          DropdownButtonFormField<String>(
            value: _activityLevel,
            decoration: const InputDecoration(labelText: 'Poziom aktywności'),
            items:
                ['niska', 'umiarkowana', 'wysoka']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
            onChanged: (val) => setState(() => _activityLevel = val!),
          ),
          DropdownButtonFormField<String>(
            value: _goal,
            decoration: const InputDecoration(labelText: 'Cel'),
            items:
                ['schudnąć', 'utrzymać wagę', 'przytyć']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
            onChanged: (val) => setState(() => _goal = val!),
          ),
          if (_goal != 'utrzymać wagę')
            TextFormField(
              decoration: InputDecoration(
                labelText:
                    _goal == 'schudnąć'
                        ? 'Do ilu kg schudnąć'
                        : 'Do ilu kg przytyć',
              ),
              keyboardType: TextInputType.number,
              initialValue: _targetWeight?.toString(),
              onChanged: (val) => _targetWeight = double.tryParse(val),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: _saveProfile,
                child: const Text('Zapisz'),
              ),
              TextButton(
                onPressed: () => setState(() => _isEditing = false),
                child: const Text('Anuluj'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
