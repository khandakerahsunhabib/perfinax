import 'package:flutter/material.dart';
import 'controllers/theme_controller.dart';
import 'core/theme/app_theme.dart';
import 'views/splash/splash_screen.dart';

class PerfinaxApp extends StatefulWidget {
  const PerfinaxApp({super.key});

  @override
  State<PerfinaxApp> createState() => _PerfinaxAppState();
}

class _PerfinaxAppState extends State<PerfinaxApp> {
  @override
  void initState() {
    super.initState();
    ThemeController.instance.loadTheme();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'PERFINAX',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeController.instance.themeMode,
          darkTheme: AppTheme.darkTheme,
          theme: AppTheme.lightTheme,
          home: const SplashScreen(),
        );
      },
    );
  }
}
