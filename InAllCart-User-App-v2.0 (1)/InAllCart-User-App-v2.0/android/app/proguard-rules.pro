# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.

# Stripe SDK - Keep push provisioning classes
-keep class com.stripe.android.pushProvisioning.** { *; }
-dontwarn com.stripe.android.pushProvisioning.**

# Stripe SDK - General rules
-keep class com.stripe.android.** { *; }
-keep interface com.stripe.android.** { *; }

# React Native Stripe SDK
-keep class com.reactnativestripesdk.** { *; }
-dontwarn com.reactnativestripesdk.**

# Keep all classes that might be referenced by Stripe
-keepclassmembers class * {
    @com.stripe.android.* <methods>;
}

# If you're not using push provisioning, you can ignore these warnings
-dontwarn com.stripe.android.pushProvisioning.EphemeralKeyUpdateListener
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivity$g
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Args
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Error
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningEphemeralKeyProvider
