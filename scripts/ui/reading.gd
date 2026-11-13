class_name Reading
extends RefCounted
## Texto de lectura (hito 20.13): el tamaño y el contraste de los relatos entre niveles y de las
## páginas del diario, aparte del tamaño de la interfaz (que se multiplica encima). Los ajustes
## son `reading_size` (0 Normal, 1 Grande, 2 Muy grande) y `reading_contrast` (más contraste:
## letra más clara sobre un fondo más oscuro en los relatos, tinta más negra sobre papel más claro
## en el diario). Las páginas de la Biblioteca no cambian: son de tamaño fijo.

const SIZES := [1.0, 1.18, 1.35]
const NAMES: Array[String] = ["Normal", "Grande", "Muy grande"]

static func k() -> float:
	return SIZES[clampi(int(Auto.setting("reading_size", 0)), 0, SIZES.size() - 1)]

static func px(base: int) -> int:
	return int(round(base * k()))

static func contrast() -> bool:
	return bool(Auto.setting("reading_contrast", false))
