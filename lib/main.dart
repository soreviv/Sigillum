import 'package:flutter/material.dart';
import 'core/privacy/biometric_guard.dart';
import 'core/privacy/screenshot_guard.dart';
import 'ui/screens/chat_screen.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/theme/church_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await ScreenshotGuard.enable();
  } catch (_) {
    // Privacy guard unavailable on this device — app continues without it.
  }
  final seenOnboarding = await hasSeenOnboarding();
  runApp(SigillumApp(showOnboarding: !seenOnboarding));
}

class SigillumApp extends StatefulWidget {
  const SigillumApp({super.key, required this.showOnboarding});

  final bool showOnboarding;

  @override
  State<SigillumApp> createState() => _SigillumAppState();
}

class _SigillumAppState extends State<SigillumApp> {
  late bool _showOnboarding;

  @override
  void initState() {
    super.initState();
    _showOnboarding = widget.showOnboarding;
  }

  void _onOnboardingDone() => setState(() => _showOnboarding = false);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sigillum',
      debugShowCheckedModeBanner: false,
      theme: buildChurchTheme(),
      home: _showOnboarding
          ? OnboardingScreen(onDone: _onOnboardingDone)
          : BiometricGuard(
              child: ScreenshotGuard.iosRecordingGuard(
                child: const ChatScreen(),
              ),
            ),
    );
  }
}
