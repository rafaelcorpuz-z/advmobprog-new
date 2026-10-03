import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../services/user_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Do you want to log out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Log out')),
        ],
      ),
    );
    if (confirm != true) return;
    await UserService().signOut();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/signin', (_) => false);
  }

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
            onChanged: themeProvider.toggleTheme,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            onTap: () => Navigator.pushNamed(context, '/profile'),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFFB55C66)),
            title: const Text('Log out'),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}