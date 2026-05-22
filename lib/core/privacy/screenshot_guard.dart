import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:no_screenshot/screenshot_snapshot.dart';

/// Bloquea capturas de pantalla y grabación de pantalla en ambas plataformas.
/// Android: FLAG_SECURE a nivel de Window.
/// iOS: no_screenshot + overlay opaco al detectar grabación activa.
class ScreenshotGuard {
  ScreenshotGuard._();

  static final _noScreenshot = NoScreenshot.instance;

  static Future<void> enable() async {
    if (Platform.isAndroid) {
      await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    }
    await _noScreenshot.screenshotOff();
  }

  static Future<void> disable() async {
    if (Platform.isAndroid) {
      await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
    }
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
