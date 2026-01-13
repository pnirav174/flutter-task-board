import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:take_home_assignment/core/router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:take_home_assignment/core/sync_providers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:take_home_assignment/core/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    // Initialize SyncService
    ref.watch(syncServiceProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Task Board',
      themeMode: themeMode,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      routerConfig: router,
    );
  }

  ThemeData _buildLightTheme() {
    // Create a fresh light text theme without using Theme.of(context)
    final baseLightTextTheme = ThemeData.light().textTheme;

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blueAccent,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      textTheme: GoogleFonts.interTextTheme(baseLightTextTheme),
    );
  }

  ThemeData _buildDarkTheme() {
    // Create a fresh dark text theme without using Theme.of(context)
    final baseDarkTextTheme = ThemeData.dark().textTheme;

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blueAccent,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      textTheme: GoogleFonts.interTextTheme(baseDarkTextTheme),
    );
  }
}
