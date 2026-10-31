# Pantalla de título (`scenes/title.tscn`, `scripts/title/`)

Tus imágenes en `resources/PantallasMenus/`: `fondo_titulo_sin_texto_1080p_definitivo.png` (en realidad a 4K, con mipmaps activados en su `.import`) y `Texto_titulo.png`. `fondo_con_titulo_completo.png` es solo la referencia de composición.

- **Máscaras** (`tools/gen_mascaras_portada.py`: analiza la ilustración en 4K y escribe a 1920×1080; revisión en `shots/revision/2026-09-26/mascaras_revision.png`):
  - `mascara_velas.png`: R, llama de cada vela, cortada en el cuello de la mecha (sin cera); G, fase propia de cada vela, extendida a la zona que ilumina; B, cuánto baila cada punto (0 en la base, 1 en la punta, escalado por el tamaño de la llama; las lejanas y los reflejos no bailan).
  - `mascara_luces.png`: R, cristal de los farolillos; G, su halo; B, luz proyectada por las velas.
  - `mascara_zonas.png`: R, cielo claro del ventanal; G, niebla del suelo; B, cristal del ventanal.
  - `Texto_titulo_niebla.png`: el alfa del título difuminado, con el margen `TITLE_PAD` (0,14, el mismo que en `title_screen.gd`).
  - Los farolillos son una lista de posiciones revisada a mano (`LANTERNS` en el script).
  - **Si cambia la ilustración, vuelve a ejecutar el script y revisa esa lista.** Las posiciones de la luna y los ojos están en la configuración.
- **Capas** (todas en un "escenario" de 1920×1080 que cubre la pantalla conservando la proporción):
  - `background.gdshader`: velas que parpadean con fase propia, llama que baila desde la mecha y luz proyectada que oscila con ella; farolillos que respiran despacio (cristal y halo).
  - `floor_fog.gdshader`: bancos de niebla suaves que aclaran y oscurecen la niebla pintada (mezcla premultiplicada).
  - `window_sky.gdshader`: halo de la luna, relámpago y ojos.
  - Ceniza con tres `GPUParticles2D`: copos lejanos pequeños, medianos y unos pocos cercanos, grandes y desenfocados. Pasa **por delante del título**: va en su propio escenario (`ash_stage`), con el mismo encaje y acercamiento que la ilustración, pero dibujado después del título.
  - El título (`title_halo.gdshader`: niebla con su silueta, letras que se condensan, niebla que se deshace y halo fino) y el aviso van fuera del escenario, así que el acercamiento no les afecta.
- **Configuración por efecto** (`data/title/portada.tres`, `TitleScreenConfig`): cada efecto tiene su interruptor y sus parámetros. Son velas, farolillos, niebla, luna, relámpago, ojos, acercamiento, ceniza, título, halo, niebla del título, aviso y música.
  - Para compararlos sin tocar la configuración: `godot --path . -- title off=niebla,ceniza`. Nombres: velas, farolillos, niebla, luna, relampago, ojos, acercamiento, ceniza, titulo, halo, niebla_titulo, aviso y musica.
  - Otras opciones: `shots=`, `tag=`, `t=` (empezar en ese segundo), `strike=` (relámpago), `eyes=` (brillo de ojos) y `perf=`.
  - Para capturas de los menús, `open=` abre una ventana al terminar la presentación: `slots` (huecos), `slots_borrar` (con la confirmación de borrado), `menu` (menú principal), `menu_jugar` o `menu_config` con `tab=0..3`. Úsalo con `saves=demo_saves`, que tiene una partida de ejemplo en el hueco 2.
- **Controles:** cualquier botón principal (A, B, X, Y, Start, Select; Intro, Espacio o Esc) salta la presentación y, con "Pulsa Start" visible, abre la ventana de huecos. Al elegir hueco se abre el menú principal; "Jugar en local" entra en la partida hasta que exista la selección de personaje (hito 2.3).
- **Variación medida** (desviación típica en % del brillo): llamas 6,4 %, paredes iluminadas 4,4 %, cielo 2,3 %, niebla del suelo 20 % y resto por debajo del 1 %. Sutil a propósito. Coste: 0,42 ms por fotograma.
