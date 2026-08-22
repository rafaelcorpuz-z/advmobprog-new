import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'providers/theme_provider.dart';
import 'providers/cart_provider.dart';
import 'screens/home_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'assets/.env');
  runApp(const MobProgApiApp());
}

class MobProgApiApp extends StatelessWidget {
  const MobProgApiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      builder: (context, child) {
        final themeProvider = context.watch<ThemeProvider>();
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'API Store',
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
          home: const HomeScreen(),
          routes: {
            '/cart': (_) => const CartScreen(),
            '/settings': (_) => const SettingsScreen(),
          },
        );
      },
    );
  }
}
