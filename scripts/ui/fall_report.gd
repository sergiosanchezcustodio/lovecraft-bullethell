class_name FallReport
extends RefCounted
## Informe al caer (hito 13.1, fase 13): en la pantalla final, de cada jugador de este PC, quién le
## abatió, quién le quitó más vida y más cordura, por qué vía (balas, contacto, golpes…), su vida
## y su cordura del último minuto y los enemigos vivos a la vez; con la dificultad en uso. Sirve
## para calibrar (D-42): dice si te mata el número, el daño o la cordura. También se apunta en el
## registro de dificultad (`DifficultyMenu.LOG`) y en el de partidas (`RUNS`, para el historial).
## Los datos los apuntan `Player.recv_add` (origen y vía de cada golpe) y game.gd (cada segundo).

const RUNS := "user://logs/dificultad_partidas.jsonl"

## El registro de partidas; `dif_runs=res://…` lee otro (capturas del historial con datos de ejemplo).
static func runs_path() -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("dif_runs="): return a.substr(9)
	return RUNS
const HIST := 60                              ## s de vida y cordura que se dibujan
## Cómo se llama cada vía en el informe.
const VIAS := {"bala": "balas", "contacto": "contacto", "golpe": "golpes", "zona": "charcos",
	"peligro": "el escenario", "presencia": "presencia", "aura": "aura", "aliado": "un compañero", "otro": "otros"}
## Orígenes que no son enemigos.
const OTHERS := {"presencia": "La presencia de las criaturas", "angulo": "Los ángulos devoradores",
	"ola": "La ola", "paranoia": "La paranoia de un compañero", "otro": "Otros"}
const PHYS := Color(0.86, 0.26, 0.2)
const MIND := Color(0.66, 0.4, 0.98)

static var _names := {}

## Nombre de un enemigo (o de lo que hizo daño) por su id.
static func name_of(id: String) -> String:
	if OTHERS.has(id): return OTHERS[id]
	if _names.is_empty():
		var dir := DirAccess.open("res://data/enemies")
		if dir != null:
			for f in dir.get_files():
				var path := "res://data/enemies/" + f.trim_suffix(".remap")
				if not path.ends_with(".tres"): continue
				var d := load(path) as EnemyData
				if d != null: _names[String(d.id)] = d.display_name
	return String(_names.get(id, id.capitalize()))

static func via_name(via: String) -> String:
	return String(VIAS.get(via, via))

## Los datos de un jugador: `received_via` ("origen|vía" -> [vida, cordura]), sus caídas
## ([{t, hit}]), su vida y cordura por segundo (fracciones) y los vivos por segundo.
static func build(who: String, color: Color, received_via: Dictionary, falls: Array,
		hist: PackedVector2Array, alive: PackedInt32Array) -> Dictionary:
	var hp := 0.0
	var san := 0.0
	var by_via := {}
	var by_src := {}                          # origen -> {src, ph, me, vias: {vía: [vida, cordura]}}
	for key: String in received_via:
		var v: Array = received_via[key]
		var parts := key.split("|")
		var src := parts[0]
		var via := parts[1] if parts.size() > 1 else "otro"
		hp += float(v[0]); san += float(v[1])
		if not by_via.has(via): by_via[via] = [0.0, 0.0]
		by_via[via][0] += float(v[0]); by_via[via][1] += float(v[1])
		if not by_src.has(src): by_src[src] = {"src": src, "ph": 0.0, "me": 0.0, "vias": {}}
		var row: Dictionary = by_src[src]
		row.ph += float(v[0]); row.me += float(v[1])
		row.vias[via] = [float(v[0]), float(v[1])]
	var rows: Array = by_src.values()
	var top_hp := rows.filter(func(r: Dictionary) -> bool: return r.ph >= 0.5)
	top_hp.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.ph > b.ph)
	var top_san := rows.filter(func(r: Dictionary) -> bool: return r.me >= 0.5)
	top_san.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.me > b.me)
	var sum := 0
	var peak := 0
	for n in alive:
		sum += n
		peak = maxi(peak, n)
	var tail := hist.slice(maxi(hist.size() - HIST, 0))
	return {"who": who, "color": color, "hp": hp, "san": san, "by_via": by_via,
		"top_hp": top_hp.slice(0, 3), "top_san": top_san.slice(0, 2), "falls": falls,
		"hist": tail, "alive_avg": float(sum) / maxf(alive.size(), 1.0), "alive_max": peak}

