class_name ShopItem
extends Resource
## Artículo de la tienda que no es un personaje ni un compañero (data/shop/*.tres): los
## potenciadores permanentes (varios niveles) y las mejoras de huecos (un solo nivel).
## Los personajes y los compañeros llevan su precio en sus propios datos (Shop los reúne).

enum Section { POWERUP, CHARACTER, PET, UPGRADE }

@export var id := &"vitalidad"
@export var display_name := "Vitalidad"
@export_multiline var description := ""
@export var section := Section.POWERUP
@export var order := 0                          ## orden dentro de su sección
## Precio de cada nivel (el tamaño es el número de niveles).
@export var prices: Array[int] = [150, 300, 600, 1000, 1500]
## Efecto por nivel: `stat` sube `per_level` (multiplicador: 0,04 = +4 %; huecos: +1).
@export var stat := "health"
@export var per_level := 0.04

func max_level() -> int:
	return prices.size()
