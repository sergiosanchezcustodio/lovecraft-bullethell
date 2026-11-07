class_name SpikeLog
extends RefCounted
## Picos del 1 % peor (hito 16.1). Con `perf=N spikes=true`, apunta cada fotograma que pasa de
## `LIMIT` ms con lo que pasó en él: CPU y GPU del dibujo, pasos de física, nodos creados, compilaciones de pipelines (shaders que se compilan
## en mitad de la partida) y los sistemas de `Prof` que más subieron respecto a lo normal. (Los
## tiempos de proceso y física de `Performance` solo se actualizan una vez por segundo: no sirven.)
## Al final imprime el reparto («PICOS …») y los peores fotogramas («PICO …»).

const LIMIT := 16.7
const WORST := 12
const HITCH := 25.0                       ## tirón que se nota: más de 25 ms
## Tope de filas (07-11-2026): cada una pesa unos 9 KB; una medición colgada llegó a 13 GB. Con
## 120 000 (unos 20 min a 100 fps, ~1 GB) deja de apuntar y el informe lo dice.
const MAX_ROWS := 120000

var _vp: RID
var _prev_prof := {}
var _prev_nodes := 0
var _prev_pipes := 0
var _prev_phys_frames := 0
var _rows: Array[Dictionary] = []          ## un diccionario por fotograma medido
var _pipe_keys: Array[String] = []

## Marcas al principio y al final de las fases del fotograma (un nodo que va el primero y otro el
## último en _process y en _physics_process): así se sabe cuánto del fotograma es proceso, cuánto
## física (todos sus pasos) y cuánto lo demás. Cada fila se cierra al acabar el dibujo
## (`frame_post_draw`) y mide ese fotograma de punta a punta (06-11-2026: antes la fila de un
## fotograma llevaba la física del siguiente, y la de un tirón en la física salía como «otro»).
class PhaseMark extends Node:
	var first := true
	static var proc_us := 0                ## scripts de _process (de la primera marca a la última)
	static var proc_end := 0
	static var _proc_start := 0
	static var phys_us := 0                ## scripts de _physics_process, todos los pasos
	static var _phys_start := 0
	static var tail_us := 0                ## tras los scripts de cada paso: diferidas, borrados, servidor de física
	static var _phys_end := 0
	static var start_us := 0               ## de la señal del paso o del proceso a la primera marca
	static var _sig := 0
	static var pre_draw := 0
	static func on_pre_draw() -> void: pre_draw = Time.get_ticks_usec()
	static func on_frame_signal() -> void: _sig = Time.get_ticks_usec()
	static func _enter_step() -> void:
		var now := Time.get_ticks_usec()
		if _phys_end > 0: tail_us += now - _phys_end
		_phys_end = 0
		if _sig > 0: start_us += now - _sig
		_sig = 0
	static func reset() -> void:
		proc_us = 0; phys_us = 0; tail_us = 0; start_us = 0
	func _init(is_first: bool) -> void:
		first = is_first
		process_priority = -1000000 if is_first else 1000000
		process_physics_priority = -1000000 if is_first else 1000000
		process_mode = Node.PROCESS_MODE_ALWAYS
	func _process(_d: float) -> void:
		if first:
			_enter_step()
			_proc_start = Time.get_ticks_usec()
		else:
			proc_end = Time.get_ticks_usec()
			proc_us += proc_end - _proc_start
	func _physics_process(_d: float) -> void:
		if first:
			_enter_step()
			_phys_start = Time.get_ticks_usec()
		else:
			_phys_end = Time.get_ticks_usec()
			phys_us += _phys_end - _phys_start

var _marks: Array[PhaseMark] = []
var _born := {}                            ## nodos creados en este fotograma, por tipo
var _born_spikes := {}                     ## y sumados en los fotogramas de pico
var _born_all := {}

