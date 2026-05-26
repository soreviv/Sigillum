import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/church_theme.dart';

const _kOnboardingSeenKey = 'onboarding_seen';

/// Comprueba si el onboarding ya fue visto y lo elimina de SharedPreferences si hace falta.
Future<bool> hasSeenOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kOnboardingSeenKey) ?? false;
}

/// Pantalla de bienvenida que se muestra únicamente en el primer lanzamiento.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingSeenKey, true);
    onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kOledBlack,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              _buildTitle(),
              const SizedBox(height: 48),
              _buildFeature(
                icon: Icons.lock_outline,
                title: 'Cero almacenamiento',
                body:
                    'Ningún mensaje, confesión ni dato personal se guarda '
                    'en disco. Todo vive en memoria y se destruye al cerrar la sesión.',
              ),
              const SizedBox(height: 28),
              _buildFeature(
                icon: Icons.fingerprint,
                title: 'Protección biométrica',
                body:
                    'La app se bloquea cada vez que pasa al segundo plano '
                    'y exige tu huella dactilar o Face ID para continuar.',
              ),
              const SizedBox(height: 28),
              _buildFeature(
                icon: Icons.menu_book_outlined,
                title: 'Guiado por doctrina',
                body:
                    'Las respuestas se basan en el Catecismo de la Iglesia '
                    'Católica y el Código de Derecho Canónico, sin opiniones personales.',
              ),
              const Spacer(),
              _buildStartButton(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Sigillum',
          style: TextStyle(
            color: kGold,
            fontSize: 36,
            fontWeight: FontWeight.w300,
            letterSpacing: 4,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Examen de conciencia estructurado',
          style: TextStyle(
            color: kTextMuted,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildFeature({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: kGold, size: 22),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: const TextStyle(
                  color: kTextMuted,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    return Builder(
      builder: (context) => SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _complete,
          style: FilledButton.styleFrom(
            backgroundColor: kGold,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Comenzar',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
