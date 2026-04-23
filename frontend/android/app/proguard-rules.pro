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

# Flutter Play Store deferred components (not used but referenced by Flutter engine)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task
