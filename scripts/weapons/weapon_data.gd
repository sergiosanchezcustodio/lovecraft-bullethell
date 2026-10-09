class_name WeaponData
extends Resource
## Definición de un arma (datos en data/weapons/*.tres). Cada arma decide cómo apunta
## (D-05) y cómo entrega el daño: balas o un objeto lanzado que explota.

## STRONGEST: la élite más cercana o, si no hay, el de más vida (Springfield). FRONT_BACK:
## hacia donde anda el personaje y hacia atrás a la vez, sin buscar objetivo (Lugers).
enum Targeting { NEAREST, DENSEST, MOVE_DIR, AROUND, STRONGEST, FRONT_BACK }
## MELEE: tajo alrededor del personaje (aoe_radius). ORBIT: proyectiles que giran alrededor del
## personaje durante `duration` s (count, aoe_radius = radio de la órbita, projectile_speed =
## grados por segundo). BEAM: rayo recto de `range` m y `projectile_radius` de ancho, que daña
## a todo lo que atraviesa. WAVE: onda que se expande desde el personaje hasta aoe_radius en
## `duration` s, empuja hacia fuera y aturde `stun` s a lo que alcanza.
## FLAME: chorro en cono delante del personaje durante `duration` s (alcance `range`, abertura
## `spread_deg`) que deja fuego en el suelo.
## Arsenal II (hito 2.7):
## SIGIL: signo en el suelo bajo el personaje durante `duration` s (radio aoe_radius) que daña
## `damage` cada hit_interval, empuja hacia fuera y frena las balas enemigas (bullet_slow).
## PULSE: onda como WAVE que además deshace las balas enemigas que alcanza (Resonador).
## TETHER: rayo sostenido `duration` s sobre un enemigo; cada hit_interval hace `damage` y,
## si sigue sobre el mismo, el daño crece `ramp` hasta ramp_max veces (Lente del Éter).
## CLOUD: deja una zona (zone) donde está el grupo más denso (Polvo de Ibn-Ghazi).
## DRONE: `count` orbes que vuelan alrededor del personaje (aoe_radius) durante `duration`
## s y disparan al más cercano cada hit_interval (Orbe Mi-Go).
## STAB: puñalada al más cercano a menos de `range` que lo maldice (Daga ritual).
## Arsenal II, segunda tanda (hito 2.7b):
## CHAIN: rayo que salta de enemigo en enemigo, `count` objetivos a menos de aoe_radius
## entre saltos; cada salto hace un 15 % menos (Bobina Tesla).
## TURRET: deja en el suelo una torreta que dispara sola `duration` s al más cercano cada
## hit_interval (Ametralladora Lewis).
## BOOMERANG: `count` proyectiles que van hasta `range` y vuelven al personaje, golpeando
## una vez a cada enemigo a la ida y otra a la vuelta.
## FISSURE: grieta que avanza por el suelo `range` m a projectile_speed m/s, de aoe_radius
## de ancho, y aturde `stun` s (Martillo de geólogo).
## THRUST: estocada en línea hacia el más cercano, `range` de largo y projectile_radius de
## medio ancho, que daña todo lo que hay en ella (Bastón estoque).
## Arsenal III (D-38, hito 8.8):
## WHIP: latigazo en un sector de `spread_deg` hacia el más cercano, de `range` de largo (Látigo).
## TRAP: deja un cepo a unos metros (como mucho `count` a la vez) que atrapa `root` s al primero
## que lo pisa (aoe_radius) y dura `duration` s (Cepos).
## FIREBALL: bola de fuego que avanza `range` m a projectile_speed, atraviesa y va dejando fuego
## en el suelo (zone) cada pocos pasos (Llama de Cthugha).
## VORTEX: orbe lento hacia el grupo más denso que atrae (`pull`) a los de aoe_radius y los daña
## cada hit_interval durante `duration` s (Esfera de Yog-Sothoth).
## SPIKES: `count` tentáculos que brotan, tras un aviso, bajo enemigos al azar a menos de `range`;
## dañan en aoe_radius y aturden `stun` s (Tentáculos de Shub).
## MADDEN: enloquece a `count` enemigos a menos de `range` durante `duration` s: atacan a los
## suyos con `damage` por segundo y no disparan ni tocan a los jugadores (Signo Amarillo).
## SWEEP: rayo de `range` m que gira alrededor del personaje a projectile_speed grados por
## segundo durante `duration` s; daña cada hit_interval a cada enemigo (Lámpara de Alhazred).
enum Delivery { BULLET, THROWN, MELEE, ORBIT, BEAM, WAVE, FLAME, SIGIL, PULSE, TETHER, CLOUD, DRONE, STAB,
	CHAIN, TURRET, BOOMERANG, FISSURE, THRUST, WHIP, TRAP, FIREBALL, VORTEX, SPIKES, MADDEN, SWEEP }
