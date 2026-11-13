extends SceneTree
## Hoja de la entrada de las ventanas como una página (hito 20.2): una ventana de MenuKit sobre la
## portada a varios puntos del giro (`MenuKit._page_angle`), de canto a plana.
## `godot --path . -s tools/probar_pagina.gd` → shots/pagina_hoja.png

const STEPS := [0.85, 0.65, 0.45, 0.25, 0.0]

func _initialize() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(1920, 1080)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var bg := TextureRect.new()
	bg.texture = load("res://resources/PantallasMenus/fondo_titulo_sin_texto_1080p_definitivo.png")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	vp.add_child(bg)
	var holder := Control.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	vp.add_child(holder)
	var w: Array = MenuKit.window(holder, MenuKit.INK, 900)
	var box: VBoxContainer = w[1]
	MenuKit.heading(box, "Configuración")
	for t in ["Pantalla completa", "Tamaño de la ventana", "Calidad gráfica", "Efectos de las armas"]:
		box.add_child(MenuKit.button(t))
	var panel: Control = box.get_parent().get_parent()   # dress() mete el contenido en un margen
	for _f in 30: await process_frame                       # que termine su propia entrada
	var cw := 640
	var ch := 360
	var sheet := Image.create(cw * STEPS.size(), ch, false, Image.FORMAT_RGB8)
	for i in STEPS.size():
		panel.pivot_offset = Vector2(0.0, panel.size.y * 0.5)
		MenuKit._page_angle(STEPS[i], panel)
		for _f in 3: await process_frame
		var shot := vp.get_texture().get_image()
		shot.resize(cw, ch, Image.INTERPOLATE_LANCZOS)
		shot.convert(Image.FORMAT_RGB8)
		sheet.blit_rect(shot, Rect2i(0, 0, cw, ch), Vector2i(i * cw, 0))
	var out := ProjectSettings.globalize_path("res://shots/pagina_hoja.png")
	sheet.save_png(out)
	print("Hoja: ", out)
	quit()
