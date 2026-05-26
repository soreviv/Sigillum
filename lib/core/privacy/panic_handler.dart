import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'keyboard_config.dart';

/// Centraliza la limpieza de emergencia de la aplicación.
///
/// Android: purga datos y cierra la app con SystemNavigator.pop.
/// iOS: Apple prohíbe el cierre programático. Se navega a una pantalla
///       permanente de sesión destruida. El usuario cierra manualmente.
class PanicHandler {
  PanicHandler._();

  /// Limpia controladores de texto, el portapapeles y cierra/bloquea la app.
  /// [context] es necesario en iOS para navegar a la pantalla de sesión destruida.
  static Future<void> purgeAndExit(
    List<TextEditingController> controllers, {
    BuildContext? context,
  }) async {
    // 1. Limpiar todos los controladores pasados
    for (final controller in controllers) {
      controller.clear();
    }

    // 2. Limpiar el portapapeles del sistema
    await clearSystemClipboard();

    // 3. Pequeño delay para asegurar que los procesos de limpieza terminen
    await Future.delayed(const Duration(milliseconds: 100));

    // 4. Salida según plataforma
    if (Platform.isIOS && context != null && context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const _PurgedScreen()),
        (_) => false,
      );
    } else {
      // Android y fallback: cierre real de la app
      SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    }
  }
}

/// Pantalla permanente tras la purga en iOS.
/// No contiene datos y no permite navegar de vuelta.
class _PurgedScreen extends StatelessWidget {
  const _PurgedScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield, color: Colors.white24, size: 48),
            SizedBox(height: 16),
            Text(
              'Sesión destruida',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Cierra la app manualmente.',
              style: TextStyle(color: Colors.white24, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