func _init(viewport: Viewport) -> void:
	_vp = viewport.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(_vp, true)
	for k in ["PIPELINE_COMPILATIONS_CANVAS", "PIPELINE_COMPILATIONS_MESH", "PIPELINE_COMPILATIONS_SURFACE",
			"PIPELINE_COMPILATIONS_DRAW", "PIPELINE_COMPILATIONS_SPECIALIZATION"]:
		if ClassDB.class_has_integer_constant("Performance", k): _pipe_keys.append(k)
	_prev_nodes = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	_prev_pipes = _pipes()
	_prev_phys_frames = Engine.get_physics_frames()
	viewport.get_tree().node_added.connect(_on_node_added)
	# «otro» por tramos (06-11-2026): tras el proceso y antes de dibujar (borrados y llamadas
	# diferidas), el dibujo, tras la física y el arranque de cada paso
	RenderingServer.frame_pre_draw.connect(PhaseMark.on_pre_draw)
	RenderingServer.frame_post_draw.connect(_close)
	viewport.get_tree().physics_frame.connect(PhaseMark.on_frame_signal)
	viewport.get_tree().process_frame.connect(PhaseMark.on_frame_signal)
	for f in [true, false]:
		var m := PhaseMark.new(f)
		_marks.append(m)
		viewport.get_tree().root.add_child.call_deferred(m)

## Tipo del nodo: el script si lo tiene (sin ruta), si no la clase y el nombre del padre.
func _on_node_added(n: Node) -> void:
	var s: Script = n.get_script()
	var k := s.resource_path.get_file().get_basename() if s != null and s.resource_path != "" else "%s<%s" % [n.get_class(), _owner_name(n.get_parent())]
	_born[k] = int(_born.get(k, 0)) + 1

var _pipe_by := {}                         ## compilaciones por tipo (lo que dice el monitor)

## El primer antepasado con nombre propio o con script (los «@Node3D@123» no dicen nada).
static func _owner_name(p: Node) -> String:
	var hops := 0
	while p != null and hops < 6:
		var sc: Script = p.get_script()
		if sc != null and sc.resource_path != "": return sc.resource_path.get_file().get_basename() + ("/" if hops else "")
		if not String(p.name).begins_with("@"): return String(p.name)
		p = p.get_parent()
		hops += 1
	return "?"

func _pipes() -> int:
	var n := 0
	for k in _pipe_keys:
		var v := int(Performance.get_monitor(ClassDB.class_get_integer_constant("Performance", k)))
		_pipe_by[k.trim_prefix("PIPELINE_COMPILATIONS_").to_lower()] = v
		n += v
	return n

var _active := false
var _last_close := 0

## Llamar en cada fotograma medido (tras el calentamiento): desde el primero, se apuntan.
func step(_delta: float) -> void:
	_active = true

