extends GutTest
## La interfaz Pequeña solo vale desde 1080 de alto (Settings.ui_scale_for, 06-11-2026).

func test_pequena_desde_1080() -> void:
	assert_eq(Settings.ui_scale_for(0, 1080), 0.85)
	assert_eq(Settings.ui_scale_for(0, 1440), 0.85)
	assert_eq(Settings.ui_scale_for(0, 720), 1.0, "a 720, como la Normal")
	assert_eq(Settings.ui_scale_for(0, 900), 1.0)

func test_las_demas_igual() -> void:
	for h in [720, 1080]:
		assert_eq(Settings.ui_scale_for(1, h), 1.0)
		assert_eq(Settings.ui_scale_for(2, h), 1.15)
		assert_eq(Settings.ui_scale_for(3, h), 1.3)
