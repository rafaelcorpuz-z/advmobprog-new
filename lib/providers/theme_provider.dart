import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = false;

  bool get isDark => _isDark;

  // Enhancement 3: theme state is centralized so the settings page controls the app mode.
  void toggleTheme(bool value) {
    _isDark = value;
    notifyListeners();
  }

  ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorSchemeSeed: Colors.indigo,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xfff7f8fc),
    fontFamily: 'Poppins',
  );

  ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorSchemeSeed: Colors.indigo,
    brightness: Brightness.dark,
    fontFamily: 'Poppins',
  );
}
