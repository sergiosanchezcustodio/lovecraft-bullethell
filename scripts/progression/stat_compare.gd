class_name StatCompare
extends RefCounted
## Comparar antes de elegir (hito 16.29): lo que cambia en tus estadísticas con una opción de la
## subida de nivel (o con el siguiente nivel de un potenciador de la tienda), en verde si mejora
## y en rojo si empeora. Cada fila: {name, before, after, good}. `bbcode` las junta para un
## RichTextLabel.

const GOOD := Color(0.5, 0.92, 0.45)
const BAD := Color(0.95, 0.42, 0.36)

## Estadísticas del personaje que tocan los objetos: [nombre, formato, unidad, menos es mejor].
## Formatos: "mult" (factor: +12 %), "pct" (fracción: 8 %), "num" (con decimales), "int".
const STATS := {
	"max_health": ["Vida", "int", "", false], "max_sanity": ["Cordura", "int", "", false],
	"move_speed": ["Velocidad", "num", " m/s", false], "health_regen": ["Vida por segundo", "num", "", false],
	"sanity_regen": ["Cordura por segundo", "num", "", false], "heal_on_kill": ["Vida por baja", "num", "", false],
	"sanity_on_kill": ["Cordura por baja", "num", "", false], "armor": ["Armadura", "num", "", false],
	"calm_aura": ["Calma por segundo", "num", "", false], "damage_mult": ["Daño", "mult", "", false],
	"physical_mult": ["Daño físico", "mult", "", false], "firearm_mult": ["Daño balístico", "mult", "", false],
	"magic_mult": ["Daño mágico", "mult", "", false], "elite_mult": ["Daño a élites", "mult", "", false],
	"knockback_mult": ["Empuje", "mult", "", false], "range_mult": ["Alcance", "mult", "", false],
	"area_mult": ["Área", "mult", "", false], "duration_mult": ["Duración", "mult", "", false], "ally_mult": ["Duración de los aliados", "mult", "", false], "ally_dmg_mult": ["Daño de los aliados", "mult", "", false],
	"proj_speed_mult": ["Velocidad de los proyectiles", "mult", "", false],
	"weapon_cooldown_mult": ["Recarga de las armas", "mult", "", true],
	"arcane_cooldown_mult": ["Recarga de las mágicas", "mult", "", true],
	"arcane_cost_mult": ["Cordura de las mágicas", "mult", "", true],
	"mental_mult": ["Daño mental recibido", "mult", "", true], "crisis_mult": ["Duración de las crisis", "mult", "", true],
	"xp_mult": ["Experiencia", "mult", "", false], "money_mult": ["Dólares", "mult", "", false],
	"luck": ["Suerte", "mult", "", false], "pet_mult": ["Compañero", "mult", "", false],
	"pickup_heal_mult": ["Curación de la comida", "mult", "", false], "chest_mult": ["Baúles arcanos", "mult", "", false],
	"idol_mult": ["Enemigos, experiencia y dólares", "mult", "", false],
	"crit_chance": ["Crítico", "pct", "", false], "crit_bonus": ["Daño del crítico", "pct", "", false],
	"hit_slow": ["Frenar al impactar", "pct", "", false], "hit_burn": ["Prender al impactar", "pct", "", false],
	"kill_blast": ["Estallido al abatir", "pct", "", false], "low_hp_bonus": ["Daño con poca vida", "pct", "", false],
	"dodge_fury": ["Daño tras esquivar", "pct", "", false], "thorns": ["Espinas", "pct", "", false],
	"pickup_radius": ["Radio de recogida", "num", " m", false], "dodge_speed": ["Impulso del esquive", "num", "", false],
	"dodge_iframes": ["Invulnerable al esquivar", "num", " s", false], "dodge_cooldown": ["Recarga del esquive", "num", " s", true],
	"hit_iframes": ["Invulnerable tras un golpe", "num", " s", false], "decoy_time": ["Señuelo", "num", " s", false],
	"dodge_blast": ["Carga al esquivar", "num", "", false], "dodge_charges": ["Esquives seguidos", "int", "", false],
	"proj_count_add": ["Proyectiles extra", "int", "", false], "pierce_add": ["Atraviesan", "int", "", false],
	"rerolls": ["Cambios de opciones", "int", "", false], "ankh": ["Levantarse al caer", "int", "", false],
	"nodens_level": ["Nodens", "int", "", false],
}
## Estadísticas de un arma: [nombre, formato, unidad, menos es mejor].
const WEAPON := {
	"damage": ["Daño por golpe", "num", "", false], "count": ["Cantidad", "int", "", false],
	"cooldown": ["Recarga", "num", " s", true], "range": ["Alcance", "num", " m", false],
	"aoe_radius": ["Área", "num", " m", false], "zone_radius": ["Área de la zona", "num", " m", false],
	"zone_dps": ["Daño de la zona", "num", "/s", false], "zone_time": ["Duración de la zona", "num", " s", false],
	"duration": ["Duración", "num", " s", false], "stun": ["Aturde", "num", " s", false],
	"pierce": ["Atraviesa", "int", "", false], "projectile_speed": ["Velocidad", "num", "", false],
	"knockback": ["Empuje", "num", "", false], "sanity_cost": ["Cordura por disparo", "num", "", true],
	"curse_dps": ["Daño de la maldición", "num", "/s", false], "split_count": ["Chispas", "int", "", false],
	"crit_chance": ["Crítico", "pct", "", false], "lure": ["Atrae", "num", " s", false],
	"hit_interval": ["Cada", "num", " s", true], "spread_deg": ["Abertura", "int", "°", false],
	"root": ["Atrapa", "num", " s", false], "stasis": ["Estasis", "num", " s", false],
	"vulnerable": ["Vulnerables", "num", " s", false], "length": ["Largo", "num", " m", false],
	"width": ["Ancho", "num", " m", false], "burst_delay": ["Entre disparos", "num", " s", true],
}
## Potenciadores de la tienda (`Shop.DEFAULTS`): los que van en fracción de daño evitado o
## sumada; los de 1,0 son factores; los demás, cuentas.
const SHOP_PCT := ["guard", "ward", "haste", "crit"]
const EVO_KEYS := ["damage", "count", "cooldown", "range", "aoe_radius", "zone_dps", "stun", "pierce", "duration"]

