/// Parser y lógica de procesamiento de contexto para Sigillum.
library;

/// Representa una entrada de pecado que preserva el matiz emocional.
final class SinEntry {
  const SinEntry({
    required this.number,
    required this.species,
    required this.count,
    this.emotion = '',
  });

  final int number;
  final String species;
  final String count;
  final String emotion;
}

/// Crea una estructura de contexto que preserva el sentimiento original y guía a la IA.
/// Devuelve un Map con el mensaje, el contexto RAG y una instrucción dinámica.
Map<String, dynamic> parseContext(String message, String ragContext) {
  final tone = _detectTone(message);
  
  String dynamicInstruction;
  switch (tone) {
    case 'compasivo':
      dynamicInstruction = "El usuario muestra vulnerabilidad y dolor. Responde con extrema delicadeza, priorizando el consuelo y la validación de su sufrimiento.";
      break;
    case 'misericordioso':
      dynamicInstruction = "El usuario expresa arrepentimiento o culpa. Enfócate en la alegría de la conversión y en la infinita bondad de Dios que siempre acoge.";
      break;
    case 'socrático':
      dynamicInstruction = "El usuario está reflexionando o tiene dudas. Usa preguntas que le ayuden a profundizar en su conciencia y a encontrar claridad interior.";
      break;
    default:
      dynamicInstruction = "Mantén un tono de acompañamiento cálido, validando la honestidad del usuario en su proceso de introspección.";
  }

  return {
    'originalMessage': message,
    'ragContext': ragContext,
    'dynamicInstruction': dynamicInstruction,
    'tone': tone,
  };
}

/// Análisis básico de palabras clave para detectar el tono emocional predominante.
String _detectTone(String text) {
  final lower = text.toLowerCase();
  
  if (lower.contains('dolor') || 
      lower.contains('triste') || 
      lower.contains('sufr') || 
      lower.contains('angustia') || 
      lower.contains('miedo')) {
    return 'compasivo';
  }
  
  if (lower.contains('culpa') || 
      lower.contains('perdón') || 
      lower.contains('arrepient') || 
      lower.contains('fallado') || 
      lower.contains('mal')) {
    return 'misericordioso';
  }
  
  if (lower.contains('duda') || 
      lower.contains('por qué') || 
      lower.contains('paz') || 
      lower.contains('entiendo') || 
      lower.contains('busco')) {
    if (lower.contains('paz')) return 'socrático';
    return 'socrático';
  }

  return 'cálido';
}

/// Parsea el bloque ---DESTILACIÓN--- preservando el sentimiento si está presente.
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
      emotion: parts.length > 2 ? parts[2].trim() : '',
    ));
  }
  return sins;
}

/// Parsea las preguntas para el confesor.
String parseQpl(String text) {
  final match = RegExp(
    r'---QPL:\d+---(.*?)---FIN---',
    dotAll: true,
    caseSensitive: false,
  ).firstMatch(text);
  return match?.group(1)?.trim() ?? text.trim();
}
