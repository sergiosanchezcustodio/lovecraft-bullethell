class_name AchievementData
extends Resource
## Logro (D-32, hito 2.14; data/achievements/*.tres): se cumple cuando una estadística de la
## partida guardada llega a `target` y da su recompensa una sola vez: dólares, un personaje o
## un compañero (D-30, D-31: algunos se desbloquean jugando, además de en la tienda).

@export var id := &"cazador_100"
@export var display_name := "Cazador"
@export_multiline var description := ""
@export var order := 0
## Estadística que mira (ver Achievements.value): kills, runs, levels_won, elites, chests,
## crises, revives, coop_runs, best_level, best_time, money, characters, maxed_weapons, flawless.
@export var stat := "kills"
@export var target := 100
@export_group("Recompensa")
@export var reward_money := 0
@export var reward_character := &""
@export var reward_pet := &""
@export_group("Imagen")
@export var icon: Texture2D
@export var icon_model := ""                    ## o un modelo en models/ para renderizarla
@export var icon_mode := "full"                 ## "head" (retrato) o "full"
