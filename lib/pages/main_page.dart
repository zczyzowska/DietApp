import 'package:flutter/material.dart';
import 'home_page.dart';
import 'favorites_main_page.dart';
import 'profile_page.dart';
import 'login_page.dart';
import 'stats.dart';
import 'package:diet_app/services/auth_service.dart';
import 'package:diet_app/widgets/add_meal_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diet_app/services/api_service.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(), // Twój rozbudowany ekran główny
    const FavoritesGridPage(),
    const AddMealButton(),
    const StatisticsPage(),
    const ProfilePage(), // Profil
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final data = await ApiService.getUserProfile();

      if (data != null) {
        final prefs = await SharedPreferences.getInstance();

        // Zapis danych podstawowych
        await prefs.setString('name', data['name'] ?? '');
        await prefs.setString('gender', data['gender'] ?? '');
        await prefs.setInt('age', data['age'] ?? 0);
        await prefs.setDouble(
          'height',
          (data['height'] as num?)?.toDouble() ?? 0,
        );
        await prefs.setDouble(
          'weight',
          (data['weight'] as num?)?.toDouble() ?? 0,
        );
        await prefs.setString('activityLevel', data['activityLevel'] ?? 'low');
        await prefs.setString('goal', data['goal'] ?? 'maintain weight');
        await prefs.setDouble(
          'targetWeight',
          (data['targetWeight'] as num?)?.toDouble() ?? 0,
        );
        await prefs.setInt(
          'durationWeeks',
          (data['durationWeeks'] as num?)?.toInt() ?? 0,
        );

        // Zapis danych z sekcji "calculated"
        if (data['calculated'] != null) {
          final calc = data['calculated'] as Map<String, dynamic>;
          await prefs.setDouble(
            'kcal',
            (calc['kcal'] as num?)?.toDouble() ?? 0,
          );
          await prefs.setDouble(
            'protein',
            (calc['protein'] as num?)?.toDouble() ?? 0,
          );
          await prefs.setDouble(
            'fats',
            (calc['fats'] as num?)?.toDouble() ?? 0,
          );
          await prefs.setDouble(
            'carbs',
            (calc['carbs'] as num?)?.toDouble() ?? 0,
          );
        }
        print("Profil użytkownika zapisany lokalnie w SharedPreferences");
      }
    } catch (e) {
      print('Błąd podczas ładowania profilu: $e');
    }
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => AddMealButton(),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4E0E0),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.notifications, color: Colors.grey[600]),
          onPressed: () {},
        ),
        title: const Text('Serene Health'),
        centerTitle: true,
        toolbarHeight: 35,
        actions: [
          IconButton(
            onPressed: () {
              AuthService.signUserOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
            icon: Icon(Icons.logout, color: Colors.grey[600]),
          ),
        ],
      ),
      body: _pages[_selectedIndex], // Wyświetlamy odpowiednią stronę
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant),
            label: 'My meals',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Add meal'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Statistics',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        selectedItemColor: Colors.indigo[400],
        selectedIconTheme: const IconThemeData(size: 30),
        unselectedItemColor: Colors.grey[600],
        showUnselectedLabels: true,
      ),
    );
  }
}
