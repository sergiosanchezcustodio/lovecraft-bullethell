class_name WeatherData
extends Resource
## Clima de un nivel (D-33, data/weather/*.tres): solo estético, no afecta a nadie. Cada
## capa tiene su intensidad (0 = apagada):
## - precipitación: nieve, ceniza (con alguna brasa) o lluvia (con salpicaduras), que cae
##   empujada por el viento;
## - ventisca: nieve o polvo que corre a ras de suelo con las rachas;
## - niebla: bancos bajos que avanzan con el viento;
## - nubes: sus sombras cruzan el suelo;
## - rayos: destellos que iluminan la escena de golpe cada cierto tiempo.
## El viento tiene rumbo y fuerza, y rachas que lo refuerzan a ratos.

enum Precip { NONE, SNOW, ASH, RAIN }

@export var id := &"nevada"
@export var display_name := "Nevada"
@export_group("Viento")
@export var wind_dir := Vector2(1.0, 0.35)       ## rumbo en el suelo (x, z)
@export var wind := 1.5                         ## m/s de base
@export var gusts := 0.6                        ## cuánto refuerzan las rachas (0..1)
@export var gust_period := 7.0                  ## s aproximados entre rachas
@export_group("Precipitación")
@export var precip := Precip.SNOW
@export var precip_amount := 0.5                ## 0..1: densidad
@export var fall_speed := 1.4                   ## m/s hacia abajo
@export var flake_size := 0.05                  ## m
@export var precip_color := Color(0.92, 0.95, 1.0, 0.85)
@export_group("Ventisca")
@export var drift := 0.3                        ## 0..1: nieve que corre a ras de suelo
@export var drift_color := Color(0.9, 0.93, 0.98, 0.35)
@export_group("Niebla")
@export var mist := 0.3                         ## 0..1: opacidad de los bancos bajos
@export var mist_color := Color(0.62, 0.7, 0.8)
@export var fog_density := -1.0                 ## niebla general del entorno (-1: la de siempre)
@export_group("Nubes y rayos")
@export var clouds := 0.25                      ## 0..1: cuánto oscurecen sus sombras
@export var cloud_scale := 18.0                 ## m de tamaño de las nubes
@export var lightning_every := 0.0              ## s medios entre rayos (0: sin rayos)
@export var lightning_color := Color(0.75, 0.82, 1.0)

## Dirección del viento en 3D (normalizada, en el suelo).
func wind_vector() -> Vector3:
	var d := wind_dir.normalized() if wind_dir.length() > 0.001 else Vector2.RIGHT
	return Vector3(d.x, 0.0, d.y)

## Fuerza del viento en el instante t: la base más las rachas (suaves, sin azar, para que
## dos jugadores vean lo mismo y los tests sean repetibles).
func wind_at(t: float) -> float:
	var p := maxf(gust_period, 0.5)
	var g := sin(t * TAU / p) * 0.5 + 0.5
	g = g * g * g                                     # rachas cortas y marcadas
	g *= 0.75 + 0.25 * sin(t * TAU / (p * 2.7) + 1.3)
	return wind * (1.0 + gusts * 2.0 * g)
