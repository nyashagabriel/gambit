# android/app/proguard-rules.pro — GAMBIT TSL
#
# Flutter already ships a proguard config via the plugin.
# These rules extend it for our specific dependencies.

# ── Flutter engine ────────────────────────────────────────────────────────────
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ── OkHttp (used internally by some Flutter plugins) ─────────────────────────
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**

# ── file_picker ───────────────────────────────────────────────────────────────
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# ── shared_preferences ────────────────────────────────────────────────────────
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# ── url_launcher ──────────────────────────────────────────────────────────────
-keep class io.flutter.plugins.urllauncher.** { *; }

# ── Kotlin coroutines (used by some plugins) ──────────────────────────────────
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}

# ── Keep line numbers for crash reports ───────────────────────────────────────
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile