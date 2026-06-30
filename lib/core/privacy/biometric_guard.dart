import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
  
  // Biometría no está disponible en plataformas de escritorio
  static bool get _isDesktop => 
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.linux ||
                  defaultTargetPlatform == TargetPlatform.windows ||
                  defaultTargetPlatform == TargetPlatform.macOS);

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
    // En desktop, no aplicar bloqueo por ciclo de vida
    if (_isDesktop) return;
    
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
    // En plataformas de escritorio, deshabilitar bloqueo biométrico
    if (_isDesktop) {
      setState(() => _isLocked = false);
      return;
    }
    
    try {
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      final canCheck = canCheckBiometrics || isDeviceSupported;

      if (!canCheck) {
        // Dispositivo sin biometría: permite acceso sin bloqueo.
        setState(() => _isLocked = false);
        return;
      }
    } catch (e) {
      // Si falla la verificación de biometría, deshabilitar bloqueo
      setState(() => _isLocked = false);
      return;
    }

    try {
      final authenticated = await _auth.authenticate(
        localizedReason: 'Verifica tu identidad para continuar en Sigillum.',
        persistAcrossBackgrounding: true,
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
