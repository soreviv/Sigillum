import 'package:flutter/material.dart';
import '../../core/ai/distillation_parser.dart';
import '../theme/church_theme.dart';

/// Tarjeta de un pecado destilado con panel QPL expandible.
class SinCard extends StatelessWidget {
  const SinCard({
    super.key,
    required this.sin,
    required this.qplText,
    required this.isLoadingQpl,
    required this.isExpanded,
    required this.onToggleQpl,
  });

  final SinEntry sin;
  final String? qplText;
  final bool isLoadingQpl;
  final bool isExpanded;
  final VoidCallback onToggleQpl;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera: número, especie, cantidad
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NumberBadge(sin.number),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sin.species,
                        style: const TextStyle(
                          color: kTextPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        sin.count,
                        style: const TextStyle(
                          color: kTextMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Botón QPL
          InkWell(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            onTap: onToggleQpl,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.help_outline, color: kGold, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '¿Qué preguntarle al sacerdote?',
                      style: TextStyle(color: kGold, fontSize: 13),
                    ),
                  ),
                  if (isLoadingQpl)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: kGold,
                      ),
                    )
                  else
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: kGold,
                      size: 18,
                    ),
                ],
              ),
            ),
          ),

          // Panel QPL expandible
          if (isExpanded && qplText != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kOledBlack,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kBorder),
              ),
              child: Text(
                qplText!,
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge(this.number);
  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: const TextStyle(
          color: kTextMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
