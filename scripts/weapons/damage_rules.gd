class_name DamageRules
extends RefCounted
## Reglas de daño de las armas (D-37). Todas parten de un mismo daño por segundo de
## referencia a un solo objetivo (BASE_DPS, nivel 1, si todo acierta), multiplicado por un
## factor por rasgo:
##   corto alcance ×1,3 / largo ×0,85; un objetivo ×1,15 / área ×0,8;
##   un proyectil ×1,15 / varios ×0,85; cadencia baja ×1,2 / alta ×0,85;
##   cuesta cordura ×1,2 (vida o esquive ×1,3, cuando haya armas que los gasten);
##   teledirigida ×0,8 / al azar o sin apuntar ×1,15;
##   control (aturde, inmoviliza, atrae, congela, frena, debilita, hace vulnerable, frena
##   balas o levanta aliados) ×0,6. Las de puro apoyo (`WeaponData.support`) quedan fuera.
## `dps()` estima el daño por segundo actual a partir de los datos; `target_dps()` es el que le
## toca. tools/reglas_dano.gd imprime la tabla y ajusta `damage` (y zone_dps, curse_dps).

const BASE_DPS := 14.0              ## calibrado con la mediana del arsenal (03-10-2026)
const TOLERANCE := 0.15

const D := WeaponData.Delivery
## Entregas que no son proyectiles: el rasgo "uno o varios proyectiles" no se aplica.
const NO_PROJECTILE := [D.MELEE, D.WAVE, D.PULSE, D.SIGIL, D.FLAME, D.CLOUD, D.TETHER, D.STAB,
	D.THRUST, D.FISSURE, D.BEAM, D.CHAIN, D.TURRET, D.WHIP, D.TRAP, D.VORTEX, D.SPIKES, D.MADDEN, D.SWEEP]
## Entregas que dañan una zona o una línea (o atraviesan).
const AREA := [D.MELEE, D.ORBIT, D.WAVE, D.PULSE, D.SIGIL, D.FLAME, D.CLOUD, D.CHAIN, D.FISSURE,
	D.BEAM, D.THRUST, D.WHIP, D.FIREBALL, D.VORTEX, D.SPIKES, D.SWEEP]
## Entregas centradas en el personaje: su alcance es aoe_radius.
const SELF := [D.MELEE, D.ORBIT, D.WAVE, D.PULSE, D.SIGIL, D.SWEEP]

const SHORT_REACH := 5.0
const LONG_REACH := 14.0
const SLOW_COOLDOWN := 1.5
const FAST_COOLDOWN := 0.5

## Rasgos del arma: diccionario rasgo -> [etiqueta, factor].
static func traits(w: WeaponData) -> Dictionary:
	var t := {}
	var reach := w.aoe_radius if w.delivery in SELF and w.delivery != D.SWEEP else w.range
	if reach <= SHORT_REACH: t["alcance"] = ["corto", 1.3]
	elif reach >= LONG_REACH: t["alcance"] = ["largo", 0.85]
	var area := w.delivery in AREA or w.pierce > 0.0 or w.zone != WeaponData.Zone.NONE \
		or (w.delivery == D.THROWN and w.aoe_radius > 0.0)
	t["objetivo"] = ["área", 0.8] if area else ["uno", 1.15]
	if not w.delivery in NO_PROJECTILE:
		var multi := w.count > 1.0 or w.split_count > 0.0
		t["proyectiles"] = ["varios", 0.85] if multi else ["uno", 1.15]
	if w.cooldown >= SLOW_COOLDOWN: t["cadencia"] = ["baja", 1.2]
	elif w.cooldown <= FAST_COOLDOWN: t["cadencia"] = ["alta", 0.85]
	if w.sanity_cost > 0.0: t["coste"] = ["cordura", 1.2]
	if w.homing > 0.0 or w.delivery == D.CHAIN: t["apuntado"] = ["teledirigida", 0.8]
	elif w.jitter_deg > 0.0 or w.targeting in [WeaponData.Targeting.MOVE_DIR, WeaponData.Targeting.FRONT_BACK]:
		t["apuntado"] = ["al azar", 1.15]
	if is_control(w): t["control"] = ["control", 0.6]
	return t

