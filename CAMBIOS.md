# Cambios

Este documento tiene dos partes: el **diseño**, escrito antes del código, y la
**entrega**, escrita al terminar. Lo que está marcado **«por confirmar»** es una
decisión tomada por lo más sencillo que el dueño tiene que validar.

---

## 1. Diseño — versión 1.0.0 (18-11-2026)

### 1.1 Qué se construye

Una app Android sin pantallas propias que abre el portal `https://<nombre>/` a
pantalla completa con el Chrome del móvil (una *Trusted Web Activity*, TWA).
El repositorio contiene solo ese envoltorio: un manifest, unos recursos y la
configuración de compilación. No hay ni una línea de Java o Kotlin.

Lo que el envoltorio aporta sobre «añadir a pantalla de inicio»:

- está en Google Play con el paquete `es.proefic.iot`;
- los avisos push salen a nombre de la app, no de Chrome;
- los enlaces `https://<nombre>/…` (el QR de una etiqueta, una invitación)
  abren la app.

### 1.2 Decisiones y por qué

**D1. Proyecto escrito a mano con la biblioteca `android-browser-helper`, sin
Bubblewrap.** Bubblewrap es un generador: a partir de un `twa-manifest.json`
escribe un proyecto Android que usa esta misma biblioteca. Lo he descartado
tras leer su plantilla en la versión 1.27.0 (09-10-2026):

| | Bubblewrap 1.27.0 | Proyecto a mano |
|---|---|---|
| Nivel de API que deja | 36 (correcto) | 36 |
| Plugin de Android para Gradle | 8.9.1, fijado por la plantilla | 9.5.1, lo fijamos nosotros |
| Gradle | 8.11.1, fijado por la plantilla | 9.9.1 |
| Repositorios de dependencias | incluye `jcenter()`, un servicio ya cerrado | `google()` y `mavenCentral()` |
| Código | 3 clases Java generadas, vacías en nuestro caso | ninguna |
| Recursos | 21 imágenes generadas, una tarea que genera `shortcuts.xml`, 18 valores inyectados desde Gradle | 4 imágenes, 3 de ellas copia literal del portal |
| Herramientas en la integración continua | Node ≥ 18, el paquete de npm y, además, JDK y SDK de Android | JDK y SDK de Android, que ya vienen en la máquina de GitHub |
| Qué se lee para entenderlo | `twa-manifest.json` **y** el proyecto generado | el proyecto |

Con Bubblewrap habría que elegir entre guardar en el repositorio un proyecto
generado que nadie ha escrito, o regenerarlo en cada compilación y depender de
que la plantilla del día dé el mismo resultado. Escrito a mano son menos
piezas, todas se pueden leer, y la integración continua las reconstruye igual
siempre porque no hay paso de generación.

El precio: cuando la biblioteca cambie, hay que mirar a mano qué cambió.
Para acotarlo, el manifest sigue la plantilla de Bubblewrap y la demo
`twa-basic` de la propia biblioteca, que son la configuración más usada; cada
desviación está anotada aquí.

**D2. Sin código propio.** La biblioteca trae la actividad de arranque
(`LauncherActivity`) y el servicio de avisos (`DelegationService`), y se
configuran desde el manifest. La demo oficial `twa-basic` funciona así.

**D3. El nombre del portal es un único valor.** `portalHost`, al principio de
`app/build.gradle.kts`. De él salen los cuatro sitios donde hace falta: la
dirección de arranque, el filtro de enlaces, la dirección de «gestionar
espacio» y la declaración `asset_statements`. Los tres primeros llegan al
manifest como *placeholder* (`${portalHost}`); el cuarto tiene que ser un
recurso de texto y lo genera Gradle (`resValue`). Empieza en
`app.proefic.com`. Pasar a `app.proefic.es` es cambiar ese valor y la versión.

**D4. Versiones.** Las más recientes publicadas el 18-11-2026, comprobadas en
su fuente (tabla 1.4). El nivel de API objetivo es el **36**, que es el que
Google Play exige desde el 31-08-2026. El de compilación es el mismo.

**D5. Android mínimo: 7.0 (nivel 24).** Es el mínimo de la biblioteca. No
restrinjo más por mi cuenta. *Por confirmar.*

**D6. Permisos: dos, y ninguno toca datos del usuario.**

- `POST_NOTIFICATIONS`: Android 13 y posteriores lo exigen para mostrar
  cualquier aviso.
