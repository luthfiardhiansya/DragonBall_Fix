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

// image_picker_android's release lint currently crashes with the JDK/AGP
// combination used by this project while analyzing its JavaDoc. The plugin
// remains compiled and packaged; only its broken release lint task is skipped.
subprojects {
    tasks.configureEach {
        if (project.name == "image_picker_android" && name == "lintVitalAnalyzeRelease") {
            enabled = false
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
