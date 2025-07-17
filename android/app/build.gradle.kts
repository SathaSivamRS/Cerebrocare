plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services") version "4.4.3" apply false
    // END: FlutterFire Configuration
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.cerebrocare_ieee"
    ndkVersion = "27.0.12077973"  // ✅ Corrected
    compileSdk = flutter.compileSdkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.cerebrocare_ieee"
        minSdkVersion(23)  // ✅ Correct Kotlin DSL
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ Firebase BoM (Bill of Materials)
    implementation(platform("com.google.firebase:firebase-bom:33.16.0"))

    // ✅ Firebase SDKs
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")

    // ✅ Required AndroidX and Kotlin dependencies
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
}

// 👇 Add this to apply the plugin!
apply(plugin = "com.google.gms.google-services")
