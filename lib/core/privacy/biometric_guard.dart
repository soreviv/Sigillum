import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

/// Observa el ciclo de vida de la app y exige re-autenticación biométrica
/// cada vez que la app vuelve al primer plano (AppLifecycleState.resumed).
///
/// Uso: añadir BiometricGuard() como primer child del widget raíz,
/// o registrar _BiometricObserver en WidgetsBinding.
class BiometricGuard extends StatefulWidget {
  const BiometricGuard({super.key, required this.child});

  final Widget child;

  @override
  State<BiometricGuard> createState() => _BiometricGuardState();
}

class _BiometricGuardState extends State<BiometricGuard>
    with WidgetsBindingObserver {
  final _auth = LocalAuthentication();
  bool _isLocked = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authenticate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Bloquear al perder foco; re-autenticar al recuperarlo.
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      setState(() => _isLocked = true);
    } else if (state == AppLifecycleState.resumed && _isLocked) {
      _authenticate();
    }
  }

  Future<void> _authenticate() async {
    final canCheck = await _auth.canCheckBiometrics ||
        await _auth.isDeviceSupported();

    if (!canCheck) {
      // Dispositivo sin biometría: permite acceso sin bloqueo.
      setState(() => _isLocked = false);
      return;
    }

    try {
      final authenticated = await _auth.authenticate(
        localizedReason: 'Verifica tu identidad para continuar en Sigillum.',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      if (mounted) setState(() => _isLocked = !authenticated);
    } catch (_) {
      // Si falla la autenticación, mantiene el bloqueo.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocked) return const _LockScreen();
    return widget.child;
  }
}

class _LockScreen extends StatelessWidget {
  const _LockScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Icon(Icons.lock_outline, color: Colors.white24, size: 64),
      ),
    );
  }
}
