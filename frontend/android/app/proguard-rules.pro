# Flutter specific rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep application classes
-keep class com.storelink.app.** { *; }

# Gson / JSON serialization
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**

# OkHttp / Dio
-dontwarn okhttp3.**
-dontwarn okio.**

# Suppress warnings for missing classes
-dontwarn java.lang.invoke.**
