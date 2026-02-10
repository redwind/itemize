# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# ML Kit - Text Recognition (Optional languages)
# We don't use these specific language scripts in the base implementation, so we suppress warnings about them missing.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-dontwarn com.google.mlkit.vision.text.common.**

# General ML Kit
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Google Play Core (Split Install / Deferred Components)
# Suppress warnings for Play Core definition classes if not using dynamic features
-dontwarn com.google.android.play.core.**
