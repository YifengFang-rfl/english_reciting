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

// Workaround for file_picker (v11) which conditionally skips applying the
// Kotlin Gradle Plugin when AGP >= 9, expecting AGP's built-in Kotlin to
// compile its sources. Built-in Kotlin is disabled (android.builtInKotlin=false)
// on Flutter < 3.47, so its .kt sources are never compiled and the generated
// plugin registrant fails with "cannot find symbol FilePickerPlugin".
// Force-apply KGP so the plugin's Kotlin sources compile. Applying an already
// applied plugin is a no-op, so this is safe for plugins that apply KGP normally.
subprojects {
    if (name == "file_picker") {
        pluginManager.apply("org.jetbrains.kotlin.android")
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
