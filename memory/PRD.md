# Sigillum — PRD (Product Requirements Document)

## Problema Original
App móvil Flutter de desarrollo personal/espiritual: revisar el proyecto existente, corregir errores y aplicar mejoras. Integración con Claude Sonnet.

## Descripción del Producto
**Sigillum** — Aplicación Andragógica de Estructuración Sacramental. Herramienta móvil de privacidad extrema que asiste al feligrés católico a estructurar su examen de conciencia previo a la confesión, destilando narrativas complejas en la especie y número del pecado (Canon 979 — CIC).

## User Persona
- Feligrés católico que necesita preparar su examen de conciencia
- Busca privacidad extrema (zero-storage, datos solo en RAM)
- Quiere estructurar narrativas complejas en formato canónico

## Arquitectura
- **Frontend:** Flutter/Dart (app móvil Android/iOS)
- **Backend:** No aplica (zero-storage, API directa desde app)
- **IA:** Claude Sonnet 4.5 (API directa Anthropic, streaming SSE)
- **RAG:** JSON estáticos locales (CIC + Catecismo)
- **Privacidad:** FLAG_SECURE, biometría, teclado aséptico, botón de pánico

## Core Requirements (Estáticos)
1. Chat efímero (RAM only) para narración libre
2. Destilación: narrativa → especie/número canónico
3. QPL: preguntas para el sacerdote por cada falta
4. Botón de Pánico: purga irreversible + cierre
5. Zero-Storage: sin BD, sin archivos, sin telemetría
6. Privacidad SO: FLAG_SECURE, biometría, teclado sin sugerencias

## Lo implementado (Enero 2026)

### Errores Corregidos
- **E1 (P0):** Unificado botón de pánico — un solo mecanismo con confirmación + purge + cierre. Eliminado FAB redundante.
- **E2 (P1):** Migrado de `flutter_windowmanager` (obsoleto) a `no_screenshot` que ya gestiona FLAG_SECURE.
- **E3 (P0):** Agregado try-catch en `ScreenshotGuard.enable()` en main.dart para evitar crash en emuladores.
- **E4 (P2):** Manejo de error en carga de RAG (canon_loader.dart) — degradación graceful sin crash.
- **E5 (P2):** Corregido nombre de variable confuso en `AnimatedBuilder` de chat_bubble.dart.

### Mejoras Implementadas
- **M1 (P1):** Actualizado modelo de `claude-haiku-4-5` → `claude-sonnet-4-5-20250929`. MaxTokens: 1024 → 2048.
- **M2 (P2):** Flujo de pánico iOS-aware: en iOS navega a pantalla de sesión destruida (Apple no permite cierre programático).
- **M3 (P2):** Streaming visible durante generación de destilación — el usuario ve la respuesta en tiempo real.
- **M4 (P3):** RAG mejorado con expansión de sinónimos en español (pecados capitales, términos coloquiales → canónicos).
- **M5 (P1):** Limpieza de portapapeles después de cada mensaje enviado.
- **M6 (P2):** Orientación limitada a portrait (iOS + Android).
- **M7 (P3):** Tests de integración con mocks para flujo completo Chat → Destilación → QPL.

## Archivos Modificados
| Archivo | Cambios |
|---------|---------|
| `lib/main.dart` | E3: try-catch en ScreenshotGuard |
| `lib/core/ai/claude_provider.dart` | M1: modelo Sonnet, maxTokens 2048 |
| `lib/core/ai/rag/rag_retriever.dart` | M4: sinónimos español |
| `lib/core/ai/rag/canon_loader.dart` | E4: error handling |
| `lib/core/privacy/screenshot_guard.dart` | E2: eliminado flutter_windowmanager |
| `lib/core/privacy/panic_handler.dart` | M2: iOS-aware exit |
| `lib/ui/screens/chat_screen.dart` | E1, M3, M5: pánico unificado, streaming, clipboard |
| `lib/ui/screens/distillation_screen.dart` | E1: pánico con exit |
| `lib/ui/widgets/chat_bubble.dart` | E5: variable rename |
| `pubspec.yaml` | E2: eliminada dependencia obsoleta |
| `ios/Runner/Info.plist` | M6: portrait only |
| `android/app/src/main/AndroidManifest.xml` | M6: screenOrientation portrait |
| `test/core/ai/chat_flow_test.dart` | M7: tests de integración (NUEVO) |

## Backlog / Next Tasks
- **COMPLETADO:** `flutter pub get` — `flutter_windowmanager` eliminado correctamente
- **COMPLETADO:** `flutter analyze` — 0 issues
- **COMPLETADO:** `flutter test` — 84 tests, todos pasaron
- **COMPLETADO:** Auditoría Forense Fase 4 — 17 tests forenses (heap dump, aislamiento, trim, RAG, prompt, API format)
- **P1:** Considerar migración a Edge AI (LLaMA.cpp/Gemma) para eliminar dependencia de red
- **P2:** Añadir animaciones de transición entre pantallas
- **P2:** Modo Iglesia mejorado: pantalla aún más oscura, timer de inactividad
- **P3:** Ampliar base de conocimiento RAG con más cánones y secciones del Catecismo
