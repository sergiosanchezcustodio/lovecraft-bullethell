extends GutTest
## Cifras de daño cortas (DamageNumbers.short, 06-11-2026).

func test_cifras() -> void:
	assert_eq(DamageNumbers.short(0.2), "1", "nunca 0")
	assert_eq(DamageNumbers.short(9999.0), "9999")
	assert_eq(DamageNumbers.short(12400.0), "12k")
	assert_eq(DamageNumbers.short(3.0e6), "3000k")
	assert_eq(DamageNumbers.short(1.0e9), "999M", "el modo dios, sin «1000000k»")
	assert_eq(DamageNumbers.short(2.5e7), "25M")
