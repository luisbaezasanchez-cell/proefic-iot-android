// Primer fichero que lee Gradle. Dice dos cosas: de dónde se descargan las
// piezas y qué módulos tiene el proyecto.

// De dónde sale el plugin de Android para Gradle (la herramienta que sabe
// construir un APK). El plugin vive en el repositorio de Google; lo que el
// plugin necesita a su vez, en Maven Central.
pluginManagement {
    repositories {
        google()
        mavenCentral()
    }
}

// De dónde salen las bibliotecas de la app (android-browser-helper y AndroidX).
// FAIL_ON_PROJECT_REPOS impide que un módulo añada otro repositorio por su
// cuenta: los únicos orígenes son los dos de esta lista.
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "proefic-iot-android"

// Un solo módulo: la app.
include(":app")
