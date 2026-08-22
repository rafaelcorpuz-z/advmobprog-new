import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile.adaptive(
            title: Text(themeProvider.isDark ? 'Dark mode' : 'Light mode'),
            subtitle: Text(
              themeProvider.isDark
                  ? 'Switch to light mode'
                  : 'Switch to dark mode',
            ),
            secondary: Icon(
              themeProvider.isDark ? Icons.dark_mode : Icons.light_mode,
            ),
            value: themeProvider.isDark,
            // Enhancement 3: the dark/light switch now lives on its own settings page.
            onChanged: themeProvider.toggleTheme,
          ),
        ],
      ),
    );
  }
}