- `REORDER_TASKS`: traer la app al frente cuando se toca un aviso y ya estaba
  abierta. Es de nivel «normal»: se concede al instalar, sin preguntar.
  *Añadido durante la implementación; el primer borrador de este diseño decía
  «un solo permiso».* Desde junio de 2026 la actividad de la biblioteca que
  hace ese trabajo (`FocusActivity`) llama a `moveTaskToFront`, y su
  documentación dice que la app debe declarar este permiso y exportar la
  actividad. La plantilla de Bubblewrap 1.27.0 no lo hace. Lo declaro porque
  «tocar el aviso abre el dispositivo» es un requisito y no puedo probarlo en
  un móvil; si la prueba a mano funciona igual sin él, se puede quitar.
  *Por confirmar.*

Sin ubicación, sin pagos, sin analítica: no se añaden los módulos
`locationdelegation` ni `billing` de la biblioteca. No se declara `INTERNET`:
quien navega es Chrome, no la app.

*Cámara.* El envoltorio **no declara nada**. Lo que he encontrado:

- La documentación de arquitectura de Chromium
  (`components/webapps/docs/android_architecture.md`) dice que en una TWA se
  delegan en la app los permisos de «notifications, location» y nada más.
- El código de Chrome lo confirma: la clase que gestiona los permisos de una
  TWA (`InstalledWebappPermissionManager`) solo trata `NOTIFICATIONS` y
  `GEOLOCATION`.
- La biblioteca solo ofrece delegación para esos dos casos.

La cámara, por tanto, sigue el camino de cualquier web: el portal la pide con
`getUserMedia`, Chrome pregunta al usuario y el permiso de Android es el de
Chrome. No he encontrado ninguna página oficial que lo diga con la palabra
«cámara»; lo deduzco de que la lista de permisos delegados es cerrada. Queda
como punto de la prueba a mano.

**D7. Avisos delegados.** Se declara `DelegationService` y un icono pequeño
(`ic_notification_icon`). El aviso sale a nombre de «Proefic IoT».

Dos cosas que he visto al leer el código y que afectan a lo que se ve:

- *El icono tiene que ser un PNG.* AndroidX lo lee con
  `BitmapFactory.decodeResource`, que no entiende dibujos vectoriales.
- *Chrome solo usa el icono de la app si la web no envía el suyo.* En
  `TrustedWebActivityClient.fallbackToIconFromServiceIfNecessary`, el icono
  del servicio es un respaldo. El service worker del portal envía hoy
  `badge: '/icons/icon-192.png'`, así que Chrome usará esa imagen, que al ser
  opaca se verá como un cuadrado liso. **Esto se arregla en el portal**, no
  aquí: quitar `badge` de `showNotification`, o servir uno monocromo con
  transparencia. Va en la lista de pendientes.

La importancia del canal de avisos es la normal (suena, no se despliega sobre
la pantalla). *Por confirmar.*

**D8. Enlaces.** Un filtro `VIEW` + `BROWSABLE` para `https://<nombre>` con
`autoVerify`, sin restringir rutas: `/d/nuevo?code=…` y `/compartir?code=…`
entran por ahí. La biblioteca solo acepta una dirección entrante si es del
mismo origen que la de arranque, que es nuestro caso.

**D9. Sin navegador compatible: pestaña personalizada.** Es el comportamiento
por defecto de la biblioteca. Lo dejo además escrito en el manifest
(`FALLBACK_STRATEGY = customtabs`) para que se lea.

**D10. Iconos y pantalla de arranque.** Del portal se copian sin tocar
`icon-512.png` (imagen de arranque), `icon-512-maskable.png` (icono
adaptativo) e `icon-192.png` (icono para Android 7, que no tiene iconos
adaptativos). Un solo tamaño de cada uno: Android reescala.

- El icono adaptativo pone el `maskable` sobre un fondo `#256ABF`, que es el
  color del borde de la imagen, con el mismo margen que usa Bubblewrap (8,5 dp)
  para que la zona segura web coincida con la de Android.
- El icono de los avisos no puede salir de esos PNG porque son opacos. Lo he
  dibujado a partir de los trazos de `favicon.svg` del portal: el mismo
  indicador, en blanco sobre transparente. *Por confirmar.*
- La imagen de arranque es el icono a 128 dp, centrado. *Por confirmar.*

