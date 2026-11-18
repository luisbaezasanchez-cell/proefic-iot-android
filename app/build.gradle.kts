// Cómo se construye la app. Lo que se toca al publicar una versión está en el
// primer bloque; el resto solo cambia una vez al año, al subir el nivel de API.

plugins {
    id("com.android.application")
}

// ── Lo que cambia entre versiones ──────────────────────────────────────────

// Nombre del portal, sin "https://" y sin barra final. Es el único sitio donde
// está escrito. Hoy es el de pruebas; el definitivo será "app.proefic.es".
val portalHost = "app.proefic.com"

// Versión. Google Play exige que `versionNumero` suba en cada paquete que se
// le envía, aunque sea para arreglar una coma. `versionTexto` es la que ve el
// usuario en la ficha.
val versionNumero = 1
val versionTexto = "1.0.0"

// ── Lo que cambia una vez al año ───────────────────────────────────────────

android {
    // Paquete de la app. Es su identidad en Google Play: no cambia nunca.
    namespace = "es.proefic.iot"

    // Versión de Android con la que se compila.
    compileSdk = 36

    defaultConfig {
        applicationId = "es.proefic.iot"

        // Android más antiguo en el que se puede instalar: 7.0. Es el mínimo
        // que admite android-browser-helper.
        minSdk = 24

        // Nivel de API objetivo: para qué versión de Android está preparada la
        // app. Google Play exige uno reciente y lo sube cada año.
        targetSdk = 36

        versionCode = versionNumero
        versionName = versionTexto

        // El nombre del portal llega al manifest como ${portalHost}…
        manifestPlaceholders["portalHost"] = portalHost

        // …y a un texto, `asset_statements`, que es la declaración "esta app
        // está asociada a este sitio". Tiene que ser un recurso, por eso se
        // genera aquí. Las comillas van con barra (\") porque Android las
        // quitaría de un recurso de texto si no.
        resValue(
            "string",
            "asset_statements",
            """[{ \"relation\": [\"delegate_permission/common.handle_all_urls\"], \"target\": { \"namespace\": \"web\", \"site\": \"https://$portalHost\" } }]""",
        )
    }

    // Permite el `resValue` de arriba. Desde la versión 9 del plugin viene
    // desactivado.
    buildFeatures {
        resValues = true
    }

    // Firma del paquete de publicación con la clave de subida. Los datos llegan
    // por variables de entorno, que pone el workflow de GitHub a partir de los
    // secretos (ver docs/PUBLICAR.md). Sin ellas no hay firma: `bundleRelease`
    // produce un paquete sin firmar que Google Play rechaza.
    val almacenDeClaves: String? = System.getenv("UPLOAD_KEYSTORE_FILE")
    signingConfigs {
        if (almacenDeClaves != null) {
            create("subida") {
                storeFile = file(almacenDeClaves)
                storePassword = System.getenv("UPLOAD_KEYSTORE_PASSWORD")
                keyAlias = "upload"
                // En un almacén PKCS12 la contraseña de la clave es la del almacén.
                keyPassword = System.getenv("UPLOAD_KEYSTORE_PASSWORD")
            }
        }
    }

    buildTypes {
        // `release` es la variante que se publica. La de pruebas, `debug`, no
        // necesita configuración: Android la firma con una clave de usar y tirar.
        release {
            signingConfig = signingConfigs.findByName("subida")
        }
    }
}

dependencies {
    // La única dependencia. Trae la actividad de arranque y el servicio de
    // avisos, y arrastra las bibliotecas de AndroidX que necesita.
    // https://github.com/GoogleChrome/android-browser-helper
    implementation("com.google.androidbrowserhelper:androidbrowserhelper:2.7.4")
}
