# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# local_auth (Biometría)
-keep class com.baseflow.localauth.** { *; }

# Preservar anotaciones para reflexión si es necesario
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes EnclosingMethod
