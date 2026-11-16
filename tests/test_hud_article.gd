extends GutTest
## Artículo en «Acaba con …» (Hud.with_article, 06-11-2026).

func test_articulos() -> void:
	assert_eq(Hud.with_article("Primigenio menor"), "el Primigenio menor")
	assert_eq(Hud.with_article("Nyarlathotep, el Caos reptante"), "Nyarlathotep, el Caos reptante")
	assert_eq(Hud.with_article("Emanación de la puerta"), "la Emanación de la puerta")
	assert_eq(Hud.with_article("El viejo Castro"), "El viejo Castro", "ya lo lleva")
	assert_eq(Hud.with_article("Madre Hydra"), "Madre Hydra", "nombre propio")
	assert_eq(Hud.with_article("Cthulhu, recompuesto"), "Cthulhu, recompuesto")
	assert_eq(Hud.with_article("Gedney, lo que queda de él"), "Gedney, lo que queda de él")

func test_la_noche_trae_al_horror() -> void:   # 21.12 (mejoras): el rótulo del modo sin fin
	assert_eq(Hud.with_a("Acechador"), "al Acechador")
	assert_eq(Hud.with_a("El diácono de la Orden"), "al diácono de la Orden")
	assert_eq(Hud.with_a("La pesadilla del bajorrelieve"), "a la pesadilla del bajorrelieve")
	assert_eq(Hud.with_a("Barnabas Marsh, transformado"), "a Barnabas Marsh, transformado")
	assert_eq(Hud.with_a("Pth'thya-l'yi, la antepasada"), "a Pth'thya-l'yi, la antepasada")
