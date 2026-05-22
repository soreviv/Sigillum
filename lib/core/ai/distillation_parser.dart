/// Modelo y parsers para la respuesta estructurada del motor de IA.
library;

/// Un pecado destilado: especie canónica + número aproximado de veces.
final class SinEntry {
  const SinEntry({
    required this.number,
    required this.species,
    required this.count,
  });

  final int number;
  final String species;
  final String count;
}

/// Parsea el bloque ---DESTILACIÓN--- emitido por Claude.
/// Acepta tanto Ó con acento como O sin él (LLMs a veces los omiten).
List<SinEntry> parseDistillation(String text) {
  final match = RegExp(
    r'---DESTILACI[OÓ]N---(.*?)---FIN---',
    dotAll: true,
    caseSensitive: false,
  ).firstMatch(text);

  if (match == null) return [];

  final sins = <SinEntry>[];
  for (final line in match.group(1)!.trim().split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;

    final parts = trimmed.split('|');
    if (parts.length < 2) continue;

    final m = RegExp(r'^\d+\.\s*(.+)').firstMatch(parts[0].trim());
    if (m == null) continue;

    sins.add(SinEntry(
      number: sins.length + 1,
      species: m.group(1)!.trim(),
      count: parts[1].trim(),
    ));
  }
  return sins;
}

/// Parsea el bloque ---QPL:N--- emitido por Claude.
/// Si no encuentra el formato, devuelve el texto limpio como fallback.
String parseQpl(String text) {
  final match = RegExp(
    r'---QPL:\d+---(.*?)---FIN---',
    dotAll: true,
    caseSensitive: false,
  ).firstMatch(text);
  return match?.group(1)?.trim() ?? text.trim();
}
