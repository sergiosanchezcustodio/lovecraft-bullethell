extends GutTest
## Hito 19.9: informe de errores tras un cierre de golpe.

const DIR := "user://test_informe"

func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(CrashReport.MARK))

func after_each() -> void:
	for f in DirAccess.get_files_at(DIR): DirAccess.remove_absolute(DIR.path_join(f))
	DirAccess.remove_absolute(DIR)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(CrashReport.MARK))
	CrashReport.dismiss()

func test_sin_marca_no_hay_nada_que_ofrecer() -> void:
	CrashReport.start(get_tree(), false)
	assert_false(CrashReport.pending())

func test_la_marca_que_queda_es_un_cierre_de_golpe() -> void:
	var f := FileAccess.open(CrashReport.MARK, FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": "0.9.0", "started": "ayer", "where": "p3_n2"}))
	f.close()
	CrashReport.start(get_tree(), false)
	assert_true(CrashReport.pending())
	assert_true("p3_n2" in CrashReport.info_text(), "el informe dice dónde iba")
	CrashReport.dismiss()
	assert_false(CrashReport.pending(), "se pregunta una vez")

func test_el_registro_anterior_es_el_rotado_mas_nuevo() -> void:
	for n in ["godot.log", "godot2026-11-10T10.00.00.log"]:
		var f := FileAccess.open(DIR.path_join(n), FileAccess.WRITE)
		f.store_string(n)
		f.close()
	assert_eq(CrashReport.previous_log(DIR).get_file(), "godot2026-11-10T10.00.00.log", "el de ahora no")

func test_guarda_un_zip_con_el_equipo() -> void:
	var path := CrashReport.save(ProjectSettings.globalize_path(DIR))
	assert_true(path.ends_with(".zip") and FileAccess.file_exists(path))
	var z := ZIPReader.new()
	assert_eq(z.open(path), OK)
	assert_true("equipo.txt" in z.get_files())
	assert_true("Sistema:" in z.read_file("equipo.txt").get_string_from_utf8())
	z.close()

func test_lleva_los_registros_de_red_de_aquella_vez() -> void:
	var f := FileAccess.open(DIR.path_join("red_2026-11-11_10-00-00.log"), FileAccess.WRITE)
	f.store_string("Anfitrión")
	f.close()
	FileAccess.open(DIR.path_join("otra_cosa.txt"), FileAccess.WRITE).store_string("x")
	CrashReport._pending = {"t": int(Time.get_unix_time_from_system()) - 60}
	assert_eq(CrashReport.net_logs(DIR).size(), 1, "el de esa sesión, solo los red_*.log")
	CrashReport._pending = {"t": int(Time.get_unix_time_from_system()) + 3600}
	assert_eq(CrashReport.net_logs(DIR).size(), 0, "los de antes de arrancar, no")
	CrashReport._pending = {"version": "?"}
	assert_eq(CrashReport.net_logs(DIR).size(), 0, "sin hora en la marca, ninguno")
