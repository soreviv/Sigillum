import 'package:flutter/material.dart';
import '../theme/church_theme.dart';

/// Burbuja de chat para mensajes del usuario y del asistente.
/// Cuando [isStreaming] es true muestra un indicador de escritura.
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    this.isStreaming = false,
  });

  final String message;
  final bool isUser;
  final bool isStreaming;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isUser ? 56 : 16,
          right: isUser ? 16 : 56,
          bottom: 8,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? kCard : kOledBlack,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isUser ? 14 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 14),
          ),
          border: Border.all(color: kBorder),
        ),
        child: isStreaming && message.isEmpty
            ? const _TypingDots()
            : Text(
                message,
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 15,
                  height: 1.55,
                ),
              ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _anim = Tween<double>(begin: 0, end: 3).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final dots = '.' * (_anim.value.floor() + 1);
        return Text(
          dots,
          style: const TextStyle(
            color: kTextMuted,
            fontSize: 20,
            letterSpacing: 4,
          ),
        );
      },
    );
  }
}
