class_name TitleScreenConfig
extends Resource
## Ajustes de la pantalla de título (data/title/portada.tres). Cada efecto tiene su
## interruptor y sus parámetros, y se puede cambiar o quitar sin tocar los demás.
## Posiciones en fracciones de la ilustración (0..1); tiempos en segundos.

@export_group("Velas y luces")
@export var candles_enabled := true
@export var flicker_strength := 0.22         ## variación de brillo de las llamas (±)
@export var flicker_speed := 1.0
@export var flame_wobble := 0.0009           ## bailoteo de la forma de la llama (UV)
@export var spill_strength := 0.045          ## variación de la luz que proyectan en paredes y suelo (±)

@export_group("Niebla")
@export var fog_enabled := true
@export var fog_strength := 0.9
@export var fog_speed := 0.012               ## deriva horizontal
@export var fog_color := Color(0.30, 0.45, 1.0)

@export_group("Nubes del ventanal")
@export var clouds_enabled := true
@export var clouds_strength := 0.22
@export var clouds_speed := 0.006
@export var clouds_color := Color(0.55, 0.70, 1.0)

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
@export var zoom_time := 7.5                 ## dura la presentación y se detiene
@export var zoom_center := Vector2(0.58, 0.42)

@export_group("Motas de polvo")
@export var dust_enabled := true
@export var dust_amount := 60
@export var dust_area := Rect2(0.03, 0.42, 0.40, 0.36)   ## junto a las velas de la izquierda

@export_group("Título")
@export var title_enabled := true
@export var fade_in_time := 2.0              ## fundido desde negro al empezar
@export var title_delay := 4.2               ## cuándo empieza a aparecer
@export var title_reveal_time := 2.4
@export var title_center := Vector2(0.505, 0.385)
@export var title_width := 0.37              ## fracción del ancho de pantalla
@export var halo_enabled := true
@export var halo_radius := 16.0              ## px de la imagen original (≈7 px en pantalla a 1080p)
@export var halo_strength := 1.0
@export var halo_color := Color(0.70, 0.80, 0.98, 0.85)

@export_group("Aviso de pulsar")
@export var prompt_enabled := true
@export var prompt_delay := 7.0
@export var prompt_text := "Pulsa Intro o A"
@export var prompt_y := 0.9
