# Proefic IoT para Android

La app de Proefic IoT para Google Play. Paquete `es.proefic.iot`.

Este repositorio no contiene el portal. Contiene el envoltorio que lo lleva a
Google Play, y nada más.

- Cómo publicar, paso a paso: [docs/PUBLICAR.md](docs/PUBLICAR.md)
- Textos y gráficos de la ficha de Play: [docs/TIENDA.md](docs/TIENDA.md)
- Por qué está hecho así y qué queda por confirmar: [CAMBIOS.md](CAMBIOS.md)

## Qué es una Trusted Web Activity

Una *Trusted Web Activity* (TWA) es una app Android sin pantallas propias: al
abrirla, le pide a Chrome que muestre una web a pantalla completa, sin barra de
direcciones. Chrome solo quita la barra si la web y la app demuestran que son
del mismo dueño: la web publica un fichero (`/.well-known/assetlinks.json`)
con la huella de la clave que firma la app. Como quien pinta es Chrome, la app
comparte con él la sesión y los datos, y cada versión nueva del portal llega
sin volver a publicar la app.

## Mapa del repositorio

No hay código Java ni Kotlin. Todo lo que hace la app está en el manifest y en
los recursos.

### La app

| Fichero | Qué es |
|---|---|
| `app/build.gradle.kts` | Cómo se construye la app. Arriba, lo que cambia entre versiones: el **nombre del portal** y la **versión**. Debajo, el paquete, los niveles de API, la firma y la única dependencia. |
| `app/src/main/AndroidManifest.xml` | El fichero central. Declara los permisos, la actividad de arranque, los enlaces que abren la app, los avisos y los colores. Cada bloque lleva su explicación. |
| `app/src/main/res/values/strings.xml` | El nombre de la app. |
| `app/src/main/res/values/colors.xml` | Los colores: barra clara, barra oscura, fondo de arranque claro y fondo del icono. |
| `app/src/main/res/values-night/colors.xml` | El fondo de arranque con el tema oscuro. |
| `app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` | El icono de la app en Android 8 y posteriores: la imagen `maskable` sobre un fondo de color. |
| `app/src/main/res/mipmap-xxxhdpi/ic_launcher_maskable.png` | La imagen de ese icono. Copia de `icon-512-maskable.png` del portal. |
| `app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` | El icono de la app en Android 7. Copia de `icon-192.png` del portal. |
| `app/src/main/res/drawable-xxxhdpi/splash.png` | La imagen de la pantalla de arranque. Copia de `icon-512.png` del portal. |
| `app/src/main/res/drawable-xxxhdpi/ic_notification_icon.png` | El icono pequeño de los avisos: una silueta blanca sobre transparente, 96 × 96 px. |
| `app/src/main/res/xml/filepaths.xml` | La carpeta por la que la app le pasa a Chrome la imagen de arranque. |

Las imágenes están en un solo tamaño (`xxxhdpi`, el mayor). Android las reduce
para las pantallas de menos resolución.

### La compilación

| Fichero | Qué es |
|---|---|
| `settings.gradle.kts` | De dónde se descargan las piezas (Google y Maven Central) y qué módulos hay (uno, `app`). |
| `build.gradle.kts` | La versión del plugin de Android para Gradle. |
| `gradle.properties` | Memoria para Gradle. |
| `gradlew`, `gradlew.bat` | El *wrapper*: el programa que se ejecuta para compilar. Descarga la versión exacta de Gradle que pide el proyecto, así no hay que instalarlo. El primero es para Linux y macOS; el segundo, para Windows. |
| `gradle/wrapper/gradle-wrapper.properties` | Qué versión de Gradle descarga el wrapper, y la suma de control que debe tener. |
| `gradle/wrapper/gradle-wrapper.jar` | El código del wrapper. Es el único binario ejecutable del repositorio; lo genera Gradle. |
| `.gitignore` | Lo que git no debe guardar: lo que genera la compilación y cualquier almacén de claves. |

