class_name UpnpHelper
extends RefCounted
## Abre el puerto del anfitrión en el router con UPnP (hito 9.1) y averigua la IP pública.
## Buscar el router bloquea uno o dos segundos, así que va en un hilo; `finished` llega en el
## hilo principal. Si el router no tiene UPnP (o hay CGNAT), se queda sin abrir y la sala
## funciona igual en la red de casa o abriendo el puerto a mano.

signal finished(ok: bool, external_ip: String, message: String)

const DESCRIPTION := "Lovecraft Library"

var _thread: Thread
var _upnp: UPNP
var _port := 0
var _mapped := false

## Empieza a abrir `port` (UDP). Llama a `close()` al cerrar la sala.
func open(port: int) -> void:
	_port = port
	_thread = Thread.new()
	_thread.start(_work)

func _work() -> void:
	var u := UPNP.new()
	var err := u.discover(2000, 2, "InternetGatewayDevice")
	if err != UPNP.UPNP_RESULT_SUCCESS or u.get_gateway() == null or not u.get_gateway().is_valid_gateway():
		_done.call_deferred(false, "", "El router no responde a UPnP")
		return
	_upnp = u
	var ext := u.query_external_address()
	if u.add_port_mapping(_port, _port, DESCRIPTION, "UDP", 0) != UPNP.UPNP_RESULT_SUCCESS:
		_done.call_deferred(false, ext, "El router no deja abrir el puerto")
		return
	_mapped = true
	if ext.is_empty() or RoomCode.is_private(ext):    # router detrás de otro router o CGNAT
		_done.call_deferred(false, ext, "El router no tiene IP pública (CGNAT o doble router)")
		return
	_done.call_deferred(true, ext, "Puerto %d abierto" % _port)

func _done(ok: bool, ext: String, message: String) -> void:
	if _thread != null and _thread.is_started(): _thread.wait_to_finish()
	finished.emit(ok, ext, message)

## Cierra el puerto si se abrió. Espera al hilo si aún busca el router.
func close() -> void:
	if _thread != null and _thread.is_started(): _thread.wait_to_finish()
	_thread = null
	if _mapped and _upnp != null: _upnp.delete_port_mapping(_port, "UDP")
	_mapped = false