**D11. Colores.** Barra: `#FCFCFB` / `#1A1A19`. Fondo de arranque: `#F1F0EC` /
`#111110`. La barra de navegación de abajo no estaba en el encargo: le pongo
los mismos colores que a la de arriba. *Por confirmar.* La línea divisoria de
esa barra se fija al mismo color porque, si no, la biblioteca usa en oscuro el
color claro y se vería una raya.

**D12. Se declara `ManageDataLauncherActivity`.** Desde septiembre de 2025 la
biblioteca activa esta actividad cada vez que arranca
(`setComponentEnabledSetting`), y Android lanza una excepción si se activa un
componente que no está en el manifest. Bubblewrap la declara por defecto.
Efectos visibles: el botón «Borrar datos» de los ajustes de la app pasa a ser
«Gestionar espacio» y abre los ajustes del sitio en Chrome, que es donde están
de verdad los datos; y al mantener pulsado el icono aparece un acceso «Site
Settings», en inglés porque el texto está fijo en la biblioteca. *Por
confirmar.*

**D13. Sin copia de seguridad y sin minificación.** `allowBackup="false"`: la
app no guarda datos del usuario, solo estado propio del móvil. La versión de
publicación no pasa por R8: así es el mismo código que el APK de depuración
que se prueba por cable, a cambio de unos megas.

**D14. Integración continua: dos workflows y ninguna acción de terceros.**
`ci.yml` en cada subida a una rama; `publicacion.yml` a mano o con una
etiqueta `v*`. Solo se usan `actions/checkout` y `actions/upload-artifact`,
las dos de GitHub. El JDK 17 y el SDK de Android ya están en la máquina
`ubuntu-24.04`; el JDK se elige con la variable que la propia máquina publica
(`JAVA_HOME_17_X64`), sin `setup-java`. Sin caché: la compilación baja Gradle y
las dependencias cada vez, que es más lento pero no hay nada que invalidar.

**D15. Firma.** Dos secretos y un alias fijo:

| Secreto | Contenido |
|---|---|
| `UPLOAD_KEYSTORE_BASE64` | el almacén de claves (PKCS12) en base64 |
| `UPLOAD_KEYSTORE_PASSWORD` | su contraseña |

El alias es siempre `upload`. En un almacén PKCS12 la contraseña de la clave
es la del almacén, así que no hace falta un tercer secreto. La firma la hace
Gradle con la configuración estándar de Android (`signingConfigs`), leyendo
variables de entorno; si faltan, el workflow se detiene en su primer paso.
Los pasos de firma están en un guion, `ci/construir-aab.sh`, y no dentro del
workflow, para poder ensayarlos con una clave desechable sin tener los
secretos de verdad.

**D16. Comprobación de almacenes de claves.** Un guion de shell,
`ci/comprobar-claves.sh`, que mira los ficheros que git tiene registrados:
falla por extensión (`.jks`, `.keystore`, `.p12`, `.pfx`…), por contenido (los
primeros bytes de un almacén JKS o PKCS12, aunque se haya renombrado) y por
texto (la cabecera de una clave privada PEM). Además, `.gitignore` impide
añadirlos por descuido. Mira el estado del repositorio en cada subida, no el
historial: un PKCS12 de más de 64 KB o cifrado de otra forma se le escaparía
si además no lleva una extensión conocida.

**D17. Comprobación de permisos.** `ci/comprobar-apk.sh` lee los permisos
del APK ya compilado y falla si aparece alguno que no esté en la lista. No
estaba en el encargo, pero «ningún permiso de más» depende de lo que cada
biblioteca añada por su cuenta al mezclar manifests, y eso cambia con cada
actualización. También es la forma en que yo mismo puedo comprobarlo, porque
no puedo compilar aquí.

### 1.3 Por confirmar

1. Android mínimo 7.0 (D5).
2. Dibujo del icono de los avisos (D10).
3. Imagen de arranque: el icono cuadrado a 128 dp (D10).
4. Color de la barra de navegación inferior igual al de la superior (D11).
5. «Gestionar espacio» y el acceso «Site Settings» en inglés (D12).
6. Importancia normal de los avisos (D7).
7. El permiso `REORDER_TASKS` (D6).
8. Todos los textos de `docs/TIENDA.md`.

### 1.4 Versiones fijadas

Comprobadas el 18-11-2026.

