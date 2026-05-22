import 'package:flutter/material.dart';
import 'core/privacy/biometric_guard.dart';
import 'core/privacy/screenshot_guard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Activar FLAG_SECURE y bloqueo de capturas antes de pintar el primer frame.
  await ScreenshotGuard.enable();

  runApp(const SigillumApp());
}

class SigillumApp extends StatelessWidget {
  const SigillumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sigillum',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          surface: Colors.black,
          primary: Colors.white,
        ),
      ),
      home: BiometricGuard(
        child: ScreenshotGuard.iosRecordingGuard(
          child: const _PlaceholderHome(),
        ),
      ),
    );
  }
}

// Placeholder: será reemplazado por ChatScreen en Fase 3.
class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Sigillum',
          style: TextStyle(color: Colors.white24, fontSize: 32),
        ),
      ),
    );
  }
}
