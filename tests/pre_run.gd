extends GutHookScript
## Antes de los tests: dificultad base (Investigador). Los tests comprueban daños, topes y
## ritmos exactos; no deben depender de la dificultad guardada en la configuración.

func run() -> void:
	Difficulty.forced = 0
