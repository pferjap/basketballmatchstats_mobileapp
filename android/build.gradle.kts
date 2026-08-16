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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