## Al acabar el dibujo: la fila del fotograma que termina, de un final de dibujo al siguiente.
func _close() -> void:
	var now := Time.get_ticks_usec()
	var ms := (now - _last_close) / 1000.0
	var first := _last_close == 0 or not _active
	_last_close = now
	var proc_ms := PhaseMark.proc_us / 1000.0
	var phys_ms := PhaseMark.phys_us / 1000.0
	var tail_ms := PhaseMark.tail_us / 1000.0
	var start_ms := PhaseMark.start_us / 1000.0
	var tras := maxf(PhaseMark.pre_draw - PhaseMark.proc_end, 0) / 1000.0 if PhaseMark.proc_end > 0 else 0.0
	var dib := maxf(now - PhaseMark.pre_draw, 0) / 1000.0 if PhaseMark.pre_draw > 0 else 0.0
	PhaseMark.reset()
	var prof := {}
	for k: String in Prof.totals:
		prof[k] = (int(Prof.totals[k]) - int(_prev_prof.get(k, 0))) / 1000.0
	_prev_prof = Prof.totals.duplicate()
	var nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var before := _pipe_by.duplicate()
	var pipes := _pipes()
	var ptypes := {}                       # de qué tipo son las de este fotograma
	if pipes != _prev_pipes:
		for k: String in _pipe_by:
			var dv := int(_pipe_by[k]) - int(before.get(k, 0))
			if dv > 0: ptypes[k] = dv
	var phys := Engine.get_physics_frames()
	if _rows.size() >= MAX_ROWS: first = true             # lleno: ya no apunta
	if not first:
		var otro := maxf(ms - proc_ms - phys_ms, 0.0)
		_rows.append({
			"proceso": proc_ms,
			"fisica": phys_ms,
			"otro": otro,                                          # lo que no es de los scripts:
			"tras": tras,                                          # tras el proceso, antes de dibujar (diferidas, borrados)
			"dibujo": dib,                                         # dibujando (y presentando)
			"tras_fisica": tail_ms,                                # tras los scripts de cada paso de física
			"arranque": start_ms,                                  # de la señal de cada paso a sus scripts
			"resto": maxf(otro - tras - dib - tail_ms - start_ms, 0.0),
			"ms": ms,
			"t": Time.get_ticks_msec() / 1000.0,
			"cpu": RenderingServer.viewport_get_measured_render_time_cpu(_vp),
			"gpu": RenderingServer.viewport_get_measured_render_time_gpu(_vp),
			"pasos": phys - _prev_phys_frames,
			"nodos": nodes - _prev_nodes,
			"shaders": pipes - _prev_pipes,
			"ptypes": ptypes,
			"prof": prof})
		var spike := ms > LIMIT
		for k in _born:
			_born_all[k] = int(_born_all.get(k, 0)) + int(_born[k])
			if spike: _born_spikes[k] = int(_born_spikes.get(k, 0)) + int(_born[k])
		_rows[-1]["born"] = _born
	_born = {}
	_prev_nodes = nodes
	_prev_pipes = pipes
	_prev_phys_frames = phys

## Nodos que se ejecutan cada fotograma (_process o _physics_process), por script o clase.
func census(root: Node) -> String:
	var proc := {}
	var phys := {}
	var total := 0
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		total += 1
		var sc: Script = n.get_script()
		var k := sc.resource_path.get_file().get_basename() if sc != null and sc.resource_path != "" else n.get_class()
		if n.is_processing(): proc[k] = int(proc.get(k, 0)) + 1
		if n.is_physics_processing(): phys[k] = int(phys.get(k, 0)) + 1
		for c in n.get_children(): stack.append(c)
	return "NODOS %d en total | _process: %s | _physics_process: %s" % [total, _top(proc, 16), _top(phys, 10)]

