import 'package:flutter/material.dart';
import 'views/main_screen.dart';

class PerfinaxApp extends StatelessWidget {
  const PerfinaxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PERFINAX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF030A08),
        cardColor: const Color(0xFF0A221C),
        primaryColor: const Color(0xFF10B981),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF10B981),
          surface: Color(0xFF0A221C),
          secondary: Color(0xFF14B8A6),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF030A08),
          elevation: 0,
        ),
      ),
      home: const MainScreen(),
    );
  }
}
