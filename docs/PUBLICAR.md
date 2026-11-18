# Publicar Proefic IoT en Google Play

Los pasos, en orden, desde cero hasta producción. Cada paso dice **quién** lo
hace:

- **Repositorio**: ya está hecho o lo hace GitHub Actions solo.
- **Dueño**: la persona que administra la cuenta de Google Play. Nadie más
  puede hacerlo.
- **Portal**: quien mantiene el portal web (otro repositorio).
- **Cloudflare**: quien administra Cloudflare Access.

| # | Paso | Quién |
|---|---|---|
| 1 | Pedir el número D-U-N-S y crear la cuenta de empresa | Dueño |
| 2 | Crear la app en la consola | Dueño |
| 3 | Generar la clave de subida | Dueño |
| 4 | Cargar los secretos en GitHub | Dueño |
| 5 | Subir el primer paquete a la prueba interna | Repositorio lo construye, Dueño lo sube |
| 6 | Dar al portal la huella de la clave de firma | Dueño la copia, Portal la publica |
| 7 | Dejar pasar el fichero de verificación sin sesión | Cloudflare |
| 8 | Rellenar la ficha y los formularios | Dueño |
| 9 | Probar en el móvil | Dueño |
| 10 | Pasar a producción | Dueño |

Los pasos 1 y 8 son los lentos. Se pueden empezar ya, en paralelo con el resto.

> **Sobre los datos de la consola de Play.** Al escribir esto no se pudo abrir
> la ayuda de Google Play, solo extractos de un buscador sobre esas páginas.
> Los nombres de los menús y las cifras pueden haber cambiado: donde este
> documento y la consola no coincidan, vale la consola.

## Dos claves, dos huellas

Conviene tenerlo claro antes de empezar, porque es lo que más confunde.

| | Clave de **subida** | Clave de **firma** |
|---|---|---|
| Quién la tiene | El dueño, en su ordenador y como secreto en GitHub | Google. Nadie más la ve |
| Para qué sirve | Demostrar a Play que el paquete lo envía el dueño | Firmar lo que se instala en los móviles |
| Si se pierde | Se pide otra a Play | No se puede perder |
| Dónde se ve su huella | En el registro del workflow «Publicación» | En la consola de Play |

Play recibe el paquete firmado con la clave de subida, la comprueba, la quita
y vuelve a firmar con la suya. Por eso **la huella que tiene que publicar el
portal es la de la clave de firma**, la de la consola (paso 6), y no la que
escribe el workflow.

La huella que escribe el workflow sirve para dos cosas: comprobar que la clave
registrada en Play es la misma que hay en GitHub, y, si se quiere, añadirla
también al fichero del portal para poder probar un paquete antes de subirlo.

---

## 1. D-U-N-S y cuenta de empresa — Dueño

1. **Pedir el número D-U-N-S** de Syntagma Technology a Dun & Bradstreet. Es
   un identificador de empresa. Según la ayuda de Play: es obligatorio para
   una cuenta de organización, pedirlo es gratis y puede tardar 30 días o más.
   Hay intermediarios que cobran por tramitarlo; no hacen falta.
2. **Crear la cuenta de desarrollador** en <https://play.google.com/console>,
   de tipo **organización**. Pide el D-U-N-S, un correo y un teléfono que se
   verifican, y una cuota de registro que se paga una sola vez.
3. Esperar a que Google verifique la organización.

El requisito de «12 probadores durante 14 días» antes de poder publicar, del
que se habla mucho, es para las cuentas **personales** nuevas: la página de la
ayuda de Play que lo describe solo trata de esas.

## 2. Crear la app — Dueño

En la consola, **Crear aplicación**:

- Nombre: `Proefic IoT`
- Idioma predeterminado: español (España)
- Tipo: aplicación, gratuita

El paquete (`es.proefic.iot`) no se escribe aquí: Play lo lee del primer
paquete que se sube, en el paso 5, y desde entonces no se puede cambiar.

Al crear la primera versión, la consola pregunta por la **firma de
aplicaciones de Play**. Hay que **aceptarla** con la opción por defecto: que
Google genere y guarde la clave de firma.

## 3. Generar la clave de subida — Dueño

En el ordenador del dueño, **fuera de la carpeta del repositorio**. Hace falta
`keytool`, que viene con cualquier JDK y con Android Studio.

```bash
keytool -genkeypair -v -keystore proefic-iot-upload.p12 -storetype PKCS12 -alias upload -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Proefic IoT, O=Syntagma Technology, C=ES"
```

