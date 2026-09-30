class_name UpgradeData
extends Resource
## Mejora pasiva (data/upgrades/*.tres): modifica una estadística del personaje en cada
## nivel. Las armas nuevas y las subidas de arma salen de WeaponData.

@export var id := &"velocidad"
@export var display_name := "Botas de nieve"
@export var description := "+8 % de velocidad"
@export var stat := "move_speed"           ## propiedad de CharacterData que cambia
@export var multiply := 1.0                ## factor por nivel (1 = no multiplica)
@export var add := 0.0                     ## suma por nivel
@export var max_level := 5
@export var heal := false                  ## al subir la vida o la cordura máximas, rellena lo ganado
@export var color := Color(0.8, 0.8, 0.8)  ## color del icono en el menú
@export var icon: Texture2D                 ## imagen en la subida de nivel

## Aplica un nivel de la mejora a los datos (copia propia) de un personaje.
func apply(p: Player) -> void:
	var before: float = p.data.get(stat)
	var after := before * multiply + add
	p.data.set(stat, after)
	if heal:
		if stat == "max_health": p.health += after - before
		elif stat == "max_sanity": p.sanity += after - before
