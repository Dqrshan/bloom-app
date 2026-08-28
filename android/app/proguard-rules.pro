# Flutter ProGuard / R8 optimization rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep native methods
-keepclasseswithmembers class * {
    native <methods>;
}

-dontwarn io.flutter.**
-dontwarn com.bloom.bloom.**
