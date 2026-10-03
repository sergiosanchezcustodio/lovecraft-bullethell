extends SceneTree
## Tabla de las reglas de daño (DamageRules): daño por segundo actual, el que le toca y desvío.
## godot --headless --path . -s tools/reglas_dano.gd            # solo la tabla
## godot --headless --path . -s tools/reglas_dano.gd -- aplicar  # ajusta damage, zone_dps y curse_dps

func _init() -> void:
	var apply := "aplicar" in OS.get_cmdline_user_args()
	print("%-16s %7s %7s %6s  %s" % ["arma", "actual", "toca", "desvío", "rasgos"])
	for w in DamageRules.all_weapons():
		if w.support or w.evolved:
			print("%-16s (%s: fuera de las reglas)" % [w.id, "evolución" if w.evolved else "apoyo"]); continue
		var now := DamageRules.dps(w)
		var want := DamageRules.target_dps(w)
		var tr := []
		for k in DamageRules.traits(w): tr.append(DamageRules.traits(w)[k][0])
		print("%-16s %7.1f %7.1f %+5.0f%%  %s" % [w.id, now, want, (now / want - 1.0) * 100.0, ", ".join(tr)])
		if apply and absf(now / want - 1.0) > 0.02:
			var k := want / now
			_scale(w.resource_path, k)
	quit()

## Cambia en el texto del .tres solo las líneas de daño, para no reescribir el fichero entero.
func _scale(path: String, k: float) -> void:
	var lines := FileAccess.get_file_as_string(path).split("\n")
	for i in lines.size():
		for key in ["damage", "zone_dps", "curse_dps"]:
			if lines[i].begins_with(key + " = "):
				var v := float(lines[i].substr(key.length() + 3))
				lines[i] = "%s = %s" % [key, str(snappedf(v * k, 0.1))]
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("\n".join(lines))
