import 'dart:convert';
import 'package:flutter/services.dart';

/// Entrada individual del índice RAG (CIC o Catecismo).
final class CanonEntry {
  const CanonEntry({
    required this.id,
    required this.reference,
    required this.category,
    required this.keywords,
    required this.text,
  });

  final String id;
  final String reference;
  final String category;
  final List<String> keywords;
  final String text;

  factory CanonEntry.fromJson(Map<String, dynamic> json) => CanonEntry(
        id: json['id'] as String,
        reference: json['reference'] as String,
        category: json['category'] as String,
        keywords: List<String>.from(json['keywords'] as List),
        text: json['text'] as String,
      );
}

/// Carga y cachea los archivos JSON de la base de conocimiento desde assets.
/// Los datos son estáticos (solo lectura); no hay escritura en ningún momento.
class CanonLoader {
  CanonLoader._();
  static final CanonLoader instance = CanonLoader._();

  List<CanonEntry>? _cicEntries;
  List<CanonEntry>? _catecismoEntries;

  Future<List<CanonEntry>> get cicEntries async {
    _cicEntries ??= await _load('assets/rag/cic.json');
    return _cicEntries!;
  }

  Future<List<CanonEntry>> get catecismoEntries async {
    _catecismoEntries ??= await _load('assets/rag/catecismo.json');
    return _catecismoEntries!;
  }

  Future<List<CanonEntry>> get allEntries async {
    final cic = await cicEntries;
    final cat = await catecismoEntries;
    return [...cic, ...cat];
  }

  Future<List<CanonEntry>> _load(String assetPath) async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => CanonEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Asset corrupto o ausente — degradación graceful sin crash.
      return [];
    }
  }
}
