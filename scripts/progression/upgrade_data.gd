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
## Otros efectos por nivel con la sintaxis de WeaponData.level_mods: "estadística*" multiplica
## y "estadística+" suma, p. ej. {"knockback_mult*": 1.1} (Guantes de estibador).
@export var also := {}
@export_enum("ataque", "proteccion", "esquive", "utilidad", "disparador") var group := "utilidad"

## Aplica `lv` niveles del objeto sobre un diccionario de estadísticas (las que falten se
## leen de `base`). Lo usa Player.rebuild_stats.
func apply_levels(v: Dictionary, base: CharacterData, lv: int) -> void:
	if stat != "":
		if not v.has(stat): v[stat] = base.get(stat)
		for i in lv: v[stat] = v[stat] * multiply + add
	for key: String in also:
		var s := key.trim_suffix("*").trim_suffix("+")
		if not v.has(s): v[s] = base.get(s)
		for i in lv:
			if key.ends_with("*"): v[s] = v[s] * float(also[key])
			else: v[s] = v[s] + float(also[key])
