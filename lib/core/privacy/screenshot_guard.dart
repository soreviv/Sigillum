import 'dart:io';
import 'package:flutter/material.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:no_screenshot/screenshot_snapshot.dart';

/// Bloquea capturas de pantalla y grabación de pantalla en ambas plataformas.
/// Android: FLAG_SECURE vía no_screenshot (capa nativa).
/// iOS: no_screenshot + overlay opaco al detectar grabación activa.
///
/// Nota: flutter_windowmanager fue eliminado por obsoleto. El paquete
/// no_screenshot ya gestiona FLAG_SECURE internamente en Android.
class ScreenshotGuard {
  ScreenshotGuard._();

  static final _noScreenshot = NoScreenshot.instance;

  static Future<void> enable() async {
    await _noScreenshot.screenshotOff();
  }

  static Future<void> disable() async {
    await _noScreenshot.screenshotOn();
  }

  /// Widget que cubre el contenido con un overlay negro si iOS detecta grabación activa.
  static Widget iosRecordingGuard({required Widget child}) {
    if (!Platform.isIOS) return child;
    return StreamBuilder<ScreenshotSnapshot>(
      stream: _noScreenshot.screenshotStream,
      builder: (context, snapshot) {
        final isRecording = snapshot.data?.isScreenRecording ?? false;
        return Stack(
          children: [
            child,
            if (isRecording)
              const Positioned.fill(
                child: ColoredBox(color: Colors.black),
              ),
          ],
        );
      },
    );
  }
}
