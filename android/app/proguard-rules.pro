# Keep flutter_local_notifications classes
-keep class com.dexterous.** { *; }

# GSON rules required by the plugin
-keepattributes InnerClasses
-keepattributes Signature
-keepattributes *Annotation*
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Firebase rules
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.** { *; }
-keepattributes Signature