## Lo que cambia con una opción de la subida.
static func option(p: Player, o: PlayerProgress.Option) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if p == null or o == null: return out
	match o.kind:
		PlayerProgress.Option.Kind.PASSIVE:
			if o.to_level == 1 and p.progress != null:
				var n := 0
				for id in p.progress.passives:
					if int(p.progress.passives[id]) > 0: n += 1
				out.append(_row("Objetos", "%d" % n, "%d de %d" % [n + 1, p.progress.item_slots], true))
			out.append_array(upgrade(p.data, o.upgrade))
		PlayerProgress.Option.Kind.NEW_WEAPON:
			var have := p.weapons.weapons.size() if p.weapons != null else 0
			out.append(_row("Armas", "%d" % have, "%d de %d" % [have + 1, p.progress.weapon_slots if p.progress else 4], true))
		PlayerProgress.Option.Kind.WEAPON_LEVEL:
			var w: WeaponSystem.Weapon = p.weapons.get_weapon(o.weapon.id) if p.weapons != null else null
			if w != null: out.append_array(weapon_level(p, w.data, w.level, o.to_level))
		PlayerProgress.Option.Kind.EVOLUTION:
			var w: WeaponSystem.Weapon = p.weapons.get_weapon(o.from.id) if p.weapons != null and o.from != null else null
			if w != null: out.append_array(evolution(p, w.data, w.level, o.weapon))
	return out

## Un nivel más de un objeto sobre las estadísticas actuales.
static func upgrade(d: CharacterData, up: UpgradeData) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if d == null or up == null: return out
	if up.stat != "" and STATS.has(up.stat):
		var v := float(d.get(up.stat))
		out.append(_stat(STATS[up.stat], v, v * up.multiply + up.add))
	for key: String in up.also:
		var s := key.trim_suffix("*").trim_suffix("+")
		if not STATS.has(s): continue
		var v := float(d.get(s))
		out.append(_stat(STATS[s], v, v * float(up.also[key]) if key.ends_with("*") else v + float(up.also[key])))
	return out

