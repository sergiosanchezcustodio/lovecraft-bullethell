class_name LevelCard
extends CanvasLayer
## Paso entre niveles (28-10-2026): la partida empieza saliendo de negro con un rótulo del nivel
## («Parte 1 · Nivel 2» y su nombre, con el separador de los menús) que se desvanece, y al
## pasar al relato o al siguiente nivel la pantalla funde a negro antes de cambiar de escena.
## El relato ya empieza en negro, así que de nivel a relato y de relato a nivel no hay cortes.

const FADE_IN := 1.0            ## s de negro a la partida
const CARD_AT := 0.45           ## s hasta que aparece el rótulo
const CARD_HOLD := 2.6          ## s que se queda entero
const FADE_OUT := 0.45          ## s de la partida a negro al salir
const BLACK := Color(0.01, 0.01, 0.015)

## Rótulo y salida de negro al empezar un nivel. `id`: el de data/campaign.json (sin él, solo
## el nombre).
static func enter(parent: Node, id: String, level_name: String) -> LevelCard:
	var c := LevelCard.new()
	c.layer = 90
	c.process_mode = Node.PROCESS_MODE_ALWAYS          # también mientras la red espera a todos
	parent.add_child(c)
	var black := _black(c, 1.0)
	var card := c._card(id, level_name)
	card.modulate.a = 0.0
	var tw := c.create_tween().set_parallel(true)
	tw.tween_property(black, "color:a", 0.0, FADE_IN).set_trans(Tween.TRANS_SINE).set_delay(0.1)
	tw.tween_property(card, "modulate:a", 1.0, 0.6).set_delay(CARD_AT)
	for side in ["offset_top", "offset_bottom"]:          # sube un poco al aparecer
		tw.tween_property(card, side, 0.0, 0.9).from(16.0).set_trans(Tween.TRANS_CUBIC) \
			.set_ease(Tween.EASE_OUT).set_delay(CARD_AT)
	tw.chain().tween_interval(CARD_HOLD - 0.6)
	tw.chain().tween_property(card, "modulate:a", 0.0, 0.9)
	tw.chain().tween_callback(c.queue_free)
	return c

## Funde a negro y después llama a `then` (cambiar de escena).
static func leave(parent: Node, then: Callable, secs := FADE_OUT) -> void:
	var c := LevelCard.new()
	c.layer = 128
	c.process_mode = Node.PROCESS_MODE_ALWAYS
	parent.add_child(c)
	var black := _black(c, 0.0)
	var tw := c.create_tween()
	tw.tween_property(black, "color:a", 1.0, secs).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(then)

static func _black(c: CanvasLayer, a: float) -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(BLACK, a)
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(r)
	return r

## «Parte N · Nivel M» (y el título de la parte) encima del nombre del nivel, sobre una franja
## oscura que se desvanece arriba y abajo para leerse sobre cualquier escenario.
func _card(id: String, level_name: String) -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var band := TextureRect.new()
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
	g.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0.55), Color(0, 0, 0, 0.55), Color(0, 0, 0, 0)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	gt.width = 4
	gt.height = 64
	band.texture = gt
	band.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	band.stretch_mode = TextureRect.STRETCH_SCALE
	band.anchor_left = 0.0; band.anchor_right = 1.0
	band.anchor_top = 0.19; band.anchor_bottom = 0.41
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(band)
	var box := VBoxContainer.new()
	box.anchor_left = 0.0; box.anchor_right = 1.0
	box.anchor_top = 0.235; box.anchor_bottom = 0.235
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(box)
	var over := _over_line(id)
	if over != "":
		var l := MenuKit.title(over, 24, Color(MenuKit.INK, 0.75))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(l)
	var name_box := VBoxContainer.new()
	name_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(name_box)
	var h := MenuKit.heading(name_box, level_name, 50)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for n in h.get_parent().get_children():            # el separador, centrado bajo el nombre
		(n as Control).size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return box

## «Parte 1 · Nivel 2 · En las montañas de la locura» del nivel `id` ("" si no es de la campaña).
static func _over_line(id: String) -> String:
	if Challenge.is_challenge(id): return "Desafío · " + _over_line(Challenge.base_of(id))   # (hito 15.2)
	for l in Campaign.levels():
		if String(l.id) != id: continue
		var parts := Campaign.parts()
		var title := String((parts[int(l.part)] as Dictionary).get("title", "")) if int(l.part) < parts.size() else ""
		return "Parte %d · Nivel %d%s" % [int(l.part) + 1, int(l.number), (" · " + title) if title != "" else ""]
	return ""
