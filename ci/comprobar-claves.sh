#!/usr/bin/env bash
#
# Falla si en el repositorio hay un almacén de claves o una clave privada.
#
# La clave de subida a Google Play no se guarda aquí nunca: vive fuera del
# repositorio y llega a GitHub Actions como secreto (docs/PUBLICAR.md). Este
# guion es la red de seguridad por si alguien la añade por error.
#
# Mira los ficheros que git tiene registrados y los detecta de tres maneras:
#   1. por la extensión del nombre;
#   2. por los primeros bytes, que delatan un almacén JKS o PKCS12 aunque se
#      haya renombrado;
#   3. por la cabecera de texto de una clave privada en formato PEM.
#
# Uso, desde la raíz del repositorio:   ci/comprobar-claves.sh
#
# Si salta: borrar el fichero NO basta. Lo que se ha subido sigue en el
# historial de git, así que la clave hay que darla por perdida y pedir a
# Google Play que la cambie (docs/PUBLICAR.md, «Si se pierde la clave»).

set -euo pipefail

encontrados=()

while IFS= read -r -d '' fichero; do
    # Registrado en git pero borrado en esta copia: nada que mirar.
    [ -f "$fichero" ] || continue

    # 1. Extensión, sin distinguir mayúsculas.
    case "${fichero,,}" in
        *.jks | *.keystore | *.p12 | *.pfx | *.bks | *.pem | *.key | *.b64)
            encontrados+=("$fichero  (por la extensión)")
            continue
            ;;
    esac

    # 2. Primeros bytes, en hexadecimal.
    cabecera=$(head -c 8 "$fichero" | od -An -tx1 | tr -d ' \n')
    case "$cabecera" in
        feedfeed* | cececece*)
            # Números mágicos de los formatos JKS y JCEKS de Java.
            encontrados+=("$fichero  (es un almacén de claves Java)")
            continue
            ;;
        308?????020103* | 3080020103*)
            # Un PKCS12 empieza con una secuencia ASN.1 (30 8x) cuya primera
            # pieza es el número de versión 3 (02 01 03).
            encontrados+=("$fichero  (es un almacén de claves PKCS12)")
            continue
            ;;
    esac

    # 3. Clave privada en texto.
    if grep -q -e '-----BEGIN [A-Z ]*PRIVATE KEY-----' "$fichero"; then
        encontrados+=("$fichero  (contiene una clave privada)")
    fi
done < <(git ls-files -z)

if [ "${#encontrados[@]}" -gt 0 ]; then
    echo "ERROR: hay claves en el repositorio:" >&2
    printf '  %s\n' "${encontrados[@]}" >&2
    echo >&2
    echo "Quita esos ficheros. Si alguno era la clave de subida, quitarlo no basta:" >&2
    echo "mira «Si se pierde la clave» en docs/PUBLICAR.md." >&2
    exit 1
fi

echo "Sin almacenes de claves ni claves privadas en el repositorio."
