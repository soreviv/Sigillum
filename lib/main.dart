import 'package:flutter/material.dart';
import 'core/privacy/biometric_guard.dart';
import 'core/privacy/screenshot_guard.dart';
import 'ui/screens/chat_screen.dart';
import 'ui/theme/church_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      theme: buildChurchTheme(),
      home: BiometricGuard(
        child: ScreenshotGuard.iosRecordingGuard(
          child: const ChatScreen(),
        ),
      ),
    );
  }
}
