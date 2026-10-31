class_name DeathReplay
extends Node
## Repetición de la caída (hito 15.1, fase 15). Guarda en memoria los últimos `SECONDS` s de la
## pantalla, `FPS` imágenes por segundo de reloj real a `W`×`H`, y la pantalla final las enseña a
## media velocidad («Ver la caída», `ReplayView`). La lectura de la pantalla es asíncrona
## (`RenderingDevice.texture_get_data_async`: no para la GPU) y la reducción se hace en un hilo
## (`WorkerThreadPool`), así que el hilo principal casi no lo nota. Se para sola con la partida en
## pausa (la caída termina con el árbol pausado), y deja de grabar con `freeze()`.
## Sin `RenderingDevice` (renderizador de compatibilidad) no graba. `replay=false` la quita y la
## calidad gráfica también (`replay` en `data/quality.json`).

const SECONDS := 5.0
const FPS := 12.0
const W := 384
const H := 216

var frames: Array[Image] = []                  ## de la más antigua a la más reciente
var _rd: RenderingDevice
var _next_ms := 0
var _busy := 0                                 ## lecturas o reducciones en curso (como mucho 2)
var _frozen := false
var _mutex := Mutex.new()

func _ready() -> void:
	name = "DeathReplay"
	_rd = RenderingServer.get_rendering_device()

## Las imágenes guardadas, en orden; ya no graba más.
func freeze() -> Array[Image]:
	_frozen = true
	_mutex.lock()
	var out := frames.duplicate()
	_mutex.unlock()
	return out

func _process(_delta: float) -> void:
	if _frozen or _rd == null or _busy >= 2: return
	var now := Time.get_ticks_msec()
	if now < _next_ms: return
	_next_ms = now + int(1000.0 / FPS)
	var t0 := Prof.start()
	var rid := RenderingServer.texture_get_rd_texture(get_viewport().get_texture().get_rid())
	if not rid.is_valid(): return
	var fmt := _rd.texture_get_format(rid)
	var img_fmt := _image_format(fmt.format)
	if img_fmt < 0: return
	_busy += 1
	var err := _rd.texture_get_data_async(rid, 0, _got.bind(fmt.width, fmt.height, img_fmt))
	if err != OK: _busy -= 1
	Prof.stop("repeticion", t0)

func _image_format(f: int) -> int:
	match f:
		RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM, RenderingDevice.DATA_FORMAT_R8G8B8A8_SRGB:
			return Image.FORMAT_RGBA8
		RenderingDevice.DATA_FORMAT_R16G16B16A16_SFLOAT:
			return Image.FORMAT_RGBAH
	return -1

func _got(data: PackedByteArray, w: int, h: int, img_fmt: int) -> void:
	if _frozen:
		_busy -= 1
		return
	WorkerThreadPool.add_task(_shrink.bind(data, w, h, img_fmt))

## En un hilo: de la pantalla entera a W×H en dos pasos (el bilineal de una vez se salta píxeles).
func _shrink(data: PackedByteArray, w: int, h: int, img_fmt: int) -> void:
	var img := Image.create_from_data(w, h, false, img_fmt, data)
	if img_fmt != Image.FORMAT_RGBA8: img.convert(Image.FORMAT_RGBA8)
	img.resize(W * 2, H * 2, Image.INTERPOLATE_BILINEAR)
	img.resize(W, H, Image.INTERPOLATE_BILINEAR)
	img.convert(Image.FORMAT_RGB8)                # sin alfa: tres cuartos de la memoria
	_mutex.lock()
	if not _frozen:
		frames.append(img)
		while frames.size() > int(SECONDS * FPS): frames.pop_front()
	_mutex.unlock()
	_done.call_deferred()

func _done() -> void:
	_busy -= 1
