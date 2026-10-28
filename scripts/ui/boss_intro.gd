class_name BossIntro
extends Node
## Entrada de los jefes (28-10-2026): cuando aparece el enemigo final del nivel (o el jefe que
## viene tras él), franjas negras de cine por arriba y por abajo, la cámara encuadra a la vez a
## los jugadores y al jefe (GameCamera.focus), el tiempo va un momento a cámara lenta y sale un
## rótulo con la frase del nivel y su nombre, del estilo del de los niveles (LevelCard).
## Todo en tiempo real. La cámara lenta, como HitStop: solo con la partida en marcha, nunca en
## red (cada PC iría a su ritmo) ni con el juego acelerado (simulaciones).

const SLOW := 0.3                ## ritmo de la cámara lenta
const SLOW_IN := 0.15            ## s (reales) hasta llegar a ella
const SLOW_HOLD := 1.0           ## s que se queda
const SLOW_OUT := 0.8            ## s para volver al ritmo normal
const FOCUS := 2.6               ## s que la cámara encuadra al jefe
const CARD_AT := 0.35
const CARD_HOLD := 2.7
const BAR := 0.085               ## alto de cada franja (fracción de la pantalla)
const BARS_OUT := 3.0            ## s hasta que se van las franjas

static var count := 0            ## entradas hechas (tests y registro)

var _t0 := 0
var _slow := false
var _set_scale := -1.0           ## el último ritmo puesto aquí (si otro lo cambia, no se toca)

## Lanza la entrada de `e`. `subtitle`: la frase del nivel («Algo acecha entre las tiendas…»).
static func play(parent: Node, camera: GameCamera, e: Enemy, subtitle: String) -> BossIntro:
	var b := BossIntro.new()
	b.name = "BossIntro"
	b.process_mode = Node.PROCESS_MODE_ALWAYS
	b._slow = HitStop.enabled and not GameSession.online and Engine.time_scale == 1.0
	parent.add_child(b)
	b._build(String(e.data.display_name), subtitle)
	if camera != null: camera.focus(e, FOCUS, _height(e))
	count += 1
	return b

func _ready() -> void:
	_t0 = Time.get_ticks_msec()

func _process(_delta: float) -> void:
	var t := (Time.get_ticks_msec() - _t0) / 1000.0
	if _slow: _time_scale(t)
	if t > BARS_OUT + 1.0: queue_free()

func _exit_tree() -> void:
	if _set_scale > 0.0 and is_equal_approx(Engine.time_scale, _set_scale): Engine.time_scale = 1.0

## Ritmo del juego en el instante t (s reales desde que empezó).
func _time_scale(t: float) -> void:
	var k := 1.0
	if t < SLOW_IN: k = lerpf(1.0, SLOW, Anims.ease(t / SLOW_IN))
	elif t < SLOW_IN + SLOW_HOLD: k = SLOW
	elif t < SLOW_IN + SLOW_HOLD + SLOW_OUT: k = lerpf(SLOW, 1.0, Anims.ease((t - SLOW_IN - SLOW_HOLD) / SLOW_OUT))
	if _set_scale > 0.0 and not is_equal_approx(Engine.time_scale, _set_scale):
		_slow = false                              # otro lo ha cambiado (pausa, depuración): se deja
		return
	if get_tree().paused: return
	Engine.time_scale = k
	_set_scale = k
	if k == 1.0: _slow = false

func _build(enemy_name: String, subtitle: String) -> void:
	# franjas, por debajo del HUD (capa 5)
	var bars := CanvasLayer.new()
	bars.layer = 4
	add_child(bars)
	for top in [true, false]:
		var r := ColorRect.new()
		r.color = Color(0.0, 0.0, 0.0, 0.92)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.anchor_left = 0.0
		r.anchor_right = 1.0
		r.anchor_top = 0.0 if top else 1.0
		r.anchor_bottom = 0.0 if top else 1.0
		bars.add_child(r)
		var h := get_viewport().get_visible_rect().size.y * BAR
		var side := "offset_bottom" if top else "offset_top"
		var tw := create_tween().set_ignore_time_scale(true)
		tw.tween_property(r, side, h if top else -h, 0.45).from(0.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_interval(BARS_OUT - 0.45)
		tw.tween_property(r, side, 0.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	# rótulo, por encima de todo, en el tercio de abajo
	var layer := CanvasLayer.new()
	layer.layer = 80
	add_child(layer)
	var box := VBoxContainer.new()
	box.anchor_left = 0.0
	box.anchor_right = 1.0
	box.anchor_top = 0.76
	box.anchor_bottom = 0.76
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(box)
	if subtitle != "":
		var s := MenuKit.title(subtitle, 26, Color(MenuKit.INK, 0.8))
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(s)
	var name_box := VBoxContainer.new()
	name_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(name_box)
	var h := MenuKit.heading(name_box, enemy_name, 60)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for n in h.get_parent().get_children():            # el separador, centrado bajo el nombre
		(n as Control).size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for c in box.get_children(): _shadow(c)
	box.modulate.a = 0.0
	var tw := create_tween().set_parallel(true).set_ignore_time_scale(true)
	tw.tween_property(box, "modulate:a", 1.0, 0.5).set_delay(CARD_AT)
	for side in ["offset_top", "offset_bottom"]:          # sube un poco al aparecer
		tw.tween_property(box, side, 0.0, 0.9).from(18.0).set_trans(Tween.TRANS_CUBIC) \
			.set_ease(Tween.EASE_OUT).set_delay(CARD_AT)
	tw.chain().tween_interval(CARD_HOLD - 0.5)
	tw.chain().tween_property(box, "modulate:a", 0.0, 0.7)

## Alto del modelo del jefe en metros, en reposo (de sus mallas, en el espacio del modelo y a su
## escala): al empezar la entrada aún puede estar saliendo del agua o del suelo.
static func _height(e: Enemy) -> float:
	if e.model == null: return 2.0
	var inv := e.model.global_transform.affine_inverse()
	var top := 0.0
	for n in e.model.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh != null: top = maxf(top, ((inv * mi.global_transform) * mi.get_aabb()).end.y)
	return clampf(top * e.model_scale, 1.0, 14.0)

## Sombra en los textos, para leerse sobre cualquier escenario (aquí no hay franja detrás).
static func _shadow(n: Node) -> void:
	if n is Label:
		(n as Label).add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
		(n as Label).add_theme_constant_override("shadow_offset_x", 0)
		(n as Label).add_theme_constant_override("shadow_offset_y", 3)
		(n as Label).add_theme_constant_override("shadow_outline_size", 10)
	for c in n.get_children(): _shadow(c)
