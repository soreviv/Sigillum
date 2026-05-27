# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# local_auth (Biometría)
-keep class com.baseflow.localauth.** { *; }

# Play Core split install — referenciado por Flutter pero no usado en esta app
-dontwarn com.google.android.play.core.**

# Preservar anotaciones para reflexión si es necesario
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes EnclosingMethod