## Resumen: cuántos picos, la media de cada medida en los picos frente a los demás y los peores.
func report() -> String:
	var spikes := _rows.filter(func(r: Dictionary) -> bool: return r.ms > LIMIT)
	var calm := _rows.filter(func(r: Dictionary) -> bool: return r.ms <= LIMIT)
	var out: PackedStringArray = []
	out.append("PICOS %d de %d fotogramas pasan de %.1f ms (shaders compilados en total: %d)" % [spikes.size(), _rows.size(), LIMIT,
		_rows.reduce(func(a: int, r: Dictionary) -> int: return a + int(r.shaders), 0)])
	if _rows.size() >= MAX_ROWS: out.append("PICOS ojo: tope de %d fotogramas; los de después no se apuntaron" % MAX_ROWS)
	var worst := 0.0
	for r in _rows: worst = maxf(worst, float(r.ms))
	var hitches := _rows.filter(func(r: Dictionary) -> bool: return r.ms > HITCH)
	out.append("PICOS tirones (más de %.0f ms): %d  peor: %.1f ms" % [HITCH, hitches.size(), worst])
	if not hitches.is_empty():                   # cuándo caen (07-11-2026: los peores no dicen si van juntos)
		var per := {}
		for r in hitches:
			var k := int(float(r.t) / 30.0) * 30
			per[k] = int(per.get(k, 0)) + 1
		var keys := per.keys()
		keys.sort()
		out.append("PICOS tirones por medio minuto (s desde el arranque: cuántos): " + "  ".join(keys.map(func(k: int) -> String: return "%d: %d" % [k, per[k]])))
	var comp := _rows.filter(func(r: Dictionary) -> bool: return int(r.shaders) > 0)
	if not comp.is_empty():
		var cl := "PICOS compilaciones (s desde el arranque: cuántas, ms del fotograma):"
		for r in comp: cl += "  %.2f: %d, %.1f" % [r.t, r.shaders, r.ms]
		out.append(cl)
		# qué tipo y qué entró en escena en esos fotogramas (para saber qué las dispara)
		var by_frame := "PICOS compilaciones, tipo y nodos nuevos:"
		for r in comp:
			var tps := PackedStringArray()
			for k: String in r.ptypes: tps.append("%s %d" % [k, r.ptypes[k]])
			by_frame += "
    %.2f %.1f ms [%s] %s" % [r.t, r.ms, ", ".join(tps), _top(r.born, 5)]
		out.append(by_frame)
		out.append("PICOS compilaciones por tipo (desde el arranque): " + str(_pipe_by))
	if spikes.is_empty(): return "\n".join(out)
	var line := "PICOS media en picos / resto:"
	for k in ["ms", "proceso", "fisica", "otro", "tras", "dibujo", "tras_fisica", "arranque", "resto", "cpu", "gpu", "pasos", "nodos", "shaders"]:
		line += "  %s=%.2f/%.2f" % [k, _avg(spikes, k), _avg(calm, k)]
	out.append(line)
	# los sistemas de Prof que más suben en los picos
	var keys := {}
	for r in _rows:
		for k in r.prof: keys[k] = true
	var rise: Array = []
	for k: String in keys:
		rise.append([k, _avg_prof(spikes, k), _avg_prof(calm, k)])
	rise.sort_custom(func(a: Array, b: Array) -> bool: return a[1] - a[2] > b[1] - b[2])
	var sys := "PICOS sistemas (en picos / resto, ms):"
	for i in mini(8, rise.size()): sys += "  %s=%.2f/%.2f" % [rise[i][0], rise[i][1], rise[i][2]]
	out.append(sys)
	out.append("PICOS nodos creados en los picos: " + _top(_born_spikes, 14))
	out.append("PICOS nodos creados en total: " + _top(_born_all, 14))
	spikes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.ms > b.ms)
	for i in mini(WORST, spikes.size()):
		var r: Dictionary = spikes[i]
		var top: Array = r.prof.keys()
		top.sort_custom(func(a: String, b: String) -> bool: return r.prof[a] > r.prof[b])
		var tops := ""
		for j in mini(3, top.size()): tops += " %s=%.1f" % [top[j], r.prof[top[j]]]
		out.append("PICO %.1f ms  t=%.2f proceso=%.1f fisica=%.1f otro=%.1f (tras %.1f, dibujo %.1f, tras la física %.1f, arranque %.1f, resto %.1f) cpu=%.1f gpu=%.1f pasos=%d nodos=%+d shaders=%d |%s | %s" % [r.ms, r.t,
			r.proceso, r.fisica, r.otro, r.tras, r.dibujo, r.tras_fisica, r.arranque, r.resto, r.cpu, r.gpu, r.pasos, r.nodos, r.shaders, tops, _top(r.get("born", {}), 5)])
	return "\n".join(out)

static func _top(d: Dictionary, n: int) -> String:
	var ks := d.keys()
	ks.sort_custom(func(a: String, b: String) -> bool: return d[a] > d[b])
	var parts: PackedStringArray = []
	for i in mini(n, ks.size()): parts.append("%s=%d" % [ks[i], d[ks[i]]])
	return " ".join(parts)

static func _avg(rows: Array, k: String) -> float:
	if rows.is_empty(): return 0.0
	var s := 0.0
	for r in rows: s += float(r[k])
	return s / rows.size()

static func _avg_prof(rows: Array, k: String) -> float:
	if rows.is_empty(): return 0.0
	var s := 0.0
	for r in rows: s += float(r.prof.get(k, 0.0))
	return s / rows.size()
