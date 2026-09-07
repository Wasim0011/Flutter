plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase
    id("com.google.gms.google-services")
}

import java.util.Properties
import java.io.FileInputStream

// Read Google Maps API Key from local.properties
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(FileInputStream(localPropertiesFile))
}

// Read release signing config from android/key.properties (not committed to VCS).
// See SIGNING.md for how to generate a keystore and create this file.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.inallcart.customer.demo3"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required for flutter_local_notifications
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.inallcart.customer.demo3"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Google Maps API Key from local.properties with fallback
        val googleMapsApiKey = localProperties.getProperty("GOOGLE_MAPS_API_KEY") ?: "AIzaSyBm324WP5IrhHPc34QeYunXCzxryVwr9tU"
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = googleMapsApiKey

        // Deep link scheme & host (configure in local.properties).
        // DEEP_LINK_SCHEME must match AppConstants.appScheme in the Dart code.
        // DEEP_LINK_HOST should be your website domain (without https://).
        manifestPlaceholders["deepLinkScheme"] =
            localProperties.getProperty("DEEP_LINK_SCHEME") ?: "inallcart"
        manifestPlaceholders["deepLinkHost"] =
            localProperties.getProperty("DEEP_LINK_HOST") ?: "example.com"
    }

    signingConfigs {
        if (keystorePropertiesFile.exists() && keystoreProperties.containsKey("keyAlias")) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = keystoreProperties["storeFile"]?.let { rootProject.file(it as String) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            if (keystorePropertiesFile.exists() && keystoreProperties.containsKey("keyAlias")) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                signingConfig = signingConfigs.getByName("debug")
            }
            // Disable ProGuard/R8 to prevent stripping native Flutter & Firebase classes
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
