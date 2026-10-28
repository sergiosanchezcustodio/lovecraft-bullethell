class_name DamageNumbers
extends Node3D
## Números de daño (hito 11.2, 28-10-2026): cifra que salta encima del enemigo golpeado, sube y se
## desvanece. Los golpes seguidos al mismo enemigo (MERGE) se suman en la misma cifra, que vuelve
## a saltar, así que un lanzallamas o una quemadura no llenan la pantalla. Como mucho MAX a la
## vez: si no hay sitio, se reutiliza la más vieja; las etiquetas se reciclan. Se quitan en Configuración ("damage_numbers").

const LIFE := 0.8                              ## lo que dura una cifra (los últimos 0,3 s, desvaneciéndose)
const MERGE := 0.25                            ## s: golpes al mismo enemigo dentro de esto, a la misma cifra
const MAX := 40
const RISE := 0.9                              ## m que sube
const SIZE := 50                               ## tamaño de la fuente (la fuerte, ×1,35)
const NORMAL := Color(1.0, 0.95, 0.84)
const STRONG := Color(1.0, 0.7, 0.22)          ## golpe fuerte (mucha vida de golpe) o con bonificación
const DOT := Color(0.95, 0.62, 0.42)           ## daño continuo (quemaduras, ácido)
static var enabled := true                     ## lo pone Game con la configuración (set_mode)
static var strong_only := false                ## solo los golpes fuertes (dorados): partidas muy llenas

## Modo de la configuración (`damage_numbers`): 0 sin cifras, 1 solo los golpes fuertes, 2 todas.
## Las configuraciones de antes guardaban sí o no.
static func mode_of(v: Variant) -> int:
	if v is bool: return 2 if v else 0
	return clampi(int(v), 0, 2)

static func set_mode(v: Variant) -> void:
	var m := mode_of(v)
	enabled = m > 0
	strong_only = m == 1
static var _font: FontVariation

var _items: Array = []                         ## [Label3D, id del objetivo, total, edad, deriva x, origen, color, por escribir]
var _by_id := {}                               ## id del objetivo -> su cifra (para sumar sin buscar)
var _spare: Array[Label3D] = []                ## etiquetas ya usadas, para no crear otras

## Suma `amount` a la cifra de `target` (o abre otra) en `at`, el punto de encima del enemigo.
static func add(fx_parent: Node, target: Object, amount: float, at: Vector3, strong := false, dot := false) -> void:
	if not enabled or fx_parent == null or amount <= 0.0: return
	if strong_only and not strong: return
	var dn: DamageNumbers = fx_parent.get_meta("damage_numbers") if fx_parent.has_meta("damage_numbers") else null
	if dn == null or not is_instance_valid(dn):
		dn = DamageNumbers.new()
		dn.name = "DamageNumbers"
		dn.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		fx_parent.add_child(dn)
		fx_parent.set_meta("damage_numbers", dn)
	dn._add(target.get_instance_id() if target != null else 0, amount, at, strong, dot)

func _add(id: int, amount: float, at: Vector3, strong: bool, dot: bool) -> void:
	var col := STRONG if strong else (DOT if dot else NORMAL)
	var it: Array = _by_id.get(id, [])
	if not it.is_empty() and it[3] < MERGE:
		it[2] += amount
		it[3] = 0.0                                # vuelve a saltar
		if strong or it[6] == DOT: it[6] = col     # lo fuerte manda; lo continuo cede
		it[7] = true                               # se escribe una vez por fotograma (_process)
		return
	var item: Array
	if _items.size() >= MAX:
		item = _items.pop_front()                  # la más vieja
		if is_same(_by_id.get(item[1]), item): _by_id.erase(item[1])
	else:
		item = [_spare.pop_back() if not _spare.is_empty() else _label(), 0, 0.0, 0.0, 0.0, Vector3.ZERO, NORMAL, true]
	item[1] = id; item[2] = amount; item[3] = 0.0
	item[4] = randf_range(-0.25, 0.25)
	item[5] = at + Vector3(randf_range(-0.2, 0.2), randf_range(0.0, 0.2), randf_range(-0.2, 0.2))   # que no se monten dos vecinas
	item[6] = col
	item[7] = true
	_items.append(item)
	_by_id[id] = item

func _label() -> Label3D:
	if _font == null:
		var ts := TextServerManager.get_primary_interface()
		_font = FontVariation.new()
		_font.base_font = load(MenuKit.BODY_FONT_PATH) as FontFile
		_font.variation_opentype = {ts.name_to_tag("wght"): 780}
		_font.opentype_features = {ts.name_to_tag("lnum"): 1}
	var l := Label3D.new()
	l.font = _font
	l.font_size = SIZE
	l.outline_size = 14
	l.outline_modulate = Color(0.06, 0.03, 0.02, 1.0)
	l.pixel_size = 0.006
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.render_priority = 10
	l.outline_render_priority = 9
	l.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(l)
	return l

## Cambiar el texto, el tamaño o el color de un Label3D rehace su malla: solo cuando cambian,
## una vez por fotograma. El desvanecido va con `transparency`, que no la rehace.
func _text(it: Array) -> void:
	var l: Label3D = it[0]
	var v: float = it[2]
	var txt := str(maxi(roundi(v), 1)) if v < 10000.0 else "%.0fk" % (v / 1000.0)
	if l.text != txt: l.text = txt
	var fs := int(SIZE * (1.35 if it[6] == STRONG else (0.8 if it[6] == DOT else 1.0)))
	if l.font_size != fs: l.font_size = fs
	if l.modulate != it[6]: l.modulate = it[6]
	l.visible = true
	it[7] = false

func _process(delta: float) -> void:
	for i in range(_items.size() - 1, -1, -1):
		var it: Array = _items[i]
		it[3] += delta
		var t: float = it[3]
		var l: Label3D = it[0]
		if t >= LIFE:
			l.visible = false
			_items.remove_at(i)
			if is_same(_by_id.get(it[1]), it): _by_id.erase(it[1])
			_spare.append(l)
			continue
		if it[7]: _text(it)
		var k := t / LIFE
		var rise := RISE * (1.0 - pow(1.0 - k, 3.0))                 # sube deprisa y se frena
		l.position = it[5] + Vector3(it[4] * k, rise, 0.0)
		var pop := 1.0 + 0.6 * maxf(0.0, 1.0 - t / 0.12)              # salta grande y se asienta
		l.scale = Vector3.ONE * pop
		l.transparency = 1.0 - clampf((LIFE - t) / 0.3, 0.0, 1.0)

func count() -> int:
	return _items.size()