static func _clock(t: float) -> String:
	return "%d:%02d" % [int(t) / 60, int(t) % 60]

## Las líneas de texto de un informe (las del panel y las del registro).
static func lines(r: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	var falls: Array = r.falls
	if falls.size() == 1:
		var h: Dictionary = falls[0].hit
		out.append("Te abatió %s (%s, %d) a los %s" % [name_of(String(h.get("src", "otro"))),
			via_name(String(h.get("via", "otro"))), roundi(float(h.get("ph", 0.0))), _clock(float(falls[0].t))])
	elif falls.size() > 1:
		var parts := PackedStringArray()
		for f: Dictionary in falls:
			var h: Dictionary = f.hit
			parts.append("%s %s (%s)" % [_clock(float(f.t)), name_of(String(h.get("src", "otro"))), via_name(String(h.get("via", "otro")))])
		out.append("Caídas: " + "  ·  ".join(parts))
	if r.hp >= 0.5:
		var parts := PackedStringArray()
		for row: Dictionary in r.top_hp: parts.append(_who(row, 0))
		out.append("Vida perdida %d:  %s" % [roundi(r.hp), "  ·  ".join(parts)])
		out.append("Por vía:  " + _shares(r.by_via, 0, r.hp))
	else:
		out.append("Sin daño a la vida")
	if r.san >= 0.5:
		var parts := PackedStringArray()
		for row: Dictionary in r.top_san: parts.append(_who(row, 1))
		out.append("Cordura perdida %d:  %s" % [roundi(r.san), "  ·  ".join(parts)])
	return out

## "Fragmento protoplásmico 36 (balas 24, contacto 12)": un origen con lo que quitó (k: 0 vida,
## 1 cordura) y por qué vías; con una sola, solo su nombre ("Pingüino albino ciego 87 (contacto)").
## Lo que no es un enemigo (la presencia, la ola…) va sin vía.
static func _who(row: Dictionary, k: int) -> String:
	var total := float(row.ph if k == 0 else row.me)
	var head := "%s %d" % [name_of(String(row.src)), roundi(total)]
	if OTHERS.has(String(row.src)) and String(row.src) != "otro": return head
	var vias: Dictionary = row.vias
	var keys := vias.keys().filter(func(v: String) -> bool: return float(vias[v][k]) >= 0.5)
	keys.sort_custom(func(a: String, b: String) -> bool: return vias[a][k] > vias[b][k])
	if keys.size() == 1: return "%s (%s)" % [head, via_name(keys[0])]
	var parts := PackedStringArray()
	for v: String in keys: parts.append("%s %d" % [via_name(v), roundi(float(vias[v][k]))])
	return "%s (%s)" % [head, ", ".join(parts)]

## "contacto 47 %  ·  golpes 26 %…" (de mayor a menor; lo que no llega al 5 %, fuera).
static func _shares(by_via: Dictionary, k: int, total: float) -> String:
	var keys := by_via.keys().filter(func(v: String) -> bool: return float(by_via[v][k]) / total >= 0.05)
	keys.sort_custom(func(a: String, b: String) -> bool: return by_via[a][k] > by_via[b][k])
	var parts := PackedStringArray()
	for v: String in keys: parts.append("%s %d %%" % [via_name(v), roundi(100.0 * by_via[v][k] / total)])
	return "  ·  ".join(parts)

## Lo común a todos: enemigos vivos y dificultad.
static func common_lines(reports: Array) -> PackedStringArray:
	var out := PackedStringArray()
	if not reports.is_empty():
		out.append("Enemigos vivos a la vez: %d de media, %d como mucho" % [roundi(float(reports[0].alive_avg)), int(reports[0].alive_max)])
	var g := Difficulty.general()
	out.append("Dificultad: %s" % (("%d en todo" % g) if g > 0 else Difficulty.describe()))
	return out

## El panel: un bloque por jugador (en dos columnas con tres o cuatro) y lo común debajo.
static func panel(reports: Array) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	MenuKit.heading(box, "Informe", 30, MenuKit.INK)
	var grid := GridContainer.new()
	grid.columns = 2 if reports.size() > 2 else 1
	grid.add_theme_constant_override("h_separation", 28)
	grid.add_theme_constant_override("v_separation", 14)
	box.add_child(grid)
	var w := 560.0 if grid.columns == 2 else 640.0
	for r: Dictionary in reports:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 3)
		col.custom_minimum_size.x = w
		if reports.size() > 1:
			col.add_child(UiKit.label(String(r.who), 19, r.color))
		for l in lines(r):
			var ll := UiKit.label(l, 17, UiKit.TEXT)
			ll.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			ll.custom_minimum_size.x = w
			col.add_child(ll)
		var g := Graph.new()
		g.hist = r.hist
		g.custom_minimum_size = Vector2(w, (64 if reports.size() > 2 else 84) + Graph.LEGEND)
		col.add_child(g)
		grid.add_child(col)
	for l in common_lines(reports):
		var ll := UiKit.label(l, 15, UiKit.TEXT_DIM)
		ll.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ll.custom_minimum_size.x = w
		box.add_child(ll)
	return box

