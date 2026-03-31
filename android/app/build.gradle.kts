// android/app/build.gradle — GAMBIT TSL
//
// Signing:
//   Create a keystore once:
//     keytool -genkey -v -keystore gambit-release.jks \
//             -keyalg RSA -keysize 2048 -validity 10000 \
//             -alias gambit
//
//   Then copy gambit-release.jks to android/app/ (add to .gitignore!)
//   and create android/key.properties (also .gitignored):
//
//     storePassword=<your store password>
//     keyPassword=<your key password>
//     keyAlias=gambit
//     storeFile=gambit-release.jks

plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}

// Load signing properties — file must exist for release builds
def keystorePropertiesFile = rootProject.file("key.properties")
def keystoreProperties     = new Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    namespace           "zw.co.gambit.tsl"    // Change to your actual reverse-domain name
    compileSdk          flutter.compileSdkVersion
    ndkVersion          flutter.ndkVersion

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId   "zw.co.gambit.tsl"
        minSdk          flutter.minSdkVersion
        targetSdk       flutter.targetSdkVersion
        versionCode     flutter.versionCode
        versionName     flutter.versionName
    }

    signingConfigs {
        release {
            if (keystorePropertiesFile.exists()) {
                keyAlias        keystoreProperties["keyAlias"]
                keyPassword     keystoreProperties["keyPassword"]
                storeFile       file(keystoreProperties["storeFile"])
                storePassword   keystoreProperties["storePassword"]
            }
        }
    }

    buildTypes {
        debug {
            // Debug keeps default signing — no action needed
            applicationIdSuffix ".debug"
            versionNameSuffix   "-debug"
        }
        release {
            signingConfig       signingConfigs.release
            minifyEnabled       true
            shrinkResources     true
            proguardFiles getDefaultProguardFile("proguard-android-optimize.txt"),
                          "proguard-rules.pro"
        }
    }
}

flutter {
    source "../.."
}