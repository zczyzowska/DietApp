import 'package:flutter/material.dart';
import 'package:diet_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diet_app/services/auth_service.dart';
import 'package:diet_app/pages/login_page.dart';

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
    try {
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        _nameController.text = prefs.getString('name') ?? '';
        _gender = prefs.getString('gender');
        _age = prefs.getInt('age');
        _height = prefs.getDouble('height');
        _weight = prefs.getDouble('weight');
        _activityLevel = prefs.getString('activityLevel') ?? 'low';
        _goal = prefs.getString('goal') ?? 'maintain weight';
        _targetWeight = prefs.getDouble('targetWeight');
        _durationWeeks = prefs.getInt('durationWeeks');

        _calculatedData = {
          'kcal': prefs.getDouble('kcal') ?? 0,
          'protein': prefs.getDouble('protein') ?? 0,
          'fats': prefs.getDouble('fats') ?? 0,
          'carbs': prefs.getDouble('carbs') ?? 0,
        };
      });

      print("Dane użytkownika wczytane z SharedPreferences");
    } catch (e) {
      print('Błąd podczas wczytywania profilu z SharedPreferences: $e');
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
    return Column(
      children: [
        const SizedBox(height: 20),

        // 🔸 Avatar (ikona w przyszłości zastąpisz zdjęciem)
        Center(
          child: CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey.shade300,
            child: const Icon(Icons.person, size: 70, color: Colors.white),
          ),
        ),

        const SizedBox(height: 20),

        // 🔸 Imię
        Text(
          _nameController.text.isEmpty ? "No name" : _nameController.text,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 20),

        // 🔸 Karty z danymi
        _buildProfileCard(
          title: "Personal Data",
          children: [
            _profileRow("Gender", _gender ?? "-"),
            _profileRow("Age", "${_age ?? '-'} years"),
            _profileRow(
              "Height",
              _height != null ? "${_height!.toStringAsFixed(1)} cm" : "-",
            ),
            _profileRow(
              "Weight",
              _weight != null ? "${_weight!.toStringAsFixed(1)} kg" : "-",
            ),
          ],
        ),

        const SizedBox(height: 16),

        _buildProfileCard(
          title: "Lifestyle",
          children: [
            _profileRow("Activity Level", _activityLevel),
            _profileRow("Goal", _goal),
            if (_targetWeight != null)
              _profileRow(
                "Target Weight",
                "${_targetWeight!.toStringAsFixed(1)} kg",
              ),
            if (_durationWeeks != null)
              _profileRow("Duration", "$_durationWeeks weeks"),
          ],
        ),

        const SizedBox(height: 16),

        if (_calculatedData != null)
          _buildProfileCard(
            title: "Daily Nutritional Needs",
            children: [
              _profileRow("Calories", "${_calculatedData!['kcal']} kcal"),
              _profileRow("Protein", "${_calculatedData!['protein']} g"),
              _profileRow("Fats", "${_calculatedData!['fats']} g"),
              _profileRow("Carbs", "${_calculatedData!['carbs']} g"),
            ],
          ),

        const SizedBox(height: 30),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profile'),
              onPressed: () => setState(() => _isEditing = true),
            ),
            const SizedBox(width: 16), // odstęp między przyciskami
            ElevatedButton.icon(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              label: const Text(
                'Logout',
                style: TextStyle(color: Colors.redAccent),
              ),
              onPressed: () {
                AuthService.signUserOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildProfileCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _profileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
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
