import 'package:businesscalc/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _detectSystemTheme();
  }

  void _detectSystemTheme() {
    // Detecta el tema del sistema al iniciar
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    setState(() {
      _themeMode =
          brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void _toggleTheme() {
    setState(() {
      if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
      } else if (_themeMode == ThemeMode.dark) {
        _themeMode = ThemeMode.system;
      } else {
        _themeMode = ThemeMode.light;
      }
    });

    // Feedback háptico al cambiar tema
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Business Calc',
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: _themeMode,
      debugShowCheckedModeBanner: false,
      home:
          MyHomePage(onThemeToggle: _toggleTheme, currentThemeMode: _themeMode),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color.fromARGB(255, 0, 68, 255),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromARGB(255, 30, 136, 229),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 2,
        shadowColor: Colors.black26,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color.fromARGB(255, 0, 68, 255),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color.fromARGB(255, 100, 150, 255),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 2,
        shadowColor: Colors.black54,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: const Color.fromARGB(255, 100, 150, 255),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      scaffoldBackgroundColor: Colors.grey[900],
    );
  }
}

class ThemeToggleButton extends StatelessWidget {
  final VoidCallback onPressed;
  final ThemeMode currentThemeMode;

  const ThemeToggleButton({
    super.key,
    required this.onPressed,
    required this.currentThemeMode,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    String tooltip;
    String tex;

    switch (currentThemeMode) {
      case ThemeMode.light:
        icon = Icons.light_mode;
        tooltip = 'Cambiar a modo oscuro';
        tex = 'Modo Ligth';
        break;
      case ThemeMode.dark:
        icon = Icons.dark_mode;
        tooltip = 'Cambiar a modo automático';
        tex = 'Modo Oscuro';
        break;
      case ThemeMode.system:
        icon = Icons.brightness_auto;
        tooltip = 'Cambiar a modo claro';
        tex = 'Tema del sistema';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Row(
            children: [
              Text(tex),
              SizedBox(
                width: 20,
              ),
              Icon(
                icon,
                key: ValueKey(currentThemeMode),
              ),
            ],
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
