class_name LaunchArgs
extends RefCounted
## Argumentos de usuario (lo que va detrás de `--` en la línea de comandos).
## Las opciones se escriben como `clave=valor` o `--clave=valor`, y las banderas
## como `--clave`. Lo demás son posicionales, en orden.

var positional: Array[String] = []
var options := {}

static func from_cmdline() -> LaunchArgs:
	return parse(OS.get_cmdline_user_args())

static func parse(raw: PackedStringArray) -> LaunchArgs:
	var la := LaunchArgs.new()
	for a: String in raw:
		var s := a.trim_prefix("--")
		if "=" in s:
			la.options[s.get_slice("=", 0)] = s.get_slice("=", 1)
		elif a.begins_with("--"):
			la.options[s] = "true"
		else:
			la.positional.append(a)
	return la

func has(key: String) -> bool:
	return options.has(key)

func get_str(key: String, default: String = "") -> String:
	return options.get(key, default)

func get_int(key: String, default: int = 0) -> int:
	return int(options[key]) if options.has(key) else default

func get_float(key: String, default: float = 0.0) -> float:
	return float(options[key]) if options.has(key) else default

func get_bool(key: String, default: bool = false) -> bool:
	if not options.has(key): return default
	return options[key] in ["true", "1", "si", "sí"]

## Lista de números separados por comas, p. ej. `shots=2,10,30`.
func get_floats(key: String) -> Array[float]:
	var out: Array[float] = []
	if options.has(key):
		for p: String in str(options[key]).split(",", false):
			out.append(float(p))
	return out
