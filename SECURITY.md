# Política de Seguridad — Sigillum

## Principio Rector

Sigillum fue diseñado bajo el principio de **Privacy by Design** en su forma más estricta: la ausencia de datos es la mejor protección de datos. No existe ningún sistema que proteja mejor la información que aquel que nunca la almacena.

---

## Arquitectura de Privacidad (Zero-Storage)

### Garantías por diseño

| Garantía | Mecanismo |
|---|---|
| Sin persistencia de sesión | No hay base de datos, ni local ni remota |
| Sin historial de conversaciones | Los mensajes existen solo en el árbol de widgets en RAM |
| Sin telemetría | La app no realiza ninguna llamada de red de analítica |
| Sin identificadores de usuario | No hay login, cuentas ni UUIDs vinculables a personas |
| Sin copias de seguridad automáticas | `android:allowBackup="false"` en el Manifiesto de Android |
| Sin indexación por el SO | `FLAG_SECURE` impide que el sistema operativo capture el contenido |

### Ciclo de vida de los datos

```
Usuario escribe texto
        │
        ▼
  RAM (árbol de widgets Flutter)
        │
        ├── App a segundo plano ──► RAM liberada + pantalla bloqueada
        ├── App cerrada ──────────► RAM destruida por el SO
        └── Botón de Pánico ──────► purga explícita de todos los controladores
                                    + limpieza del portapapeles del SO
```

Ningún fragmento de texto atraviesa una capa de almacenamiento en ningún punto del flujo.

---

## Controles de Privacidad del Sistema Operativo

### Android

| Control | Implementación |
|---|---|
| Bloqueo de capturas de pantalla | `FLAG_SECURE` vía `flutter_windowmanager` |
| Bloqueo de teclado predictivo | `enableIMEPersonalizedLearning: false` en todos los `TextField` |
| Sin autocompletado | `enableSuggestions: false`, `autocorrect: false` |
| Sin revisión ortográfica | `SpellCheckConfiguration.disabled()` |
| Sin portapapeles retenido | `Clipboard.setData('')` al enviar cada mensaje |
| Re-autenticación biométrica | `LocalAuthentication` + `WidgetsBindingObserver` |
| Sin backup de datos | `android:allowBackup="false"` en `AndroidManifest.xml` |

### iOS

| Control | Implementación |
|---|---|
| Bloqueo de capturas | `no_screenshot` (capa de plataforma nativa) |
| Overlay anti-grabación | `StreamBuilder` sobre `screenshotStream` → overlay negro |
| Face ID / Touch ID | `local_auth` con `NSFaceIDUsageDescription` declarado |
| Sin sugerencias de teclado | mismos atributos que Android |

---

## Motor de IA — Condiciones de Privacidad

### Opción A — Edge AI (preferida)

El modelo LLM (LLaMA.cpp / Gemma cuantizado) corre **100% en el dispositivo**:
- Sin conexión de red durante la inferencia.
- El modelo descargado no contiene datos del usuario.
- Los tokens procesados nunca salen del proceso de la app.

### Opción B — API en la nube

Si se utiliza una API externa, el proveedor **debe cumplir obligatoriamente**:

- [ ] Contrato corporativo de **Zero Data Retention** (ZDR) firmado y vigente. *(pendiente: gestión contractual con Anthropic)*
- [x] Ningún prompt se utiliza para entrenamiento de modelos — configurable en Anthropic Console → "Usage Policy: No Training".
- [x] Transmisión exclusivamente sobre TLS 1.3 — garantizado por la infraestructura de `api.anthropic.com`.
- [x] El proveedor no sub-procesa datos a terceros — política vigente de Anthropic (consultar [privacy policy](https://www.anthropic.com/privacy)).

Sin estos requisitos, la Opción B está prohibida en este proyecto.

---

## Base de Conocimiento RAG — Fuentes Autorizadas

El motor RAG está estrictamente acotado a archivos estáticos locales:

- `assets/rag/cic.json` — Código de Derecho Canónico (CIC 1983)
- `assets/rag/catecismo.json` — Catecismo de la Iglesia Católica (CEC)

**Prohibido:** conectar el RAG a APIs web, motores de búsqueda, wikis o cualquier fuente dinámica externa.

---

## Botón de Pánico — Especificación de Purga

Al activarse, el Botón de Pánico debe ejecutar en orden:

```dart
// 1. Limpiar todos los TextEditingController activos
for (final controller in _activeControllers) {
  controller.clear();
}

// 2. Vaciar el historial de conversación en memoria
_conversationHistory.clear();

// 3. Limpiar el portapapeles del SO
await Clipboard.setData(const ClipboardData(text: ''));

// 4. Navegar a pantalla en blanco y destruir el stack de navegación
Navigator.of(context).pushNamedAndRemoveUntil('/lock', (_) => false);
```

Ningún paso puede omitirse. La implementación será auditada en Fase 4.

---

## Auditoría Forense (Fase 4)

En la Fase 4 se realizarán las siguientes pruebas para certificar Zero-Storage:

1. **Volcado de memoria (heap dump)** post-sesión: verificar que no existen strings de conversación en el heap de la app.
2. **Análisis de almacenamiento** (`adb shell run-as com.sigillum.app`): confirmar que el directorio de datos de la app está vacío.
3. **Análisis de tráfico de red** (Charles Proxy / mitmproxy): confirmar cero transmisiones de datos de usuario.
4. **Prueba de captura de pantalla**: confirmar que la galería del dispositivo no registra imágenes de la app.
5. **Prueba de backup**: confirmar que `adb backup` no extrae datos de la app.

---

## Reporte de Vulnerabilidades

Este proyecto es académico y no está en producción pública. Si identificas una vulnerabilidad de privacidad durante el desarrollo o revisión del código:

**Contacto:** Alejandro Viveros Domínguez  
**Email:** drviverosorl@gmail.com  
**Asunto:** `[SIGILLUM-SECURITY] <descripción breve>`

**No abrir issues públicos** con detalles de vulnerabilidades de privacidad hasta que sean confirmadas y corregidas.

---

## Declaración de Conformidad

Este software fue diseñado para cumplir con:

- **GDPR (Reglamento General de Protección de Datos)** — Art. 25: Privacy by Design and by Default.
- **CCPA** — por arquitectura (no hay datos personales que gestionar).
- **Secreto de Confesión (Canon 983 CIC)** — la app no puede ser subpoenada porque no retiene datos.

---

Copyright © 2026 Alejandro Viveros Domínguez. Todos los derechos reservados.