### La integración continua

| Fichero | Qué es |
|---|---|
| `.github/workflows/ci.yml` | En cada subida: comprueba que no hay claves, pasa el análisis estático, compila el APK de depuración y lo deja para descargar. |
| `.github/workflows/publicacion.yml` | A mano o con una etiqueta `v*`: construye el paquete de publicación (`.aab`) firmado. |
| `ci/comprobar-claves.sh` | Falla si hay un almacén de claves o una clave privada en el repositorio. |
| `ci/comprobar-apk.sh` | Enseña la ficha del APK y falla si pide un permiso que no esté en su lista. |
| `ci/construir-aab.sh` | Los pasos de la firma: comprueba la clave, compila, comprueba la firma y escribe la huella. |

### La documentación

| Fichero | Qué es |
|---|---|
| `README.md` | Este fichero. |
| `docs/PUBLICAR.md` | Los pasos hasta tener la app en Play, y la prueba a mano en el móvil. |
| `docs/TIENDA.md` | Borrador de los textos de la ficha y lista de gráficos. |
| `CAMBIOS.md` | El diseño y la entrega de cada versión. |

## Cómo compilar

### En GitHub (lo normal)

No hace falta instalar nada. Cada subida a cualquier rama lanza la integración
continua:

1. En GitHub, pestaña **Actions**, workflow **CI**, la ejecución más reciente.
2. Si está en verde, al pie de la página, en **Artifacts**, está
   `app-debug.apk`.

En el registro del paso «Ficha del APK y permisos» se ve qué se ha construido:
paquete, versión, niveles de API, portal al que apunta y permisos.

### En un ordenador

