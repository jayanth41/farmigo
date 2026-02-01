buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // REQUIRED for Firebase (latest compatible)
        classpath("com.google.gms:google-services:4.4.2")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Place build output in the workspace-level build directory
rootProject.buildDir = File(rootProject.projectDir, "../build")

subprojects {
    project.buildDir = File(rootProject.buildDir, project.name)
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
