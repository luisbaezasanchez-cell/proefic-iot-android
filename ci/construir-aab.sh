#!/usr/bin/env bash
#
# Construye el paquete de publicación (.aab) firmado con la clave de subida y
# escribe la huella SHA-256 del certificado con el que ha quedado firmado.
#
# Lo llama el workflow .github/workflows/publicacion.yml. La clave llega en
# dos variables de entorno, que el workflow rellena con los secretos:
#
#   UPLOAD_KEYSTORE_BASE64    el almacén de claves PKCS12, en base64
#   UPLOAD_KEYSTORE_PASSWORD  su contraseña
#
# El alias de la clave dentro del almacén es siempre "upload".
#
# Si algo no cuadra (falta una variable, la contraseña no abre el almacén, el
# paquete sale sin firmar) se para con un mensaje y no deja nada a medias.

set -euo pipefail

aab=app/build/outputs/bundle/release/app-release.aab

# Mensaje de error y fin. "::error::" hace que GitHub lo enseñe destacado.
fallo() {
    echo "::error::$1"
    exit 1
}

[ -n "${UPLOAD_KEYSTORE_BASE64:-}" ] || fallo "Falta UPLOAD_KEYSTORE_BASE64."
[ -n "${UPLOAD_KEYSTORE_PASSWORD:-}" ] || fallo "Falta UPLOAD_KEYSTORE_PASSWORD."

# 1. El secreto es texto; aquí vuelve a ser un fichero. Va a la carpeta
#    temporal de la máquina, fuera del repositorio. La máquina de GitHub se
#    destruye al terminar el trabajo.
almacen="${RUNNER_TEMP:-$(mktemp -d)}/upload.p12"
printf '%s' "$UPLOAD_KEYSTORE_BASE64" | base64 --decode --ignore-garbage > "$almacen" ||
    fallo "UPLOAD_KEYSTORE_BASE64 no es base64 válido. Vuelve a generarlo (docs/PUBLICAR.md, paso 4)."

# 2. Antes de compilar: ¿se abre con la contraseña y contiene la clave?
#    `-storepass:env` hace que keytool lea la contraseña de la variable, sin
#    que aparezca en la línea de órdenes.
if ! listado=$(keytool -list -keystore "$almacen" -storepass:env UPLOAD_KEYSTORE_PASSWORD -alias upload 2>&1); then
    echo "$listado"
    fallo "No se puede usar el almacén de claves: o UPLOAD_KEYSTORE_PASSWORD no es su contraseña, o UPLOAD_KEYSTORE_BASE64 no contiene un almacén válido, o no hay en él una clave con el alias 'upload'."
fi
huella_clave=$(echo "$listado" | sed -n 's/^Certificate fingerprint (SHA-256): //p')

# 3. Construir. La firma la hace Gradle con estas dos variables y la
#    contraseña (ver `signingConfigs` en app/build.gradle.kts).
export UPLOAD_KEYSTORE_FILE="$almacen"
rm -f "$aab"
./gradlew bundleRelease

# 4. Comprobar la firma leyéndola del propio .aab, no del almacén: así la
#    huella que se escribe es la del certificado con el que de verdad se firmó.
huella_aab=$(keytool -printcert -jarfile "$aab" | sed -n 's/^[[:space:]]*SHA256: //p' | head -n 1)
[ -n "$huella_aab" ] || fallo "El paquete ha salido sin firmar."
[ "$huella_aab" = "$huella_clave" ] ||
    fallo "El paquete está firmado con un certificado que no es el de la clave de subida."

echo
echo "Paquete: $aab"
echo "Firmado con la clave de subida."
echo "Huella SHA-256 del certificado de subida: $huella_aab"

# Lo mismo, en el resumen que GitHub enseña en la página de la ejecución.
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    {
        echo "### Paquete de publicación firmado"
        echo
        echo "Huella SHA-256 del certificado de **subida**:"
        echo
        echo "\`$huella_aab\`"
        echo
        echo "Es un dato público. Los móviles que instalan desde Google Play comprueban otra huella, la de la clave de **firma**, que se copia de la consola de Play (docs/PUBLICAR.md, paso 6)."
    } >> "$GITHUB_STEP_SUMMARY"
fi
