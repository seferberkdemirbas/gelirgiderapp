import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  MaterialColor _primarySwatch = Colors.blue;

  ThemeProvider() {
    _loadPrefs();
  }

  ThemeMode get themeMode => _themeMode;
  MaterialColor get primarySwatch => _primarySwatch;

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = ThemeMode.values[prefs.getInt('themeMode') ?? 0];
    final colorName = prefs.getString('primarySwatch') ?? 'blue';
    _primarySwatch = _colorFromString(colorName);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
  }

  Future<void> setPrimarySwatch(MaterialColor color) async {
    _primarySwatch = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('primarySwatch', _stringFromColor(color));
  }

  MaterialColor _colorFromString(String name) {
    switch (name) {
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  String _stringFromColor(MaterialColor color) {
    if (color == Colors.red) return 'red';
    if (color == Colors.green) return 'green';
    if (color == Colors.orange) return 'orange';
    if (color == Colors.purple) return 'purple';
    return 'blue';
  }
}
