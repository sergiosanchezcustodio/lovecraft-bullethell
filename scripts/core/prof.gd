class_name Prof
extends RefCounted
## Perfilador mínimo por sistemas (activado con la opción prof=true de la partida).
## Uso: var t := Prof.start()  ...  Prof.stop("balas", t)

static var enabled := false
static var totals := {}
static var calls := {}

static func start() -> int:
	return Time.get_ticks_usec() if enabled else 0

static func stop(key: String, t0: int) -> void:
	if not enabled: return
	totals[key] = totals.get(key, 0) + Time.get_ticks_usec() - t0
	calls[key] = calls.get(key, 0) + 1

static func report(ticks: int) -> String:
	var out: PackedStringArray = []
	var keys := totals.keys()
	keys.sort_custom(func(a: String, b: String) -> bool: return totals[a] > totals[b])
	for k: String in keys:
		out.append("%s=%.2f ms" % [k, totals[k] / 1000.0 / maxf(ticks, 1)])
	return "  ".join(out)
