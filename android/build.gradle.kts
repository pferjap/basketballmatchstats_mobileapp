allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Some plugins (e.g. sentry_flutter) still compile their Kotlin sources with
// languageVersion/apiVersion 1.6, which Kotlin 2.4.0 (the Flutter-default KGP
// for this toolchain) no longer supports: "Language version 1.6 is no longer
// supported; use version 2.0 or greater instead." Bump any subproject that
// requests a pre-2.0 Kotlin language/api version up to the minimum supported
// value so those plugins keep compiling. Versions >= 2.0 are left untouched.
subprojects {
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            val minVersion = org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_2_0
            if ((languageVersion.orNull ?: minVersion) < minVersion) {
                languageVersion.set(minVersion)
            }
            if ((apiVersion.orNull ?: minVersion) < minVersion) {
                apiVersion.set(minVersion)
            }
        }
    }
}

// Some plugins (e.g. sentry_flutter) still declare a lower compileSdk than the
// app. When a transitive plugin such as package_info_plus publishes AAR
// metadata requiring consumers to compile against Android SDK 36, those lagging
// plugins fail :checkDebugAarMetadata with:
//   "Dependency ':package_info_plus' requires ... compile against version 36 or
//    later ... :sentry_flutter is currently compiled against android-34."
// Raise every Android subproject that compiles below the app's compileSdk up to
// at least 36 so plugin AAR metadata requirements are satisfied. Subprojects
// already at 36+ are left untouched.
subprojects {
    val forceCompileSdk =
        Action<Project> {
            val android = extensions.findByName("android")
            if (android is com.android.build.gradle.BaseExtension) {
                val current =
                    android.compileSdkVersion
                        ?.removePrefix("android-")
                        ?.toIntOrNull() ?: 0
                if (current < 36) {
                    android.compileSdkVersion(36)
                }
            }
        }
    if (state.executed) {
        forceCompileSdk.execute(this)
    } else {
        afterEvaluate { forceCompileSdk.execute(this) }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