| Pieza | Versión | Fecha de la versión | Fuente |
|---|---|---|---|
| Nivel de API objetivo | 36 | exigido desde 31-08-2026 | <https://developer.android.com/google/play/requirements/target-sdk> (actualizada 28-10-2026) |
| Plugin de Android para Gradle | 9.5.1 | la 9.5.0 es de octubre de 2026 | <https://developer.android.com/build/releases/agp-9-5-0-release-notes> (actualizada 05-11-2026) |
| Gradle | 9.9.1 | 10-11-2026 | <https://services.gradle.org/versions/current> |
| JDK | 17 | — | misma página del plugin: mínimo 17, por defecto 17 |
| SDK Build Tools | 36.0.0 | — | misma página: mínimo y por defecto; no se fija, lo elige el plugin |
| android-browser-helper | 2.7.4 | 02-10-2026 | etiqueta `android-browser-helper-2.7.4` de <https://github.com/GoogleChrome/android-browser-helper> |
| Bubblewrap (solo evaluado) | 1.27.0 | 09-10-2026 | <https://registry.npmjs.org/@bubblewrap/cli> |
| `actions/checkout` | v7 (7.0.1) | — | etiquetas de <https://github.com/actions/checkout> |
| `actions/upload-artifact` | v7 (7.0.2) | — | etiquetas de <https://github.com/actions/upload-artifact> |
| Máquina de GitHub | `ubuntu-24.04` | imagen 20261111 | <https://github.com/actions/runner-images/blob/main/images/ubuntu/Ubuntu2404-Readme.md>: trae JDK 17.0.21, plataforma `android-36` y Build Tools 36.0.0 |

El plugin 9.5 pide Gradle 9.6.0 como mínimo y admite hasta el nivel de API 37.
La suma SHA-256 del `gradle-wrapper.jar` del repositorio coincide con la
oficial de Gradle 9.9.1
(`621008afc4f5d59357fcf06ffa644dd5aade5e091bdc363742710445f73cdaf8`).

### 1.5 Límites de la sesión en la que se ha hecho

- **No se puede compilar aquí.** El contenedor tiene bloqueado
  `dl.google.com`, de donde salen el SDK de Android y el plugin de Android para
  Gradle. La compilación solo se ha visto en GitHub Actions.
- **No se ha podido abrir la ayuda de Play** (`support.google.com`) ni la
  documentación de Chrome (`developer.chrome.com`) ni la de Cloudflare. Los
  datos que vienen de ahí están sacados de extractos de un buscador sobre esas
  mismas páginas, y así se indica donde aparecen.
- Sí se han leído directamente `developer.android.com`, el registro de npm,
  `services.gradle.org` y el código fuente de android-browser-helper,
  Bubblewrap, AndroidX y Chromium.

---

## 2. Entrega — versión 1.0.0 (18-11-2026)

### 2.1 Qué hay

Una rama, `claude/quirky-archimedes-21i6ml`, sin unir a `main` y sin *pull
request*. Contiene el proyecto Android, los dos workflows, tres guiones y la
documentación. La integración continua está en verde: compila el APK de
depuración con el nivel de API 36 y lo deja para descargar.

**Nadie ha instalado esta app en un móvil.** Ni yo, que no tengo cómo, ni
nadie más todavía. Todo lo que solo se ve en un móvil está sin probar (2.4).

### 2.2 Qué cambió respecto al diseño

| Diseño inicial | Lo que hay | Por qué |
|---|---|---|
| Un permiso | Dos: se añade `REORDER_TASKS`, y `FocusActivity` va exportada | Lo pide la documentación de la biblioteca para traer la app al frente al tocar un aviso (D6). *Por confirmar.* |
| La firma, en pasos del workflow | En un guion, `ci/construir-aab.sh` | Para poder ensayarla sin los secretos de verdad (D15). |
| `lint { textReport = true }` | Un paso de la CI que copia el informe al registro | Esa opción está obsoleta en el plugin 9.5. |
| `ci/comprobar-permisos.sh` | `ci/comprobar-apk.sh` | Además de los permisos enseña la ficha del APK. |

### 2.3 Qué se ha comprobado

En GitHub Actions, máquina `ubuntu-24.04`, sobre esta rama:

| Qué | Resultado |
|---|---|
| `./gradlew lint assembleDebug` con plugin 9.5.1, Gradle 9.9.1 y JDK 17 | Compila. Todas las ejecuciones del workflow «CI» en esta rama han terminado en verde, desde la primera. |
| Análisis estático | `0 errors, 7 warnings`. Los siete avisos están explicados en el README. |
| Ficha del APK, leída del propio fichero con `aapt2` | Paquete `es.proefic.iot`, versión 1.0.0 (código 1), Android mínimo 24, objetivo 36, nombre «Proefic IoT», portal `https://app.proefic.com/`. |
| Permisos del APK | `POST_NOTIFICATIONS`, `REORDER_TASKS` y el interno de AndroidX (`es.proefic.iot.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`). Ninguno más. |
| `asset_statements` dentro del APK | JSON correcto, con `https://app.proefic.com`. |
| Manifest final | A lo nuestro se suman dos actividades de la biblioteca para accesos directos, el arranque de AndroidX y la consulta de qué navegadores hay. Ningún permiso. |
| `ci/construir-aab.sh` con una clave desechable creada en la propia máquina (ejecución 44382714086, workflow temporal ya borrado) | Sin secretos se para sin construir. Con contraseña equivocada se para antes de compilar. Con una clave válida, `bundleRelease` compila, firma, y la huella leída del `.aab` coincide con la de la clave. |
| Qué pasa sin clave | `bundleRelease` deja un `.aab` sin firmar. Por eso el guion comprueba la firma. |
| Aviso de Gradle sobre funciones obsoletas (ejecución 44383300838) | Viene del plugin de Android, no de este repositorio. |

En el contenedor de la sesión:

| Qué | Resultado |
|---|---|
| `ci/comprobar-claves.sh` contra un repositorio de prueba | Detecta los seis casos (JKS y PKCS12 por extensión y renombrados, una clave PEM) y no señala una imagen, un texto ni un certificado público. |
| La orden de `keytool` de docs/PUBLICAR.md | Crea el almacén. El secreto se decodifica bien aunque se pegue con saltos de línea de Windows. |
| `gradle-wrapper.jar` | Su SHA-256 es el que publica Gradle para la 9.9.1. |
| Icono de los avisos | Mirado ampliado sobre fondo claro y oscuro. |
| Los tres PNG del portal | Copia idéntica, byte a byte. El repositorio del portal no se ha modificado. |

Las claves de estas pruebas eran desechables, se crearon en directorios
temporales y no están en el repositorio ni en la conversación.

### 2.4 Qué no se ha comprobado

- **Nada en un móvil.** Que abra sin barra, la pantalla de arranque, los
  colores, el recorte del icono, que llegue un aviso y cómo se ve, que al
  tocarlo se abra, los enlaces, la cámara, el arranque sin red, el botón atrás
  y el giro. Es la lista del paso 9 de docs/PUBLICAR.md.
- **El workflow `publicacion.yml` nunca se ha ejecutado.** Solo se puede
  lanzar desde `main` o con una etiqueta, y necesita los secretos. Sí se ha
  ejecutado su guion; del fichero del workflow solo sé que es YAML válido.
- **No se ha compilado en un ordenador**, solo en GitHub. El contenedor de la
  sesión no puede bajar el SDK de Android (`dl.google.com` bloqueado).
- **Si `REORDER_TASKS` hace falta**, y si no declarar
  `ManageDataLauncherActivity` falla de verdad. Las dos cosas salen de leer el
  código de la biblioteca, no de verlas ocurrir.
- **La orden de Chrome para ver el APK de depuración sin barra** (README).
- **Los datos de la consola de Play**: límites de texto, medidas de los
  gráficos, D-U-N-S, formularios. Vienen de extractos de un buscador sobre la
  ayuda de Play, que no pude abrir. Lo mismo la política *Bypass* de
  Cloudflare. Los nombres de los menús de la consola son orientativos.
- **El nombre definitivo**, `app.proefic.es`.

### 2.5 Por confirmar

Decisiones tomadas por lo más sencillo. Cada una se cambia en un sitio.