Hace falta **JDK 17** y el **SDK de Android**. Lo más sencillo es instalar
[Android Studio](https://developer.android.com/studio), que trae los dos, y
abrir con él la carpeta del repositorio.

Desde una terminal, en la raíz del repositorio:

```bash
./gradlew lint assembleDebug
```

En Windows es `gradlew.bat lint assembleDebug`. Si Gradle no encuentra el SDK,
hay que decirle dónde está con la variable de entorno `ANDROID_HOME`.

`lint` es el análisis estático; `assembleDebug` construye el APK, que queda en
`app/build/outputs/apk/debug/app-debug.apk`.

### Instalar el APK de depuración por cable

1. En el móvil: activar las **opciones de desarrollador** y, dentro, la
   **depuración por USB**.
2. Conectar el móvil y ejecutar:

   ```bash
   adb install app-debug.apk
   ```

   `adb` viene con el SDK de Android, en la carpeta `platform-tools`.

Tres cosas que hay que saber del APK de depuración:

- **Se ve la barra de direcciones.** Está firmado con una clave de usar y
  tirar que se crea en cada compilación, así que el portal no puede
  reconocerlo. Es lo esperado.
- **No se puede instalar encima de otro.** Cada APK de la integración continua
  lleva una firma distinta, y tampoco coincide con la de Google Play. Si el
  móvil ya tiene la app, hay que desinstalarla antes.
- **Los enlaces del portal no lo abren**, por el mismo motivo.

Para probarlo sin barra hay que pedirle a Chrome que no compruebe ese sitio.
Es un ajuste de desarrollo, solo en ese móvil:

1. En Chrome, abrir `chrome://flags`, buscar *Enable command line on
   non-rooted devices* y activarlo.
2. Con el móvil conectado:

   ```bash
   adb shell "echo '_ --disable-digital-asset-link-verification-for-url=\"https://app.proefic.com\"' > /data/local/tmp/chrome-command-line"
   ```

3. Cerrar Chrome del todo (Ajustes > Aplicaciones > Chrome > Forzar
   detención) y abrir la app.

Para deshacerlo: `adb shell rm /data/local/tmp/chrome-command-line`.

La orden es la que usa Bubblewrap (`enable-debug.sh`) y la que cita la
documentación de android-browser-helper. No se ha probado en este proyecto.

## Cómo cambiar cosas

Después de cualquier cambio que deba llegar a los usuarios hay que **subir la
versión** y publicar (ver «Publicar una versión nueva»).

### El nombre del portal

Un solo valor, al principio de `app/build.gradle.kts`:

```kotlin
val portalHost = "app.proefic.com"
```

Sin `https://` y sin barra final. De ahí salen la dirección de arranque, los
enlaces que abren la app y la declaración de asociación con el sitio.

Antes de cambiarlo, el nombre nuevo tiene que servir su propio
`/.well-known/assetlinks.json` (docs/PUBLICAR.md, paso 6).

Para los usuarios, cambiar de nombre es como cambiar de web: Chrome guarda la
sesión, los datos y el permiso de avisos por cada nombre. Tendrán que iniciar
sesión y aceptar los avisos otra vez.

### El nombre de la app

`app/src/main/res/values/strings.xml`, el texto `app_name`. Es el que sale
bajo el icono y en los avisos. El título de la ficha de Google Play es otra
cosa: se cambia en la consola.

### El icono

Sustituir, con el mismo nombre y tamaño:

| Fichero | Qué poner |
|---|---|
| `mipmap-xxxhdpi/ic_launcher_maskable.png` | El icono *maskable* del portal, 512 × 512. |
| `mipmap-xxxhdpi/ic_launcher.png` | El icono normal del portal, 192 × 192. |
| `drawable-xxxhdpi/splash.png` | El icono normal del portal, 512 × 512. Es la imagen de arranque. |
| `drawable-xxxhdpi/ic_notification_icon.png` | La silueta del icono: 96 × 96, blanco puro sobre fondo transparente. Android solo usa la transparencia. Tiene que ser PNG. |

Si cambia el color de fondo del icono, cambiar también `icono_fondo` en
`values/colors.xml`.

El icono de la ficha de Google Play se sube aparte, en la consola.

### Los colores

| Color | Fichero | Nombre |
|---|---|---|
| Barra, tema claro | `values/colors.xml` | `barra` |
| Barra, tema oscuro | `values/colors.xml` | `barra_oscura` |
| Fondo de arranque, tema claro | `values/colors.xml` | `fondo_arranque` |
| Fondo de arranque, tema oscuro | `values-night/colors.xml` | `fondo_arranque` |

La barra de navegación inferior usa los mismos colores que la superior. Para
separarlos, crear dos colores nuevos y ponerlos en las líneas
`NAVIGATION_BAR_…` del manifest.

## Publicar una versión nueva

1. En `app/build.gradle.kts`, subir `versionNumero` en uno y poner el
   `versionTexto` nuevo. Google Play rechaza un paquete con un número que ya
   ha recibido.
2. Subir el cambio a `main` y esperar a que la integración continua esté en
   verde.
3. Crear la etiqueta y subirla:

   ```bash
   git tag v1.0.1
   git push origin v1.0.1
   ```

4. En **Actions**, workflow **Publicación**: al terminar, descargar
   `app-release.aab` de **Artifacts**.
5. Subirlo a Google Play desde la consola.

La primera vez hay más pasos: están en [docs/PUBLICAR.md](docs/PUBLICAR.md).

## Subir el nivel de API (una vez al año)

Google Play exige que las apps apunten a una versión reciente de Android, y
sube el listón cada año, normalmente con fecha límite el 31 de agosto. La
consola avisa con meses de antelación.

1. **Mirar qué nivel pide Play**:
   <https://developer.android.com/google/play/requirements/target-sdk>
2. **Mirar qué plugin de Android para Gradle lo admite**:
   <https://developer.android.com/build/releases/gradle-plugin>. La tabla de
   compatibilidad de cada versión dice el nivel de API máximo, el Gradle
   mínimo y el JDK.
3. **Subir el plugin** en `build.gradle.kts` (raíz).
4. **Subir Gradle**, si el plugin lo pide. Los datos de la versión están en
   <https://services.gradle.org/versions/current>. Ejecutar dos veces (la
   primera cambia la versión, la segunda regenera el wrapper con ella):

   ```bash
   ./gradlew wrapper --gradle-version X.Y.Z --gradle-distribution-sha256-sum SUMA
   ```

   `SUMA` es el valor `checksum` de esa página. Después, comprobar que
   `sha256sum gradle/wrapper/gradle-wrapper.jar` da el valor
   `wrapperChecksum` de la misma página.