Pide una contraseña dos veces. Hay que inventarla en ese momento, larga, y no
usarla para nada más.

Qué significa cada parte:

| Parte | Significado |
|---|---|
| `-keystore proefic-iot-upload.p12` | El fichero que se crea: el *almacén de claves*. |
| `-storetype PKCS12` | El formato del almacén. Con este formato hay una sola contraseña. |
| `-alias upload` | El nombre de la clave dentro del almacén. Tiene que ser `upload`: es el que busca el workflow. |
| `-keyalg RSA -keysize 2048` | El tipo de clave. Es el que pide Android. |
| `-validity 10000` | Días de validez, unos 27 años. Android recomienda al menos 25. |
| `-dname "…"` | Los datos del titular. Son informativos. |

Es la orden de la documentación de Android
(<https://developer.android.com/build/building-cmdline#sign_cmdline>) con el
nombre del fichero, el alias y el formato ya puestos.

**Guardar el fichero `.p12` y la contraseña** en el gestor de contraseñas de
la empresa, y una segunda copia en otro sitio. No van al repositorio, ni a un
correo, ni a un chat.

Para ver la huella de la clave recién creada:

```bash
keytool -list -v -keystore proefic-iot-upload.p12 -alias upload
```

La línea `SHA256:` es la que tendrá que coincidir con la que escriba el
workflow.

### Si se pierde la clave

No es grave: con la firma de aplicaciones de Play, la clave de subida se puede
cambiar. En la consola, en la página de firma de la aplicación, hay una opción
para **solicitar el cambio de la clave de subida**. Se genera una clave nueva
con la orden de arriba, se le envía a Google su certificado y, cuando lo
aprueban, se actualizan los dos secretos de GitHub.

Lo mismo hay que hacer si la clave **se ha subido al repositorio por error**:
borrar el fichero no basta, porque sigue en el historial de git. Hay que darla
por perdida.

## 4. Cargar los secretos en GitHub — Dueño

El workflow necesita dos secretos:

| Nombre | Contenido |
|---|---|
| `UPLOAD_KEYSTORE_BASE64` | El fichero `.p12`, convertido a texto (base64). |
| `UPLOAD_KEYSTORE_PASSWORD` | La contraseña del paso 3. |

**Convertir el fichero a texto**, en la carpeta donde está el `.p12`:

- Linux:

  ```bash
  base64 -w 0 proefic-iot-upload.p12 > upload.b64
  ```

- macOS:

  ```bash
  base64 -i proefic-iot-upload.p12 -o upload.b64
  ```

- Windows (PowerShell):

  ```powershell
  [Convert]::ToBase64String([IO.File]::ReadAllBytes("proefic-iot-upload.p12")) | Set-Content upload.b64
  ```

**Cargarlos**: en GitHub, en el repositorio, **Settings > Secrets and
variables > Actions > New repository secret**. Uno por cada nombre. En el
primero se pega el contenido entero de `upload.b64`.

Después, **borrar `upload.b64`**.

Un secreto no se puede volver a leer desde GitHub, ni siquiera por quien lo
cargó: solo sustituir. GitHub lo tacha si aparece en un registro.

Si falta alguno de los dos, el workflow de publicación se para en su primer
paso, dice cuál falta y no construye nada.

## 5. Primer paquete a la prueba interna — Repositorio y Dueño

**Construir el paquete.** El workflow «Publicación» tiene que estar en la rama
`main`. Con la rama de trabajo ya unida a `main`:

```bash
git checkout main
git pull
git tag v1.0.0
git push origin v1.0.0
```

Subir la etiqueta lanza el workflow. También se puede lanzar a mano: pestaña
**Actions > Publicación > Run workflow**.

Cuando termina, en la página de la ejecución:

- el resumen muestra la **huella SHA-256 del certificado de subida**. Tiene
  que ser la misma que salió en el paso 3;
- en **Artifacts** está `app-release.aab`. Ese es el paquete.

**Subirlo.** En la consola, en la sección de pruebas, **Prueba interna >
Crear nueva versión**, subir `app-release.aab`, poner unas notas de la versión
y publicar en la prueba interna.

**Añadir probadores.** En la misma página, crear una lista con las cuentas de
Google de quienes vayan a probar y enviarles el enlace de participación. La
app se instala desde Google Play con ese enlace.

A partir de aquí la app instalada viene firmada por Google, con la clave de
firma. Hasta completar los pasos 6 y 7 **se verá con barra de direcciones**:
es lo esperado.

## 6. La huella de la clave de firma — Dueño y Portal

**Dueño.** En la consola, en la página de **firma de la aplicación** (dentro
de la configuración de la versión; en inglés, *Release > Setup > App
signing*), apartado **Certificado de la clave de firma de la aplicación**,
copiar la **huella digital SHA-256**. Según la documentación de Android, en
esa misma página la consola ofrece ya montado el fichero que hay que publicar
(«Digital Asset Links JSON»).

No es un secreto. Se le pasa a quien mantiene el portal.

**Portal.** Servir en `https://app.proefic.com/.well-known/assetlinks.json`:

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "es.proefic.iot",
      "sha256_cert_fingerprints": [
        "HUELLA_DE_LA_CLAVE_DE_FIRMA"
      ]
    }
  }
]
```

La huella va tal como la da la consola: 32 pares de caracteres separados por
dos puntos. La lista admite varias; se puede añadir, separada por una coma, la
de la clave de subida.

Condiciones que pone Android para ese fichero
(<https://developer.android.com/training/app-links/configure-assetlinks>):

- se sirve por HTTPS;
- con el tipo de contenido `application/json`;
- **sin redirecciones** (ni 301 ni 302);
- accesible para cualquiera, sin sesión. De ahí el paso 7.

Cuando el portal pase a `app.proefic.es`, ese nombre tiene que servir el mismo
fichero.

## 7. Dejar pasar el fichero sin sesión — Cloudflare

Con Cloudflare Access delante, una petición sin sesión recibe una redirección
a la pantalla de entrada. Ni Chrome ni Android pueden iniciar sesión, así que
para ellos el fichero no existe.

A quien administra Cloudflare Access hay que pedirle:

> Que `https://app.proefic.com/.well-known/assetlinks.json` responda sin
> sesión de Access. Solo esa ruta. El resto del sitio sigue protegido.

