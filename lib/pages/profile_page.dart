import 'package:flutter/material.dart';
import 'package:diet_app/services/api_service.dart'; // 🔹 Zmien na swoją ścieżkę

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  String? _gender;
  int? _age;
  double? _height;
  double? _weight;
  String _activityLevel = 'low';
  String _goal = 'maintain weight';
  double? _targetWeight;
  int? _durationWeeks;

  Map<String, dynamic>? _calculatedData;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final data = await ApiService.getUserProfile(); // 🔹 GET /profile
    if (data != null) {
      setState(() {
        _nameController.text = data['name'] ?? '';
        _gender = data['gender'];
        _age = data['age'];
        _height = (data['height'] as num?)?.toDouble();
        _weight = (data['weight'] as num?)?.toDouble();
        _activityLevel = data['activityLevel'] ?? 'low';
        _goal = data['goal'] ?? 'maintain weight';
        _targetWeight = (data['targetWeight'] as num?)?.toDouble();
        _durationWeeks = (data['durationWeeks'] as num?)?.toInt();
        _calculatedData = data['calculated'] as Map<String, dynamic>?;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final profileData = {
      'name': _nameController.text,
      'gender': _gender,
      'age': _age ?? 0,
      'height': _height ?? 0.0,
      'weight': _weight ?? 0.0,
      'activityLevel': _activityLevel,
      'goal': _goal,
      'targetWeight': _targetWeight ?? _weight ?? 0.0,
      'durationWeeks': _durationWeeks ?? 0,
    };

    final result = await ApiService.updateUserProfile(profileData);

    if (result != null) {
      setState(() {
        _calculatedData = result['calculated'];
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil zapisany pomyślnie!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nie udało się zapisać profilu')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
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
          const Text('Profile incomplete', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => setState(() => _isEditing = true),
            child: const Text('Edit Profile'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Name: ${_nameController.text}'),
        Text('Gender: $_gender'),
        Text('Age: $_age years'),
        Text('Height: ${_height!.toStringAsFixed(1)} cm'),
        Text('Weight: ${_weight!.toStringAsFixed(1)} kg'),
        Text('Activity Level: $_activityLevel'),
        Text('Goal: $_goal'),
        if (_targetWeight != null)
          Text('Target Weight: ${_targetWeight!.toStringAsFixed(1)} kg'),
        const SizedBox(height: 16),
        if (_calculatedData != null) ...[
          const Text(
            'Daily Caloric Needs:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text('Calories: ${_calculatedData!['kcal']} kcal'),
          Text('Protein: ${_calculatedData!['protein']} g'),
          Text('Fats: ${_calculatedData!['fats']} g'),
          Text('Carbs: ${_calculatedData!['carbs']} g'),
        ],
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => setState(() => _isEditing = true),
          child: const Text('Edit Profile'),
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
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          DropdownButtonFormField<String>(
            value: _gender,
            items:
                ['woman', 'man']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
            onChanged: (val) => setState(() => _gender = val),
            decoration: const InputDecoration(labelText: 'Gender'),
            validator: (val) => val == null ? 'Select gender' : null,
          ),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Age'),
            keyboardType: TextInputType.number,
            initialValue: _age?.toString(),
            onChanged: (val) => _age = int.tryParse(val),
            validator: (val) => val == null || val.isEmpty ? 'Enter age' : null,
          ),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Height (cm)'),
            keyboardType: TextInputType.number,
            initialValue: _height?.toString(),
            onChanged: (val) => _height = double.tryParse(val),
            validator:
                (val) => val == null || val.isEmpty ? 'Enter height' : null,
          ),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Weight (kg)'),
            keyboardType: TextInputType.number,
            initialValue: _weight?.toString(),
            onChanged: (val) => _weight = double.tryParse(val),
            validator:
                (val) => val == null || val.isEmpty ? 'Enter weight' : null,
          ),
          DropdownButtonFormField<String>(
            value: _activityLevel,
            decoration: const InputDecoration(labelText: 'Activity Level'),
            items:
                ['very low', 'low', 'moderate', 'high', 'very high']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
            onChanged: (val) => setState(() => _activityLevel = val!),
          ),
          DropdownButtonFormField<String>(
            value: _goal,
            decoration: const InputDecoration(labelText: 'Goal'),
            items:
                ['lose weight', 'maintain weight', 'gain weight']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
            onChanged: (val) {
              setState(() {
                _goal = val!;
                if (_goal == 'maintain weight') {
                  _targetWeight = null;
                  _durationWeeks = null;
                }
              });
            },
          ),

          if (_goal != 'maintain weight') ...[
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Target weight (kg)',
              ),
              keyboardType: TextInputType.number,
              initialValue: _targetWeight?.toString(),
              onChanged: (val) => _targetWeight = double.tryParse(val),
              validator: (val) {
                if (_goal != 'maintain weight' &&
                    (val == null || val.isEmpty)) {
                  return 'Enter target weight';
                }
                return null;
              },
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Duration (weeks)'),
              keyboardType: TextInputType.number,
              initialValue: _durationWeeks?.toString(),
              onChanged: (val) => _durationWeeks = int.tryParse(val),
              validator: (val) {
                if (_goal != 'maintain weight' &&
                    (val == null || val.isEmpty)) {
                  return 'Enter duration';
                }
                return null;
              },
            ),
          ],

          const SizedBox(height: 16),
          ElevatedButton(onPressed: _saveProfile, child: const Text('Save')),
        ],
      ),
    );
  }
}
