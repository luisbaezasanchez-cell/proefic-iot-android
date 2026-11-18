#!/usr/bin/env bash
#
# Enseña la ficha de un APK ya compilado (paquete, versión, niveles de API,
# nombre, portal al que apunta) y falla si pide algún permiso que no esté en
# la lista de abajo.
#
# Para qué: el manifest final de la app no es solo el nuestro. Al compilar,
# Android le suma el de cada biblioteca, y una biblioteca puede traer un
# permiso sin que nadie lo haya escrito aquí. Este guion mira el resultado.
#
# Uso:   ci/comprobar-apk.sh app/build/outputs/apk/debug/app-debug.apk
#
# Necesita el SDK de Android (variable ANDROID_HOME), que trae `aapt2`, la
# herramienta que sabe leer un APK.

set -euo pipefail

apk="${1:?Uso: ci/comprobar-apk.sh ruta/al/fichero.apk}"

# Permisos admitidos. Si hay que añadir uno, se añade aquí y se explica en el
# manifest por qué hace falta.
permitidos=(
    # Mostrar avisos. Declarado en nuestro manifest.
    android.permission.POST_NOTIFICATIONS
    # Traer la app al frente al tocar un aviso. Declarado en nuestro manifest.
    android.permission.REORDER_TASKS
    # Lo añade AndroidX por su cuenta. No da acceso a nada: es un permiso que
    # la app se concede a sí misma para que nadie más pueda enviarle ciertos
    # mensajes internos.
    es.proefic.iot.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION
)

# aapt2 está en las Build Tools del SDK; se usa la versión más reciente.
aapt2=$(find "${ANDROID_HOME:?Falta la variable ANDROID_HOME (ruta del SDK de Android)}/build-tools" -name aapt2 | sort -V | tail -n 1)
[ -n "$aapt2" ] || { echo "ERROR: no encuentro aapt2 en $ANDROID_HOME/build-tools" >&2; exit 1; }

ficha=$("$aapt2" dump badging "$apk")
manifest=$("$aapt2" dump xmltree "$apk" --file AndroidManifest.xml)

echo "Ficha de $apk"
echo "$ficha" | grep -E "^(package|sdkVersion|minSdkVersion|targetSdkVersion|application-label):" | sed 's/^/  /'
echo "$manifest" | grep -A 1 'trusted.DEFAULT_URL"' | sed -n 's/.*:value([^)]*)="\([^"]*\)".*/  portal: \1/p'

pedidos=$(echo "$ficha" | sed -n "s/^uses-permission[^:]*: name='\([^']*\)'.*/\1/p" | sort -u)

echo "Permisos que pide:"
echo "$pedidos" | sed 's/^/  /'

sobran=()
for permiso in $pedidos; do
    admitido=no
    for p in "${permitidos[@]}"; do
        [ "$permiso" = "$p" ] && admitido=si
    done
    [ "$admitido" = si ] || sobran+=("$permiso")
done

if [ "${#sobran[@]}" -gt 0 ]; then
    echo "ERROR: el APK pide permisos que no están en la lista de ci/comprobar-apk.sh:" >&2
    printf '  %s\n' "${sobran[@]}" >&2
    exit 1
fi

echo "Ningún permiso de más."
