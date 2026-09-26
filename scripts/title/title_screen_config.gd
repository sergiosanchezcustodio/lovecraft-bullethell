class_name TitleScreenConfig
extends Resource
## Ajustes de la pantalla de título (data/title/portada.tres). Cada efecto tiene su
## interruptor y sus parámetros, y se puede cambiar o quitar sin tocar los demás.
## Posiciones en fracciones de la ilustración (0..1); tiempos en segundos.

@export_group("Velas")
@export var candles_enabled := true
@export var flicker_strength := 0.22         ## variación de brillo de las llamas (±)
@export var flicker_speed := 1.0
@export var flame_sway := 2.5                ## px (a 1080p) que baila la punta de la llama mayor; la base no se mueve
@export var spill_strength := 0.045          ## variación de la luz que proyectan en paredes y suelo (±)

@export_group("Farolillos")
@export var lanterns_enabled := true         ## no se mueven: su cristal y su halo respiran despacio
@export var lantern_breath := 0.06           ## variación de brillo del cristal (±)
@export var lantern_halo := 0.10             ## intensidad del halo
@export var lantern_period := 5.0            ## s de una respiración
@export var lantern_color := Color(1.0, 0.62, 0.28)

@export_group("Niebla del suelo")
@export var fog_enabled := true
@export var fog_strength := 1.0
@export var fog_speed := 1.0                 ## deriva de los bancos de niebla (1 = unos 30 px/s en primer plano)
@export var fog_color := Color(0.30, 0.45, 1.0)

@export_group("Halo de la luna")
@export var moon_enabled := true
@export var moon_pos := Vector2(0.6242, 0.1528)
@export var moon_radius := 0.0275            ## en fracción del ancho
@export var moon_halo_strength := 0.3
@export var moon_halo_period := 7.0          ## s de una respiración completa
@export var moon_color := Color(0.55, 0.75, 1.0)

@export_group("Relámpago en el ventanal")
@export var lightning_enabled := true
@export var lightning_min_interval := 9.0
@export var lightning_max_interval := 16.0
@export var lightning_strength := 0.55       ## tenue a propósito (accesibilidad)

@export_group("Ojos de Cthulhu")
@export var eyes_enabled := true
@export var eye_left := Vector2(0.6151, 0.1898)
@export var eye_right := Vector2(0.6294, 0.1898)
@export var eyes_strength := 0.9
@export var eyes_period := 9.0               ## s entre un brillo y el siguiente
@export var eyes_color := Color(0.85, 1.0, 0.75)

@export_group("Acercamiento lento")
@export var zoom_enabled := true
@export var zoom_amount := 0.03              ## 3 %
@export var zoom_time := 8.5                 ## dura la presentación y se detiene
@export var zoom_center := Vector2(0.58, 0.42)

@export_group("Ceniza")
@export var ash_enabled := true
@export var ash_amount := 280                ## copos lejanos, pequeños (3-6 px)
@export var ash_mid_amount := 90             ## copos medianos (6-13 px)
@export var ash_near_amount := 26            ## copos cercanos, grandes y desenfocados (16-42 px)
@export var ash_speed := 24.0                ## px/s de caída
@export var ash_alpha := 0.7
@export var ash_color := Color(0.86, 0.83, 0.79)

@export_group("Título")
@export var title_enabled := true
@export var fade_in_time := 2.0              ## fundido desde negro al empezar
@export var title_delay := 3.2               ## cuándo empieza a aparecer
@export var title_reveal_time := 5.0         ## niebla con su silueta, letras y niebla que se deshace
@export var title_center := Vector2(0.505, 0.385)
@export var title_width := 0.37              ## fracción del ancho de pantalla
@export var halo_enabled := true
@export var halo_radius := 16.0              ## px de la imagen original (≈7 px en pantalla a 1080p)
@export var halo_strength := 1.0
@export var halo_color := Color(0.70, 0.80, 0.98, 0.85)
@export var title_fog_enabled := true        ## entrada desde una niebla con la silueta del título
@export var title_fog_color := Color(0.66, 0.74, 0.90, 0.6)

@export_group("Aviso de pulsar")
@export var prompt_enabled := true
@export var prompt_delay := 8.6
@export var prompt_text := "Pulsa Intro o A"
@export var prompt_y := 0.9

@export_group("Música")
@export var music_enabled := true
@export var music := "res://resources/Music/Musica_Intro.mp3"
@export var music_fade_in := 2.0