static func is_control(w: WeaponData) -> bool:
	return w.stun > 0.0 or w.root > 0.0 or w.lure > 0.0 or w.stasis > 0.0 or w.vulnerable > 0.0 		or w.ally_time > 0.0 or w.delivery in [D.PULSE, D.SIGIL] or w.zone == WeaponData.Zone.DUST 		or (w.delivery == D.CLOUD and (w.slow_factor < 1.0 or w.weaken < 1.0)) or w.frost or w.pull > 0.0 		or w.delivery == D.MADDEN

static func factor(w: WeaponData) -> float:
	var f := 1.0
	for v in traits(w).values(): f *= float(v[1])
	return f

static func target_dps(w: WeaponData) -> float:
	return BASE_DPS * factor(w)

## Daño a un solo objetivo por uso (todo acierta), sin el de las zonas ni maldiciones.
static func _hit_per_use(w: WeaponData) -> float:
	match w.delivery:
		D.CHAIN, D.CLOUD: return w.damage if w.delivery == D.CHAIN else 0.0
		D.BOOMERANG: return w.damage * w.count * 2.0
		D.ORBIT, D.SIGIL, D.TURRET: return w.damage * w.duration / maxf(w.hit_interval, 0.05)
		D.DRONE: return w.damage * w.count * w.duration / maxf(w.hit_interval, 0.05)
		D.TETHER: return w.damage * w.duration / maxf(w.hit_interval, 0.05) * (1.0 + w.ramp_max) * 0.5
		D.FLAME: return w.damage * w.duration / 0.15
		D.VORTEX: return w.damage * w.duration / maxf(w.hit_interval, 0.05)
		D.SWEEP: return w.damage * maxf(w.duration * w.projectile_speed / 360.0, 1.0)   # una vez por vuelta
		D.MADDEN: return w.damage * w.duration                   # lo que hacen los enloquecidos
		D.SPIKES, D.TRAP: return w.damage                        # cada uno, a un enemigo distinto
	if w.delivery == D.BULLET: return w.damage * w.count * w.volleys
	return w.damage * w.count

## s entre usos: las páginas y los orbes no vuelven a salir mientras están activos.
static func cycle(w: WeaponData) -> float:
	if w.delivery in [D.ORBIT, D.DRONE, D.SWEEP]: return maxf(w.cooldown, w.duration)
	if w.spinup > 1.0: return w.cooldown / ((1.0 + w.spinup) * 0.5)   # Nagant: la cadencia media
	return maxf(w.cooldown, 0.05)

## Daño por segundo a un solo objetivo, nivel 1, si todo acierta.
static func dps(w: WeaponData) -> float:
	var per_use := _hit_per_use(w) * (1.0 + w.crit_chance * (w.crit_mult - 1.0))
	if w.zone != WeaponData.Zone.NONE and w.zone_dps > 0.0: per_use += w.zone_dps * w.zone_time
	if w.curse > 0.0: per_use += w.curse_dps * w.curse
	return per_use / cycle(w)

## Desvío del daño actual respecto al que le toca (0,1 = un 10 % de más).
static func deviation(w: WeaponData) -> float:
	return dps(w) / target_dps(w) - 1.0

static func all_weapons() -> Array[WeaponData]:
	var out: Array[WeaponData] = []
	for f in DirAccess.get_files_at("res://data/weapons"):
		if f.ends_with(".tres"): out.append(load("res://data/weapons/" + f))
	out.sort_custom(func(a: WeaponData, b: WeaponData) -> bool: return int(a.evolved) < int(b.evolved))
	return out
