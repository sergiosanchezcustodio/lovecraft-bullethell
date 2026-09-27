class_name WeaponData
extends Resource
## Definición de un arma (datos en data/weapons/*.tres). Cada arma decide cómo apunta
## (D-05) y cómo entrega el daño: balas o un objeto lanzado que explota.

enum Targeting { NEAREST, DENSEST, MOVE_DIR, AROUND }
## MELEE: tajo alrededor del personaje (aoe_radius). ORBIT: proyectiles que giran alrededor del
## personaje durante `duration` s (count, aoe_radius = radio de la órbita, projectile_speed =
## grados por segundo). BEAM: rayo recto de `range` m y `projectile_radius` de ancho, que daña
## a todo lo que atraviesa. WAVE: onda que se expande desde el personaje hasta aoe_radius en
## `duration` s, empuja hacia fuera y aturde `stun` s a lo que alcanza.
## FLAME: chorro en cono delante del personaje durante `duration` s (alcance `range`, abertura
## `spread_deg`) que deja fuego en el suelo.
enum Delivery { BULLET, THROWN, MELEE, ORBIT, BEAM, WAVE, FLAME }
## Zona que deja en el suelo (lanzados, lanzallamas): ninguna, fuego o ácido.
enum Zone { NONE, FIRE, ACID }

## Tipo de ataque, para los atributos (D-27): físico (FUE+TEN: cuerpo a cuerpo y lanzadas
## con el brazo), de fuego (CON+INT) o mágico (POD+EDU: arcanas y tecnología de los Mitos).
enum Category { PHYSICAL, FIREARM, MAGIC }

@export var id := &"revolver"
@export var display_name := "Revólver .38"
@export var delivery := Delivery.BULLET
@export var targeting := Targeting.NEAREST
@export var category := Category.FIREARM
@export_group("Base (nivel 1)")
@export var cooldown := 0.8                  ## s entre disparos
@export var range := 12.0                    ## alcance para elegir objetivo (m)
@export var damage := 12.0
@export var count := 1.0                     ## proyectiles por disparo
@export var spread_deg := 0.0                ## abanico entre proyectiles
@export var burst_delay := 0.0               ## s entre proyectiles de un mismo disparo
@export var pierce := 0.0                    ## enemigos que atraviesa además del primero
@export var projectile_speed := 22.0
@export var projectile_radius := 0.2         ## radio de colisión
@export var projectile_size := 0.17          ## radio visual
@export var aoe_radius := 0.0                ## explosión (lanzados)
@export var flight_time := 0.0               ## s en el aire (lanzados)
@export var fuse := 0.0                      ## s de mecha tras caer (lanzados)
@export var sanity_cost := 0.0               ## armas arcanas: cordura por uso
@export var knockback := 1.0                 ## empuje sobre los enemigos (1 = el de una bala normal)
@export var duration := 0.0                  ## s activa (órbita) o visible (rayo)
@export var hit_interval := 0.45             ## órbita: s entre dos golpes al mismo enemigo
@export var stun := 0.0                      ## s que deja aturdido al enemigo (onda)
@export var jitter_deg := 0.0                ## desvío al azar de cada proyectil (errático)
@export var split_count := 0.0               ## al explotar o apagarse, se divide en tantos proyectiles
@export var zone := Zone.NONE                ## zona en el suelo al caer (lanzados) o a lo largo del chorro
@export var zone_radius := 1.6
@export var zone_time := 3.0                 ## s que dura la zona
@export var zone_dps := 8.0                  ## daño por segundo dentro de la zona
@export var vulnerable := 0.0                ## s que el enemigo recibe +25 % de daño (ácido)
@export var lure := 0.0                      ## s que la bengala atrae a los enemigos cercanos
@export var arc_height := 2.2                ## altura del arco de los lanzados
@export var look := "dinamita"               ## aspecto del lanzado: dinamita, granada, molotov, frasco, bengala
@export_group("Progresión")
@export var max_level := 5
## Mejora de cada nivel a partir del 2 (índice 0 = nivel 2). Claves "estadística*"
## multiplican y "estadística+" suman, p. ej. {"damage*": 1.25, "count+": 1}.
@export var level_mods: Array[Dictionary] = []
@export var level_text: Array[String] = []   ## descripción de cada mejora, para el menú

## Valor de una estadística en un nivel dado.
func stat(stat_name: String, level: int) -> float:
	var v: float = get(stat_name)
	for i in range(0, mini(level - 1, level_mods.size())):
		var m: Dictionary = level_mods[i]
		if m.has(stat_name + "*"): v *= float(m[stat_name + "*"])
		if m.has(stat_name + "+"): v += float(m[stat_name + "+"])
	return v