## Vida (rojo) y cordura (violeta) del último minuto; la línea de puntos, la mitad.
class Graph extends Control:
	var hist := PackedVector2Array()

	const LEGEND := 20.0                      ## px de la leyenda, debajo

	func _draw() -> void:
		var s := Vector2(size.x, size.y - LEGEND)
		draw_rect(Rect2(Vector2.ZERO, s), Color(0, 0, 0, 0.28))
		for x in range(0, int(s.x), 8):
			draw_line(Vector2(x, s.y * 0.5), Vector2(x + 3, s.y * 0.5), Color(1, 1, 1, 0.14))
		var font := get_theme_default_font()
		var y := size.y - 4.0
		var x0 := 0.0
		for k in 2:                                    # "— vida  — cordura  ·  último minuto"
			var c := PHYS if k == 0 else MIND
			draw_line(Vector2(x0, y - 5), Vector2(x0 + 16, y - 5), c, 2.0)
			var word := "vida" if k == 0 else "cordura"
			draw_string(font, Vector2(x0 + 21, y), word, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.7))
			x0 += 21 + font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 18
		var span := "último minuto" if hist.size() >= HIST else "%d s" % hist.size()
		draw_string(font, Vector2(x0, y), "·  " + span, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.5))
		if hist.size() < 2: return
		for k in 2:
			var pts := PackedVector2Array()
			for i in hist.size():
				var x := s.x * float(i) / float(hist.size() - 1)
				var v := hist[i].x if k == 0 else hist[i].y
				pts.append(Vector2(x, 3.0 + (s.y - 6.0) * (1.0 - clampf(v, 0.0, 1.0))))
			draw_polyline(pts, PHYS if k == 0 else MIND, 2.0, true)

## Al registro de dificultad (texto) y al de partidas (una línea JSON por partida, para el
## historial del hito 13.2): resultado, nivel, minuto, características y lo principal de cada uno.
static func log_run(result: String, level_id: String, t: float, reports: Array) -> void:
	var stamp := Time.get_datetime_string_from_system(false, true)
	var text := PackedStringArray()
	var people: Array = []
	for r: Dictionary in reports:
		text.append("%s: %s" % [r.who, " / ".join(lines(r))])
		var fell := ""
		if not (r.falls as Array).is_empty():
			var h: Dictionary = (r.falls as Array).back().hit
			fell = "%s|%s" % [h.get("src", ""), h.get("via", "")]
		people.append({"who": r.who, "hp": roundi(r.hp), "san": roundi(r.san), "fell": fell})
	DifficultyMenu.append_log("%s · %s · %s · %s · %s · %s" % [stamp, level_id, _clock(t), result,
		Difficulty.describe(), " | ".join(text)])
	var rec := {"date": stamp, "level": level_id, "t": roundi(t), "result": result,
		"levels": Difficulty.levels(), "players": people}
	_append(runs_path(), JSON.stringify(rec))

static func _append(path: String, line: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.READ_WRITE) if FileAccess.file_exists(path) else FileAccess.open(path, FileAccess.WRITE)
	if f == null: return
	f.seek_end()
	f.store_line(line)
