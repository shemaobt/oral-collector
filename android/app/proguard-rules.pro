-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

-keep class com.shema.oralCollector.** { *; }

-dontwarn com.google.android.play.core.**

# FFmpegKit (ffmpeg_kit_flutter_new_min). The plugin ships keep rules via
# `proguardFiles` (not `consumerProguardFiles`), so they do NOT reach the app's R8
# pass — without re-declaring them here, R8 strips/renames its JNI + reflection
# classes (AbiDetect, FFmpegKitConfig) and release crashes at the first ffmpeg call
# (waveform extraction / segment concat). A clean build / empty missing_rules.txt
# cannot catch JNI breakage; this is verified only by a release device smoke test.
-keep class com.antonkarpenko.ffmpegkit.** { *; }
-dontwarn com.antonkarpenko.ffmpegkit.**
-keepclasseswithmembernames class * {
    native <methods>;
}
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