5. **Subir el JDK**, si el plugin lo pide: en los dos workflows, cambiar
   `JAVA_HOME_17_X64` por la variable del JDK nuevo (`JAVA_HOME_21_X64`…).
6. **Subir `compileSdk` y `targetSdk`** en `app/build.gradle.kts`, al mismo
   número.
7. **Subir android-browser-helper** a su última versión, en el mismo fichero:
   <https://github.com/GoogleChrome/android-browser-helper>. Mirar qué ha
   cambiado; en esta biblioteca los cambios a veces piden tocar el manifest.
8. **Leer los cambios de comportamiento** de la versión nueva de Android para
   las apps que apuntan a ella («Behavior changes: apps targeting Android N»
   en developer.android.com). En una app sin pantallas propias casi nunca
   afectan.
9. Subir la versión de la app, comprobar que la integración continua está en
   verde, **probar el APK en un móvil** y publicar.

## Añadir un segundo nombre de confianza

No está hecho. Hará falta si el inicio de sesión del portal pasa a una página
que vive en otro nombre **que sea de Proefic** (por ejemplo
`login.proefic.es`). Sin esto la app funciona igual, pero esa página se ve
con barra de direcciones.

1. Crear `app/src/main/res/values/arrays.xml`:

   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <resources>
       <string-array name="additional_trusted_origins">
           <item>https://login.proefic.es</item>
       </string-array>
   </resources>
   ```

2. En el manifest, dentro de la actividad `LauncherActivity`, junto a
   `DEFAULT_URL`:

   ```xml
   <meta-data
       android:name="android.support.customtabs.trusted.ADDITIONAL_TRUSTED_ORIGINS"
       android:resource="@array/additional_trusted_origins" />
   ```

3. En `app/build.gradle.kts`, añadir el nombre nuevo a `asset_statements`:
   un segundo objeto, igual que el primero y con el otro `site`, dentro de los
   mismos corchetes.
4. El nombre nuevo tiene que servir su propio
   `/.well-known/assetlinks.json`, con el mismo contenido que el del portal.
5. **No** añadirle un filtro de enlaces (`intent-filter`): los enlaces a la
   página de identidad no tienen por qué abrir la app.

Si la página de identidad es de un tercero (Cloudflare Access, Google,
Microsoft) no se puede hacer: no hay forma de publicar el `assetlinks.json` en
un nombre ajeno. Esa pantalla se verá siempre con barra, y es lo correcto.

## Avisos del análisis estático

`lint` termina con 0 errores y estos avisos, que son esperados:

| Aviso | Por qué se deja |
|---|---|
| `OldTargetApi`, `GradleDependency` | Existe un Android más nuevo que el nivel 36. Se sube una vez al año, cuando Play lo pide. |
| `ExportedService` | El servicio de avisos está abierto a otras apps porque quien lo llama es Chrome. El servicio comprueba por su cuenta quién llama. |
| `DataExtractionRules` | Pide un fichero que detalle qué se copia en una copia de seguridad. La app no guarda datos del usuario. |
| `IconLauncherShape` (2) | Los iconos del portal ocupan todo el cuadrado. En el *maskable* es obligado; el otro solo se ve en Android 7. |
| `MonochromeLauncherIcon` | No hay versión monocroma del icono para los «iconos con tema» de Android 13 y posteriores. |

Si aparece alguno que no esté en esta tabla, hay que leerlo.
