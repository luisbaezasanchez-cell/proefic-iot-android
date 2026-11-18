# Ficha de Google Play — borrador

**Todo lo de este fichero está «por confirmar».** Son propuestas para que el
dueño las corrija y las pegue en la consola de Play (docs/PUBLICAR.md, paso 8).

> **Sobre los límites y las medidas.** No se pudo abrir la ayuda de Google
> Play desde donde se escribió esto. Los datos vienen de extractos de un
> buscador, el 18-11-2026, sobre estas dos páginas de la ayuda:
>
> - «Create and set up your app»:
>   <https://support.google.com/googleplay/android-developer/answer/9859152>
> - «Add preview assets to showcase your app»:
>   <https://support.google.com/googleplay/android-developer/answer/9866151>
>
> Hay que contrastarlos con esas páginas o con la propia consola, que avisa si
> un texto se pasa o una imagen no cumple.

## Textos

### Título — máximo 30 caracteres

```
Proefic IoT
```

11 caracteres.

### Descripción corta — máximo 80 caracteres

```
Estado, histórico y avisos de tus sensores Proefic, en el móvil.
```

64 caracteres. Es lo primero que se lee en la ficha.

### Descripción completa — máximo 4000 caracteres

```
Proefic IoT es la app del portal de dispositivos de Proefic. Con ella consultas desde el móvil el estado de tus sensores, su histórico y los avisos que generan.

QUÉ PUEDES HACER
• Ver el estado de cada uno de tus sensores.
• Consultar el histórico de sus medidas.
• Recibir un aviso en el móvil cuando un sensor lo requiere.
• Dar de alta un dispositivo nuevo escaneando el código QR de su etiqueta.
• Compartir tus dispositivos con otras cuentas mediante una invitación.

PARA QUIÉN ES
Para clientes de Proefic con dispositivos instalados. Hace falta una cuenta del portal para entrar.

CÓMO FUNCIONA
La app muestra el portal de Proefic IoT a pantalla completa, así que siempre tienes la última versión sin actualizar nada. Necesita Google Chrome, u otro navegador compatible, instalado en el móvil.

Proefic es una marca de Syntagma Technology.
```

847 caracteres. La ayuda de Play pide no repetir en ella la
descripción corta.

Los títulos de sección van en mayúsculas porque la ficha no admite negritas ni
otro formato.

### Otros campos que pide la ficha

| Campo | Propuesta |
|---|---|
| Categoría | Por decidir. «Herramientas» o «Empresa» son las que encajan. |
| Correo de contacto | Un buzón de la empresa que alguien lea. Es obligatorio y público. |
| Sitio web | El de Proefic. |
| Política de privacidad | Una dirección pública. Sin ella no se puede publicar. |

## Gráficos

| Gráfico | Obligatorio | Medidas | Formato |
|---|---|---|---|
| Icono de la app | Sí | 512 × 512 px | PNG de 32 bits (con canal alfa), 1024 KB como máximo |
| Gráfico de funciones | Sí | 1024 × 500 px | JPEG o PNG de 24 bits (sin alfa) |
| Capturas de teléfono | Sí, 2 como mínimo | Cada lado entre 320 y 3840 px. El lado largo no puede ser más del doble del corto | JPEG o PNG de 24 bits (sin alfa) |
| Capturas de tableta de 7 y 10 pulgadas | No, recomendadas | Las mismas reglas | Los mismos |
| Vídeo | No | — | Una dirección de YouTube |

### De dónde sacar cada uno

**Icono.** `icon-512.png` del portal tiene la medida justa. Dos cosas que
mirar: está guardado sin canal alfa y Play lo pide con él, así que quizá haya
que volver a exportarlo; y Play redondea las esquinas por su cuenta, por lo
que tiene que seguir siendo un cuadrado entero, sin esquinas recortadas.

**Gráfico de funciones.** No existe. Es la imagen apaisada que encabeza la
ficha. Lo más sencillo: el indicador del icono y el nombre «Proefic IoT»
sobre el azul `#256ABF`.

**Capturas.** El repositorio del portal ya genera capturas
(`pwa/dev/capturas.mjs`, en `docs/capturas`). Las de móvil miden 780 px de
ancho pero son de página entera, y muchas pasan de 1560 px de alto: superan la
proporción de 2 a 1 que admite Play. Hay que recortarlas o volver a hacerlas a
la altura de una pantalla (por ejemplo, 780 × 1560). Propuesta de pantallas:
el estado de los dispositivos, la ficha de uno con su histórico, los avisos y
el alta con el QR.

Las capturas tienen que enseñar la app tal como es. No pueden llevar precios,
posiciones en listas ni reclamos del tipo «la mejor».