La forma documentada por Cloudflare es crear una aplicación de Access aparte
para esa ruta exacta, con una política de tipo **Bypass** para todo el mundo.
Cloudflare advierte de que *Bypass* desactiva todos los controles en lo que
cubre, así que tiene que cubrir esa ruta y nada más.

**Cómo comprobarlo**, desde cualquier ordenador, sin haber iniciado sesión:

```bash
curl -i https://app.proefic.com/.well-known/assetlinks.json
```

Tiene que responder `HTTP/2 200`, con `content-type: application/json` y el
JSON del paso 6. Si responde `302` con una dirección de
`cloudflareaccess.com`, sigue protegido.

## 8. Ficha y formularios — Dueño

Todo esto se rellena en la consola. Play no deja publicar en producción hasta
que esté completo. Los borradores de los textos y la lista de gráficos están
en [TIENDA.md](TIENDA.md).

| Qué | Qué hay que tener preparado |
|---|---|
| **Ficha de la tienda** | Título, descripción corta y completa, icono, gráfico de funciones y capturas. Ver TIENDA.md. |
| **Política de privacidad** | Una dirección web pública con la política de privacidad del portal. |
| **Acceso a la app** | La app pide iniciar sesión, así que hay que dar a los revisores de Google **una cuenta de prueba**: usuario, contraseña e instrucciones. Tiene que funcionar sin más pasos. Ver la advertencia de abajo. |
| **Seguridad de los datos** | Un cuestionario sobre qué datos recoge la app, para qué y si se comparten. La app es el portal: hay que declarar lo que recoge el portal (cuenta, datos de los dispositivos, avisos). El envoltorio no añade nada: no lleva publicidad ni analítica. |
| **Borrado de cuenta** | Dentro del cuestionario anterior. Si desde la app se puede **crear** una cuenta, Play exige una forma de borrarla dentro de la app **y** una dirección web donde pedirlo. Si las cuentas las crea Proefic y el usuario no puede registrarse solo, se marca que la app no permite crear cuentas. |
| **Clasificación de contenido** | Un cuestionario sobre el contenido (violencia, etc.). Para una herramienta como esta, todo es «no». |
| **Público objetivo** | A qué edades va dirigida. No es una app para niños. |
| **Anuncios** | Declarar que no tiene. |

> **Los revisores y Cloudflare Access.** Mientras la app apunte a
> `app.proefic.com`, quien la abra se encuentra primero con la pantalla de
> Cloudflare Access. Un revisor de Google no puede pasarla con una cuenta de
> prueba del portal. La documentación de Android lo dice así: no se debe
> publicar una app cuyas direcciones no sean accesibles al público. **Antes de
> enviar a producción, la app tiene que apuntar al nombre definitivo**, sin
> Access delante (paso 10).

