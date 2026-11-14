# ProGuard rules for Lammah Flutter application
-dontwarn org.slf4j.**
-dontwarn javax.annotation.**
-dontwarn org.checkerframework.**
-keep class org.slf4j.** { *; }

# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**
-ignorewarnings
