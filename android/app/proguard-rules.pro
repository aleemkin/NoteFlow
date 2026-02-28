# Flutter Wrapper Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep JavascriptInterface for WebView communication
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Flutter deferred components - ignore missing play core classes
-dontwarn com.google.android.play.core.**