## Lo que da el siguiente nivel de un potenciador de la tienda: [{name: "Ahora", before, after}].
static func shop(save: SaveData, e: Shop.Entry) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if e == null or e.item == null or not Shop.DEFAULTS.has(e.item.stat) or Shop.is_maxed(save, e): return out
	var now := float(Shop.bonuses(save).get(e.item.stat, Shop.DEFAULTS[e.item.stat]))
	var nxt := now + e.item.per_level
	var kind := "pct" if e.item.stat in SHOP_PCT else ("mult" if float(Shop.DEFAULTS[e.item.stat]) == 1.0 else ("num" if e.item.stat == "regen" else "int"))
	var unit := "/s" if e.item.stat == "regen" else ""
	out.append(_row("Ahora", fmt(now, kind) + unit, fmt(nxt, kind) + unit, true))
	return out

## Lo que cambia en un arma al pasar de `from_lv` a `to_lv` (las estadísticas de su mejora).
static func weapon_level(p: Player, wd: WeaponData, from_lv: int, to_lv: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var i := to_lv - 2
	if i < 0 or i >= wd.level_mods.size(): return out
	var seen := {}
	for key: String in wd.level_mods[i]:
		var s := key.trim_suffix("*").trim_suffix("+").trim_suffix("=")
		if seen.has(s) or not WEAPON.has(s): continue
		seen[s] = true
		out.append(_stat(WEAPON[s], _wstat(p, wd, s, from_lv), _wstat(p, wd, s, to_lv)))
	return out

## El arma que lleva frente a su evolución.
static func evolution(p: Player, wd: WeaponData, lv: int, evo: WeaponData) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s: String in EVO_KEYS:
		var a := _wstat(p, wd, s, lv)
		var b := _wstat(p, evo, s, 1)
		if absf(a - b) > 0.001 and (a > 0.0 or b > 0.0): out.append(_stat(WEAPON[s], a, b))
	return out

static func _wstat(p: Player, wd: WeaponData, s: String, lv: int) -> float:
	var v := WeaponSystem.with_items(wd, s, wd.stat(s, lv), p.data if p != null else null)
	if s in ["damage", "zone_dps", "curse_dps"] and p != null: v *= p.damage_mult(wd.category)
	return v

static func _stat(info: Array, a: float, b: float) -> Dictionary:
	var better := b < a if bool(info[3]) else b > a
	return _row(String(info[0]), fmt(a, String(info[1])) + String(info[2]), fmt(b, String(info[1])) + String(info[2]), better)

static func _row(name: String, before: String, after: String, good: bool) -> Dictionary:
	return {"name": name, "before": before, "after": after, "good": good}

## Un valor con su formato, con coma decimal.
static func fmt(v: float, kind: String) -> String:
	match kind:
		"mult":
			var pc := roundi((v - 1.0) * 100.0)
			return ("+%d %%" % pc) if pc >= 0 else ("−%d %%" % -pc)
		"pct": return "%d %%" % roundi(v * 100.0)
		"int": return str(roundi(v))
	if absf(v - roundf(v)) < 0.005: return str(roundi(v))
	var t := ("%.2f" % v).rstrip("0").rstrip(".")
	return t.replace(".", ",")

## Las filas en una línea para un RichTextLabel: «Velocidad 4,5 → [verde]4,86 m/s[/verde]».
static func bbcode(rows: Array[Dictionary], sep := "    ") -> String:
	var parts := PackedStringArray()
	for r: Dictionary in rows:
		var c: Color = GOOD if r.good else BAD
		parts.append(_nobreak("%s %s → [color=#%s]%s[/color]" % [r.name, r.before, c.to_html(false), r.after]))
	return sep.join(parts)

## Una estadística no se parte entre dos líneas: se rompe solo entre una y otra (05-11-2026: «15,12/»
## quedaba al final de una línea y la «s» al principio de la siguiente).
static func _nobreak(s: String) -> String:
	var out := ""
	var tag := false
	for ch in s:
		if ch == "[": tag = true
		elif ch == "]": tag = false
		if not tag and ch == " ": out += char(0xA0)          # espacio que no rompe
		elif not tag and ch == "/": out += "/" + char(0x2060)   # y la «/» unida a lo que sigue
		else: out += ch
	return out
