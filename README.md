# renova2-historias

Historias misioneras trilingües para la app **Missionary Stories - OneVoice27**: español, inglés y portugués, con los videos de Renova2 TV.

La app descarga estas historias desde GitHub Pages:
`https://klerenac.github.io/renova2-historias/index.json`

## Cómo agregar una historia

1. Copia `plantilla.json` dentro de `historias/` y renómbralo con el id de la historia, por ejemplo `historias/2026_T4_W05.json`.
2. Llena los campos:

| Campo | Qué va |
|---|---|
| `id` | `AAAA_T#_W##`: año, trimestre (1–4) y semana. Debe ser igual al nombre del archivo. |
| `fecha` | Día en que aparece en la app (`AAAA-MM-DD`). Antes de esa fecha queda oculta. Vacío = se muestra ya. |
| `tituloEs/En/Pt` | Título en cada idioma. |
| `resumenEs/En/Pt` | Una o dos frases para la ficha de la historia. |
| `youtubeIdEs/En/Pt` | Solo el ID del video (11 caracteres, lo que va después de `youtu.be/`). Vacío = "video aún no disponible". |
| `textoEs/En/Pt` | El relato. Separa los párrafos con `\n\n`. |

3. Sube el cambio (commit + push). En 1–2 minutos queda publicado y las apps lo reciben al abrirse.

## Corregir algo

Edita el archivo de la historia y súbelo. La app detecta qué historias cambiaron y descarga solo esas.

## Seguridad contra errores

Antes de publicar, `tool/build.dart` revisa todas las historias (JSON válido, id y nombre de archivo, IDs de YouTube, fechas). Si encuentra un error, **no publica nada** y la app sigue mostrando la versión anterior. El detalle del error aparece en la pestaña **Actions** del repositorio.

Para revisar en tu PC antes de subir:

```
dart tool/build.dart
```
