import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/feedback/app_audio.dart';
import 'core/feedback/feedback_settings.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_text_styles.dart';
import 'home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Matches the web app locking portrait/no-zoom feel; safe to remove if
  // you want to support landscape/tablet layouts later.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // Music / sound / vibration preferences must be known before anything
  // plays; audio itself preloads in the background.
  await FeedbackSettings.instance.load();
  runApp(const MilKeKheloApp());
  AppAudio.instance.init();
}

/// Root widget. Deliberately thin: it just sets up the MaterialApp shell and
/// hands off to [HomeScreen] — all game logic lives inside games/<name>/.
class MilKeKheloApp extends StatefulWidget {
  const MilKeKheloApp({super.key});

  @override
  State<MilKeKheloApp> createState() => _MilKeKheloAppState();
}

class _MilKeKheloAppState extends State<MilKeKheloApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Pause music when the app leaves the screen; resume when it comes back.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AppAudio.instance.onForeground();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden || state == AppLifecycleState.detached) {
      AppAudio.instance.onBackground();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mil ke Khelo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // Baloo 2 everywhere (bundled in assets/fonts/).
        fontFamily: AppFonts.family,
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
