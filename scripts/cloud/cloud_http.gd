class_name CloudHttp
extends Node
## Transporte HTTP de la nube (fase 10): una petición, un `HTTPRequest` que se borra al acabar.
## `GitHubGist` solo usa `request`, así que en las pruebas se cambia por uno falso.

const TIMEOUT := 20.0                        ## s: sin respuesta, se da por perdida

## Devuelve {"code": código HTTP (0 si no hubo respuesta), "body": texto, "result": HTTPRequest.Result}.
func request(method: int, url: String, headers: PackedStringArray, body := "") -> Dictionary:
	var h := HTTPRequest.new()
	h.timeout = TIMEOUT
	add_child(h)
	var err := h.request(url, headers, method as HTTPClient.Method, body)
	if err != OK:
		h.queue_free()
		return {"code": 0, "body": "", "result": HTTPRequest.RESULT_CANT_CONNECT}
	var r: Array = await h.request_completed
	h.queue_free()
	var ok: bool = r[0] == HTTPRequest.RESULT_SUCCESS
	return {"code": int(r[1]) if ok else 0, "body": (r[3] as PackedByteArray).get_string_from_utf8(), "result": r[0]}
