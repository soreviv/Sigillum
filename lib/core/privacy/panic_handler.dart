import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'keyboard_config.dart';

/// Centraliza la limpieza de emergencia de la aplicación.
class PanicHandler {
  PanicHandler._();

  /// Limpia controladores de texto, el portapapeles y cierra la aplicación.
  /// Se usa cuando el usuario necesita borrar todo rastro de forma instantánea.
  static Future<void> purgeAndExit(List<TextEditingController> controllers) async {
    // 1. Limpiar todos los controladores pasados
    for (final controller in controllers) {
      controller.clear();
    }

    // 2. Limpiar el portapapeles del sistema
    await clearSystemClipboard();

    // 3. Pequeño delay para asegurar que los procesos de limpieza terminen
    await Future.delayed(const Duration(milliseconds: 100));

    // 4. Salida forzada de la aplicación
    // En iOS/Android esto cierra la app devolviendo al usuario al home del SO.
    SystemChannels.platform.invokeMethod('SystemNavigator.pop');
  }
}