## 9. Probar en el móvil — Dueño

Con la app instalada **desde Google Play** por el enlace de la prueba interna
(no el APK de depuración), y los pasos 6 y 7 hechos.

Nadie ha instalado todavía esta app en un móvil. Esta lista es la primera
prueba real.

**Arranque**

- [ ] La app se instala y **abre sin barra de direcciones**. Si se ve la
      barra, el fichero del paso 6 no está bien servido, la huella no es la de
      la clave de firma, o falta el paso 7.
- [ ] Con Cloudflare Access delante, **su pantalla de entrada se ve con
      barra**, porque es de otro nombre. Al entrar, la barra desaparece.
- [ ] Los **colores de arranque** son los del tema: fondo `#F1F0EC` con el
      móvil en claro y `#111110` en oscuro. Durante un instante se ve el icono
      centrado.
- [ ] La barra de arriba y la de navegación de abajo son `#FCFCFB` en claro y
      `#1A1A19` en oscuro.

**Sesión**

- [ ] **La sesión se conserva** al cerrar la app (quitarla de recientes) y
      volver a abrirla.

**Avisos**

- [ ] Al activar los avisos en el portal, el diálogo de permiso de Android
      dice **«Proefic IoT»**, no «Chrome».
- [ ] **Llega un aviso push** con el **nombre de la app**.
- [ ] El **icono** del aviso es el indicador de Proefic. Si sale un cuadrado
      liso, es lo que se explica en CAMBIOS.md: el portal envía su propio
      `badge` y hay que quitarlo en el portal.
- [ ] **Al tocar el aviso se abre el dispositivo.** Probarlo dos veces: con la
      app cerrada y con la app abierta por detrás.

**Cámara**

- [ ] **El lector de QR del alta funciona.** El permiso de cámara lo pide
      Chrome. Si Chrome no tiene permiso de cámara en ese móvil, lo pide
      Android para Chrome.

**Enlaces**

- [ ] **Escanear el QR de una etiqueta** con la cámara del móvil **abre la
      app**, en la pantalla de alta de ese dispositivo.
- [ ] **Un enlace de invitación** (por ejemplo, recibido por correo o
      mensaje) **abre la app**.

  Si se abren en el navegador, Android no ha verificado el nombre. Con el
  móvil conectado por cable se puede ver:

  ```bash
  adb shell pm get-app-links es.proefic.iot
  ```

  Tiene que decir `app.proefic.com: verified`.

**Sin red**

- [ ] En modo avión, **la app abre** y muestra lo que el portal tenga
      previsto para ese caso. La primera vez que se abre la app tiene que
      haber red.

**Comportamiento de app**

- [ ] El **botón atrás** recorre las pantallas del portal y, desde la
      primera, sale de la app.
- [ ] Al **girar el móvil**, la pantalla gira y no se pierde lo que se estaba
      viendo.
- [ ] En **recientes** aparece una sola tarjeta, con el nombre y el icono de
      la app.

**Por confirmar** (decisiones tomadas por lo más sencillo; ver CAMBIOS.md)

- [ ] El icono de la app se ve bien recortado en el lanzador del móvil.
- [ ] La imagen de arranque, el icono de los avisos y el color de la barra
      inferior son aceptables.
- [ ] Al mantener pulsado el icono aparece un acceso «Site Settings», en
      inglés. Decidir si se acepta.

Si algo falla, anotar el modelo del móvil, la versión de Android y la de
Chrome.

## 10. Pasar a producción — Dueño

1. **Cambiar al nombre definitivo**, cuando `app.proefic.es` funcione y sirva
   su `assetlinks.json` sin sesión. En `app/build.gradle.kts`:

   ```kotlin
   val portalHost = "app.proefic.es"
   val versionNumero = 2
   ```

   No hay que tocar nada más. Subir el cambio, crear la etiqueta nueva y subir
   el paquete a la prueba interna, como en el paso 5.

   Para quien ya tenía la app, es un sitio nuevo: tendrá que iniciar sesión y
   aceptar los avisos otra vez.
2. **Repetir la prueba del paso 9** con ese paquete.
3. Comprobar que el paso 8 está completo y que la cuenta de prueba de los
   revisores funciona.
4. En la consola, **promover** la versión de la prueba interna a
   **producción** y enviarla a revisión. La primera revisión puede tardar
   varios días.

Las versiones siguientes son los cinco pasos de «Publicar una versión nueva»
del [README](../README.md).
