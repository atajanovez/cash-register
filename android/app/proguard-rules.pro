# shared_preferences_android 2.5.x calls into Kotlin through JNI, looking
# classes and methods up by name. It ships no keep rules, so R8 strips or
# renames them in release builds and SharedPreferences.getInstance() throws
# at startup (black screen). The bridge also touches Kotlin stdlib types
# (Result, coroutine intrinsics), so keep those as well.
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class kotlin.** { *; }
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlin.**
-dontwarn kotlinx.coroutines.**
