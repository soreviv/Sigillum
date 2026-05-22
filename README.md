# Sigillum

**Aplicación Andragógica de Estructuración Sacramental**

> Herramienta móvil de privacidad extrema que asiste al feligrés católico a estructurar su examen de conciencia previo a la confesión, destilando narrativas complejas en la *especie y número* del pecado (Canon 979 — CIC).

Proyecto de intervención académica · Maestría en Educación (Educación Social)
Autor: Alejandro Viveros Domínguez

---

## El Problema

| Problema | Descripción |
|---|---|
| Ansiedad Narrativa | El feligrés carece de formación para estructurar faltas complejas |
| Fatiga por Compasión Pastoral | El sacerdote se desgasta al procesar narrativas desorganizadas y morbosas |
| Brecha de Comunicación | Desconexión relacional en el confesionario por falta de estructura |

**Solución:** Un chatbot efímero que destila la historia del usuario en una lista canónica estructurada y genera *Question Prompt Lists (QPL)* para empoderar un diálogo constructivo con el confesor.

---

## Pilares de Ingeniería (Restricciones Innegociables)

### Zero-Storage
- Sin base de datos. Sin Firebase. Sin SQLite. Sin archivos locales de sesión.
- Toda la información vive exclusivamente en **RAM**.
- Se destruye irreversiblemente al: cerrar la app · pasar a segundo plano · presionar el Botón de Pánico.
- Sin login. Sin cuentas de usuario. Sin telemetría.

### Privacidad de Sistema Operativo
- `FLAG_SECURE` (Android) — bloquea capturas de pantalla a nivel de kernel.
- Ofuscación de pantalla (iOS) — cubre el contenido en el app switcher.
- Teclado sin sugerencias, sin autocorrección, sin aprendizaje predictivo (`enableIMEPersonalizedLearning: false`).
- Bloqueo biométrico instantáneo al perder el foco de pantalla.

### IA Aséptica
- Prohibido simular empatía humana (`"entiendo"`, `"lo siento"`).
- No da absolución ni suplanta al sacerdote.
- Solo estructura, nunca aconseja directamente.
- El motor RAG está acotado exclusivamente al Código de Derecho Canónico y el Catecismo de la Iglesia Católica.

---

## Arquitectura

```
┌─────────────────────────────────────────────────────┐
│                    Flutter App                       │
│                                                     │
│  ┌──────────────┐   ┌──────────────────────────┐   │
│  │ Privacy Layer│   │      UI Layer            │   │
│  │              │   │                          │   │
│  │ FLAG_SECURE  │   │  ChatScreen (Desahogo)   │   │
│  │ BiometricLock│   │  DestilationScreen       │   │
│  │ KeyboardConf │   │  QPL (Opt-In Educativo)  │   │
│  └──────────────┘   └──────────────────────────┘   │
│                                                     │
│  ┌──────────────────────────────────────────────┐   │
│  │              AI Engine (RAM only)            │   │
│  │                                              │   │
│  │  Opción A: LLM Local (LLaMA.cpp / Gemma)    │   │
│  │  Opción B: API + Zero Data Retention         │   │
│  │                                              │   │
│  │  RAG ──► JSON/Markdown estáticos             │   │
│  │          (CIC + Catecismo)                   │   │
│  └──────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
        │ Botón de Pánico │
        ▼
   RAM.purge() — destrucción irreversible
```

---

## Flujo de Pantallas

```
1. Pantalla de Desahogo    → Chat donde el usuario narra su situación
2. Pantalla de Destilación → Lista: pecados resumidos (especie / número)
3. QPL (Opt-In)            → "¿Qué preguntarle al sacerdote?" por falta
```

---

## Roadmap de Desarrollo

| Fase | Semanas | Descripción | Estado |
|------|---------|-------------|--------|
| **Fase 1** | 1–2 | Entorno de Privacidad — bloqueos a nivel de SO | ✅ Completada |
| **Fase 2** | 3–6 | Motor de IA + RAG stateless en RAM | ✅ Completada |
| **Fase 3** | 7–9 | UI/UX: Chat · Destilación · QPL · Modo Iglesia · Botón de Pánico | ✅ Completada |
| **Fase 4** | 10–12 | Auditoría forense de memoria + pruebas de campo | ✅ Completada |

---

## Fase 1 — Entorno de Privacidad (Completada)

**Archivos implementados:**

```
lib/
└── core/
    └── privacy/
        ├── screenshot_guard.dart   # FLAG_SECURE + overlay iOS anti-grabación
        ├── biometric_guard.dart    # Bloqueo/desbloqueo biométrico por ciclo de vida
        └── keyboard_config.dart   # TextField aséptico + limpieza de portapapeles
```

**Dependencias de privacidad:**

```yaml
local_auth: ^3.0.1          # Face ID / Fingerprint
flutter_windowmanager: ^0.2.0  # FLAG_SECURE (Android)
no_screenshot: ^1.1.0       # Prevención capturas (iOS + Android)
```

---

## Requisitos de Desarrollo

| Herramienta | Versión mínima |
|---|---|
| Flutter | 3.44.0 |
| Dart | 3.12.0 |
| Android SDK | API 23+ (Android 6.0) |
| Xcode | 15+ (para iOS) |

```bash
# Clonar y preparar
git clone <repo>
cd Sigillum
flutter pub get
flutter analyze
```

---

## Base de Conocimiento (RAG)

El motor de IA está estrictamente acotado a fuentes canónicas oficiales:

- **Código de Derecho Canónico (CIC 1983)** — especialmente Canon 979 (especie y número)
- **Catecismo de la Iglesia Católica (CEC)**

No se utiliza ninguna fuente externa, base de datos en línea ni modelo de lenguaje no supervisado.

---

## Licencia

Copyright © 2026 Alejandro Viveros Domínguez. Todos los derechos reservados.
Consulta el archivo [LICENSE](LICENSE) para más información.

---

## Política de Seguridad

Consulta [SECURITY.md](SECURITY.md) para conocer la arquitectura de privacidad y el proceso de reporte de vulnerabilidades.
