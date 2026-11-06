extends GutTest
## Artículo en «Acaba con …» (Hud.with_article, 06-11-2026).

func test_articulos() -> void:
	assert_eq(Hud.with_article("Primigenio menor"), "el Primigenio menor")
	assert_eq(Hud.with_article("Emanación de la puerta"), "la Emanación de la puerta")
	assert_eq(Hud.with_article("El viejo Castro"), "El viejo Castro", "ya lo lleva")
	assert_eq(Hud.with_article("Madre Hydra"), "Madre Hydra", "nombre propio")
	assert_eq(Hud.with_article("Cthulhu, recompuesto"), "Cthulhu, recompuesto")
	assert_eq(Hud.with_article("Gedney, lo que queda de él"), "Gedney, lo que queda de él")
