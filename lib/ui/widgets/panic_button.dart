import 'package:flutter/material.dart';
import '../theme/church_theme.dart';

/// Botón de Pánico — purga toda la sesión de forma irreversible.
/// Siempre visible en el AppBar. Requiere confirmación explícita.
class PanicButton extends StatelessWidget {
  const PanicButton({super.key, required this.onConfirmed});

  final VoidCallback onConfirmed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.shield_outlined, color: kPanic),
      tooltip: 'Borrar sesión',
      onPressed: () => _confirm(context),
    );
  }

  void _confirm(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Borrar sesión'),
        content: const Text(
          'Se eliminarán todos los datos de esta sesión de forma irreversible. '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: kTextMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirmed();
            },
            child: const Text(
              'Borrar todo',
              style: TextStyle(color: kPanic, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
