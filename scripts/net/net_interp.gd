class_name NetInterp
extends RefCounted
## Historial de estados que llegan de otro PC, para dibujarlos un poco en el pasado e
## interpolar entre dos fotos (hito 9.3a). Cada pista (un enemigo, un jugador) guarda
## [ms del que lo manda, valores]; `sample` da las dos fotos que rodean un instante y el peso.
##
## Reloj: cada PC cuenta sus propios ms. `observe` estima la diferencia con el del que manda
## (sube deprisa con un paquete que llega antes de lo esperado y baja despacio con uno que se
## retrasa, así que se queda cerca del retraso más corto) y `render_ms` da el instante que
## toca dibujar: el reloj del otro menos DELAY_MS.

const DELAY_MS := 100.0                      ## dos fotos a 20 Hz: aguanta que se pierda una
const KEEP := 12                             ## fotos por pista
const STALE_MS := 2000.0                     ## pistas sin fotos nuevas en este tiempo, fuera

var offset := 0.0                            ## ms del otro PC menos los de este
var has_clock := false
var tracks := {}                             ## clave -> Array de [ms, valores]

func observe(remote_ms: float, local_ms: float) -> void:
	var d := remote_ms - local_ms
	if not has_clock:
		offset = d
		has_clock = true
	else:
		offset += (d - offset) * (0.1 if d > offset else 0.01)

func render_ms(local_ms: float) -> float:
	return local_ms + offset - DELAY_MS

func push(key: Variant, t: float, values: Array) -> void:
	var tr: Array = tracks.get(key, [])
	if tr.is_empty() or t > float(tr[-1][0]):
		tr.append([t, values])
	else:                                    # fuera de orden: en su sitio (o fuera, si se repite)
		var i := tr.size() - 1
		while i >= 0 and float(tr[i][0]) > t: i -= 1
		if i >= 0 and float(tr[i][0]) == t: return
		tr.insert(i + 1, [t, values])
	while tr.size() > KEEP: tr.pop_front()
	tracks[key] = tr

## [valores de antes, valores de después, peso 0..1] para el instante `t`, o [] si no hay
## nada. Antes de la primera foto da la primera; pasada la última, la última (sin adivinar).
func sample(key: Variant, t: float) -> Array:
	var tr: Array = tracks.get(key, [])
	if tr.is_empty(): return []
	if t <= float(tr[0][0]): return [tr[0][1], tr[0][1], 0.0]
	var i := tr.size() - 1
	while i > 0 and float(tr[i][0]) > t: i -= 1
	if i == tr.size() - 1: return [tr[i][1], tr[i][1], 0.0]
	var a: Array = tr[i]
	var b: Array = tr[i + 1]
	return [a[1], b[1], clampf((t - float(a[0])) / maxf(float(b[0]) - float(a[0]), 1.0), 0.0, 1.0)]

## La foto más reciente de una pista ([] si no hay).
func latest(key: Variant) -> Array:
	var tr: Array = tracks.get(key, [])
	return tr[-1][1] if not tr.is_empty() else []

func last_ms(key: Variant) -> float:
	var tr: Array = tracks.get(key, [])
	return float(tr[-1][0]) if not tr.is_empty() else -INF

## Quita las pistas que llevan STALE_MS sin fotos (enemigos que ya no existen).
func prune(now_remote_ms: float) -> void:
	for k in tracks.keys():
		if now_remote_ms - last_ms(k) > STALE_MS: tracks.erase(k)
