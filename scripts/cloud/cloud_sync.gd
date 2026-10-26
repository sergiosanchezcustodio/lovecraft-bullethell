class_name CloudSync
extends RefCounted
## Qué hacer con cada cosa guardada al comparar este PC con la nube (hito 10.2). Sin red ni
## ficheros: solo revisiones. Cada copia lleva `rev` (sube en cada guardado) y la local además
## `cloud_base`, la revisión de la nube con la que coincidía la última vez. Así:
## - la nube no ha cambiado (rev == base) y aquí sí (rev > base): se sube;
## - la nube ha cambiado y aquí no: se baja;
## - han cambiado los dos (se jugó en dos PC sin conexión): conflicto, elige el jugador.
## No se mira la hora: el reloj de cada PC puede ir a su aire.

enum {NOTHING, UPLOAD, DOWNLOAD, CONFLICT, DELETE_CLOUD}

## `local` y `cloud`: diccionarios con "rev" (y "cloud_base" el local), o null si no hay copia.
## `deleted_rev`: si aquí se borró, la revisión que tenía (−1 si no se borró).
static func decide(local: Variant, cloud: Variant, deleted_rev := -1) -> int:
	if local == null:
		if cloud == null: return NOTHING
		return DELETE_CLOUD if deleted_rev >= _rev(cloud) else DOWNLOAD
	if cloud == null: return UPLOAD
	var lr := _rev(local)
	var base := int((local as Dictionary).get("cloud_base", -1))
	var cr := _rev(cloud)
	if cr < base: return UPLOAD                      # la nube va por detrás (la restauraron): manda la de aquí
	if cr == base: return UPLOAD if lr > base else NOTHING
	return DOWNLOAD if lr == base else CONFLICT

static func _rev(d: Variant) -> int:
	return int((d as Dictionary).get("rev", 0))

## Nombre del fichero de un hueco en la nube.
static func slot_file(i: int) -> String:
	return "slot_%d.json" % (i + 1)

const CONTROLS := "controles.json"
