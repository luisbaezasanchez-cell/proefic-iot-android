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

**D6. Permisos: uno solo, `POST_NOTIFICATIONS`.** Android 13 y posteriores lo
exigen para mostrar cualquier aviso. Sin ubicación, sin pagos, sin analítica:
no se añaden los módulos `locationdelegation` ni `billing` de la biblioteca.
No se declara `INTERNET`: quien navega es Chrome, no la app.

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

**D16. Comprobación de almacenes de claves.** Un guion de shell,
`ci/comprobar-claves.sh`, que mira los ficheros que git tiene registrados:
falla por extensión (`.jks`, `.keystore`, `.p12`, `.pfx`…), por contenido (la
cabecera de un almacén JKS) y por texto (`PRIVATE KEY`). Además, `.gitignore`
impide añadirlos por descuido.

**D17. Comprobación de permisos.** `ci/comprobar-permisos.sh` lee los permisos
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
7. Todos los textos de `docs/TIENDA.md`.

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

## 2. Entrega

*Pendiente: se escribe al terminar.*
