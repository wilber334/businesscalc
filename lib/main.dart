import 'package:businesscalc/home.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Business Calc',
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromARGB(255, 0, 68, 255)),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
              backgroundColor: Color.fromARGB(255, 0, 68, 255),
              foregroundColor: Colors.white,
              centerTitle: true),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color.fromARGB(255, 0, 68, 255),
            foregroundColor: Colors.white,
          )),
      home: const MyHomePage(),
    );
  }
}