## Zona que deja en el suelo (lanzados, lanzallamas, nube): ninguna, fuego, ácido o polvo
## (ralentiza y debilita).
## GAS: nube tóxica que deriva (`drift` m/s) hacia donde se lanzó (Gas de cloro).
enum Zone { NONE, FIRE, ACID, DUST, GAS }

## Tipo de ataque, para los atributos (D-27): físico (FUE+TEN: cuerpo a cuerpo y lanzadas
## con el brazo), de fuego (CON+INT) o mágico (POD+CUL: arcanas y tecnología de los Mitos).
enum Category { PHYSICAL, FIREARM, MAGIC }

@export var id := &"revolver"
@export var display_name := "Revólver .38"
@export_multiline var description := ""      ## qué hace, en una frase (descripciones emergentes)
## Aspecto de sus balas (04-10-2026): "" trazadora pesada (pistolas), "pellet" (perdigón),
## "rifle" (estela larga), "smg" (trazadora corta), "blade" (hoja que gira), "spark" (chispa
## de colores), "harpoon" (arpón), "dart" (dardo). Las teledirigidas y las de Yith, las suyas.
@export var bullet_look := ""
@export var sfx := ""                         ## sonido al disparar (data/sfx.json); vacío: según categoría y entrega (hito 8.1)
@export var support := false                ## de puro apoyo (bengala, red...): fuera de las reglas de daño (DamageRules)
@export var icon: Texture2D                  ## imagen del arma (ficha, HUD); sin ella, un hueco
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
@export var homing := 0.0                    ## giro máximo hacia el enemigo más cercano (rad/s; fuegos fatuos)
@export var stasis := 0.0                    ## s de estasis al impactar (Rayo de Yith)
@export var bullet_slow := 0.5               ## velocidad de las balas enemigas dentro del signo
@export var slow_factor := 1.0               ## velocidad de los enemigos dentro de la zona (polvo)
@export var weaken := 1.0                    ## daño que hacen los enemigos dentro de la zona (polvo)
@export var ramp := 0.0                      ## rayo sostenido: aumento del daño por golpe al mismo enemigo
@export var ramp_max := 1.0                  ## rayo sostenido: tope del multiplicador
@export var curse := 0.0                     ## s de maldición (Daga ritual)
@export var curse_dps := 0.0                 ## daño por segundo de la maldición
@export var curse_spread := 0.0              ## enemigos a los que salta al morir el maldito
@export var crit_chance := 0.0               ## probabilidad de crítico (Springfield)
@export var crit_mult := 1.0                 ## daño del crítico
@export var ally_time := 0.0                 ## s que se levanta como aliado el que muere inyectado (West)
@export var root := 0.0                      ## s que deja inmóviles a los de la red (las élites solo se frenan)
@export_group("Arsenal III")
@export var volleys := 1.0                   ## disparos seguidos por uso (Recortada: 2)
@export var volley_delay := 0.2              ## s entre ellos
@export var bounces := 0.0                   ## rebotes de cada bala hacia otro enemigo cercano (BAR)
@export var spinup := 1.0                    ## cadencia máxima al disparar sin parar (Nagant: 2,5); 1 = fija
@export var spinup_time := 3.0               ## s disparando hasta llegar a ella
@export var drift := 0.0                     ## m/s que deriva la zona (Gas de cloro)
@export var frost := false                   ## chorro helado: frena y, si sigue, congela (Aliento de Ithaqua)
@export var pull := 0.0                      ## fuerza con que atrae hacia su centro (Esfera de Yog-Sothoth)
@export var orbit_look := ""                 ## aspecto de la órbita: "" páginas, "ancla"
@export_group("Progresión")
## Evolución (D-06): con el arma al nivel máximo y el objeto `evolves_with` (id de UpgradeData),
## el siguiente baúl arcano la convierte en `evolution` (id de otra arma, con `evolved`).
@export var evolves_with := &""
@export var evolution := &""
@export var evolved := false                  ## es una evolución: no sale al subir de nivel
@export var max_level := 5
## Mejora de cada nivel a partir del 2 (índice 0 = nivel 2). Claves "estadística*"
## multiplican y "estadística+" suman, p. ej. {"damage*": 1.25, "count+": 1}.
@export var level_mods: Array[Dictionary] = []
@export var level_text: Array[String] = []   ## descripción de cada mejora, para el menú

## Imagen del arma: la asignada o, si no la hay, resources/weapons/icons/<id>.png
## (tools/generar_iconos_armas.py). Null si no tiene.
func get_icon() -> Texture2D:
	if icon != null: return icon
	var path := "res://resources/weapons/icons/%s.png" % id
	return load(path) if ResourceLoader.exists(path) else null

## Valor de una estadística en un nivel dado.
func stat(stat_name: String, level: int) -> float:
	var v: float = get(stat_name)
	for i in range(0, mini(level - 1, level_mods.size())):
		var m: Dictionary = level_mods[i]
		if m.has(stat_name + "*"): v *= float(m[stat_name + "*"])
		if m.has(stat_name + "+"): v += float(m[stat_name + "+"])
	return v
