import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/church_theme.dart';

const _kOnboardingSeenKey = 'onboarding_seen';

Future<bool> hasSeenOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kOnboardingSeenKey) ?? false;
}

/// Pantalla de bienvenida con dos slides: características y flujo de uso.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == 0) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingSeenKey, true);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kOledBlack,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _page = i),
                children: const [
                  _FeaturesPage(),
                  _HowItWorksPage(),
                ],
              ),
            ),
            _buildDots(),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: kGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    _page == 0 ? 'Siguiente' : 'Comenzar',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(2, (i) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _page == i ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: _page == i ? kGold : kBorder,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

class _FeaturesPage extends StatelessWidget {
  const _FeaturesPage();

  @override
  Widget build(BuildContext context) {
    return Padding(
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
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
}

class _HowItWorksPage extends StatelessWidget {
  const _HowItWorksPage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          const Text(
            'Cómo funciona',
            style: TextStyle(
              color: kGold,
              fontSize: 28,
              fontWeight: FontWeight.w300,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tres pasos sencillos antes de tu confesión',
            style: TextStyle(color: kTextMuted, fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 48),
          _buildStep(
            number: '1',
            icon: Icons.chat_bubble_outline,
            title: 'Narra tu situación',
            body:
                'Escribe con libertad lo que pesa en tu conciencia. '
                'La IA te escucha y te guía con preguntas socráticas para no olvidar nada.',
          ),
          _buildConnector(),
          _buildStep(
            number: '2',
            icon: Icons.format_list_bulleted,
            title: 'Obtén tu lista',
            body:
                'Pulsa "Obtener mi lista" cuando hayas terminado. '
                'Recibirás un examen estructurado con la especie canónica y el número de cada falta.',
          ),
          _buildConnector(),
          _buildStep(
            number: '3',
            icon: Icons.question_answer_outlined,
            title: 'Lleva tus preguntas',
            body:
                'Para cada falta puedes generar preguntas específicas '
                'que podrás plantear a tu sacerdote durante la confesión.',
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildStep({
    required String number,
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                border: Border.all(color: kGold, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  number,
                  style: const TextStyle(
                    color: kGold,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: kTextPrimary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      color: kTextPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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

  Widget _buildConnector() {
    return Padding(
      padding: const EdgeInsets.only(left: 17, top: 6, bottom: 6),
      child: Container(width: 1, height: 20, color: kBorder),
    );
  }
}
