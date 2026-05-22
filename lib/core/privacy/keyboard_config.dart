import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Configuración global de InputDecoration y TextField para el chat de Sigillum.
/// Garantiza que el SO no aprenda ni sugiera ningún texto ingresado.
class SigillumKeyboardConfig {
  SigillumKeyboardConfig._();

  /// InputDecoration base: sin sugerencias, sin autocompletado, sin historial.
  static InputDecoration decoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.white30),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white38),
      ),
      filled: true,
      fillColor: const Color(0xFF111111),
    );
  }

  /// TextField listo para el Modo Iglesia: sin sugerencias, sin autocorrección,
  /// sin spellcheck, sin aprendizaje de teclado predictivo.
  static Widget buildTextField({
    required TextEditingController controller,
    String? hintText,
    int maxLines = 5,
    ValueChanged<String>? onSubmitted,
    FocusNode? focusNode,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      maxLines: maxLines,
      keyboardType: TextInputType.multiline,
      textInputAction:
          maxLines == 1 ? TextInputAction.send : TextInputAction.newline,

      // Bloqueos de privacidad de teclado
      enableSuggestions: false,
      autocorrect: false,
      enableIMEPersonalizedLearning: false,
      spellCheckConfiguration: const SpellCheckConfiguration.disabled(),

      style: const TextStyle(color: Colors.white, fontSize: 16),
      cursorColor: Colors.white54,
      decoration: decoration(hintText: hintText),
      onSubmitted: onSubmitted,

      // Evita que el portapapeles del SO retenga el texto
      contextMenuBuilder: (context, editableTextState) =>
          const SizedBox.shrink(),
    );
  }
}

/// Limpia el portapapeles del SO. Llamar al activar el Botón de Pánico
/// o al enviar cada mensaje.
Future<void> clearSystemClipboard() async {
  await Clipboard.setData(const ClipboardData(text: ''));
}
