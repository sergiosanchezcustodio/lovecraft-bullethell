extends Node
## Prueba de verdad contra GitHub (hito 10.1): `godot --path . -- cloud_check cloud_token=<token>
## cloud_marker=lovecraft_prueba.json`. Busca o crea el gist del marcador, escribe un fichero, lo
## lee, lo borra y, con `cloud_delete=true`, borra el gist al acabar. Imprime cada paso y sale.

func _ready() -> void:
	var la := LaunchArgs.from_cmdline()
	var ok := await _run(la.get_bool("cloud_delete"))
	print("Nube: %s" % ("BIEN" if ok else "FALLO (%s)" % Cloud.error))
	get_tree().quit(0 if ok else 1)

func _run(delete_after: bool) -> bool:
	if not Cloud.connected():
		print("Nube: sin token (cloud_token=)")
		return false
	var who: String = await Cloud.gist.user_login()
	print("Nube: usuario %s, marcador %s" % [who, Cloud.gist.marker])
	if who == "": return false
	var t0 := Time.get_ticks_msec()
	var id: String = await Cloud.ensure_gist()
	print("Nube: gist %s (%d ms)" % [id, Time.get_ticks_msec() - t0])
	if id == "": return false
	var text := JSON.stringify({"prueba": Time.get_datetime_string_from_system(), "ñ": "¿Iä! Cthulhu fhtagn"})
	t0 = Time.get_ticks_msec()
	if not await Cloud.push({"prueba.json": text}): return false
	print("Nube: escrito (%d ms)" % (Time.get_ticks_msec() - t0))
	t0 = Time.get_ticks_msec()
	var files: Variant = await Cloud.fetch()
	print("Nube: leído %s (%d ms)" % [files.keys() if files is Dictionary else files, Time.get_ticks_msec() - t0])
	if files is not Dictionary or files.get("prueba.json") != text: return false
	if not await Cloud.push({"prueba.json": null}): return false
	files = await Cloud.fetch()
	if files is not Dictionary or files.has("prueba.json"): return false
	print("Nube: borrado el fichero")
	Cloud.gist_id = ""                               # en otro PC: lo encuentra por el marcador
	if await Cloud.ensure_gist() != id: return false
	print("Nube: encontrado otra vez por el marcador")
	if delete_after:
		if not await Cloud.gist.delete(id): return false
		Cloud.gist_id = ""
		Cloud.save_file()
		print("Nube: gist borrado")
	return true
