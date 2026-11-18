// Fichero de compilación de la raíz. Solo fija la versión del plugin de Android
// para Gradle; quien lo usa es el módulo app/.
//
// Al subir esta versión hay que mirar qué Gradle mínimo pide y, si hace falta,
// subir también el wrapper (gradle/wrapper/gradle-wrapper.properties). La
// tabla está en https://developer.android.com/build/releases/gradle-plugin
plugins {
    id("com.android.application") version "9.5.1" apply false
}