| # | Decisión | Dónde se cambia |
|---|---|---|
| 1 | Android mínimo 7.0 | `minSdk` en `app/build.gradle.kts` |
| 2 | Permiso `REORDER_TASKS` y `FocusActivity` exportada | Manifest. Si se quita, quitarlo también de la lista de `ci/comprobar-apk.sh` |
| 3 | Dibujo del icono de los avisos | `drawable-xxxhdpi/ic_notification_icon.png` |
| 4 | Imagen de arranque: el icono cuadrado, a 128 dp | `drawable-xxxhdpi/splash.png` |
| 5 | Barra de navegación inferior del color de la superior | Líneas `NAVIGATION_BAR_…` del manifest |
| 6 | «Gestionar espacio» y el acceso «Site Settings», en inglés | No se puede quitar sin escribir código |
| 7 | Avisos de importancia normal | Un `meta-data` en el servicio del manifest: `androidx.browser.trusted.USE_HIGH_PRI_NOTIFICATIONS` con valor `true` |
| 8 | Sin icono monocromo para los «iconos con tema» | Una capa `<monochrome>` en `ic_launcher.xml` |
| 9 | Todos los textos de la ficha | `docs/TIENDA.md` |

### 2.6 Lo que depende del portal

No se ha tocado el repositorio del portal. Tres cosas son suyas:

1. **Servir `/.well-known/assetlinks.json`** con la huella de la clave de
   firma (docs/PUBLICAR.md, paso 6), y dejarlo pasar sin sesión de Cloudflare
   Access (paso 7). Sin esto la app funciona, pero con barra de direcciones y
   sin que los enlaces la abran.
2. **El `badge` de los avisos.** `sw.js` llama a `showNotification` con
   `badge: '/icons/icon-192.png'`. En Android el *badge* es el icono pequeño
   del aviso y solo se usa su transparencia; esa imagen es opaca, así que se
   verá un cuadrado liso. Dentro de la app, además, impide que se use el icono
   de la app. Arreglo: quitar `badge`, o servir uno monocromo con fondo
   transparente.
3. **El título por defecto de un aviso** en `sw.js` es «Portal IoT». Solo se
   ve si el servidor envía un aviso sin título.

Una observación sobre el encargo: decía que la huella que escribe el workflow
«hace falta para el fichero de verificación del portal». La que hace falta es
la de la clave de **firma**, que solo está en la consola de Play; la del
workflow es la de la clave de **subida**. Está explicado en «Dos claves, dos
huellas», en docs/PUBLICAR.md.

### 2.7 Mapa de ficheros

Descrito fichero por fichero en el README. En corto:

```
app/build.gradle.kts                   portal, versión, niveles de API, firma
app/src/main/AndroidManifest.xml       permisos, arranque, enlaces, avisos
app/src/main/res/                      nombre, colores, iconos, imagen de arranque
build.gradle.kts                       versión del plugin de Android
settings.gradle.kts                    repositorios y módulos
gradle.properties                      memoria para Gradle
gradlew, gradlew.bat, gradle/wrapper/  Gradle 9.9.1
.github/workflows/ci.yml               en cada subida
.github/workflows/publicacion.yml      a mano o con etiqueta
ci/comprobar-claves.sh                 ningún almacén de claves
ci/comprobar-apk.sh                    ficha del APK y permisos
ci/construir-aab.sh                    firma y huella
README.md, docs/, CAMBIOS.md           documentación
.gitignore
```

### 2.8 Versiones

Las de la tabla 1.4. No ha cambiado ninguna. La compilación en GitHub confirma
que el plugin 9.5.1 y android-browser-helper 2.7.4 existen en el repositorio
de Google y funcionan juntos con Gradle 9.9.1.

### 2.9 Lo que le toca al dueño, por orden

1. **Pedir ya el número D-U-N-S**, si no lo tiene. Es lo que más tarda.
2. **Leer la lista «por confirmar»** (2.5) y decir qué se cambia.
3. **Instalar el APK de depuración** en un móvil por cable (README). Se verá
   con barra, pero ya se ven el icono, la pantalla de arranque y los colores.
4. **Unir la rama a `main`** cuando esté conforme. Hasta entonces el workflow
   de publicación no se puede lanzar a mano.
5. **Seguir docs/PUBLICAR.md** del paso 1 al 10: cuenta de Play, app, clave de
   subida, secretos, etiqueta `v1.0.0`, prueba interna, huella al portal,
   Cloudflare, ficha y formularios, prueba en el móvil, producción.
6. **Pasar el punto 2.6** a quien mantiene el portal.
7. **Antes de producción**, cambiar `portalHost` a `app.proefic.es`: con
   Cloudflare Access delante los revisores de Google no pueden entrar.

Para una próxima sesión como esta: si el entorno permite `dl.google.com`, se
puede compilar dentro de la sesión en vez de esperar a GitHub.
