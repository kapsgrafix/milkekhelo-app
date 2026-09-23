import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme/app_colors.dart';
import 'home/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Matches the web app locking portrait/no-zoom feel; safe to remove if
  // you want to support landscape/tablet layouts later.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MilKeKheloApp());
}

/// Root widget. Deliberately thin: it just sets up the MaterialApp shell and
/// hands off to [HomeScreen] — all game logic lives inside games/<name>/.
class MilKeKheloApp extends StatelessWidget {
  const MilKeKheloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mil ke Khelo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.shell,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.langActiveBg,
          brightness: Brightness.dark,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
