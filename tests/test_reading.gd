extends GutTest
## Hito 20.13: tamaño y contraste del texto de los relatos y el diario.

func after_each() -> void:
	Settings._overrides.erase("reading_size")
	Settings._overrides.erase("reading_contrast")

func _page() -> DiaryPage:
	var p := DiaryPage.new([{"who": "J1 · Dyer", "color": Color.WHITE, "title": "Prueba", "text": "Una entrada."}])
	add_child_autofree(p)
	return p

func test_normal() -> void:
	assert_eq(Reading.px(24), 24)
	var p := _page()
	assert_eq(p._text.get_theme_font_size("font_size"), 24)
	assert_eq(p._text.get_theme_color("font_color"), DiaryPage.INK)

func test_muy_grande_y_contraste() -> void:
	Settings._overrides["reading_size"] = 2
	Settings._overrides["reading_contrast"] = true
	assert_eq(Reading.px(24), int(round(24 * Reading.SIZES[2])))
	var p := _page()
	assert_eq(p._text.get_theme_font_size("font_size"), Reading.px(24))
	assert_eq(p._text.get_theme_color("font_color"), DiaryPage.INK_HC)
