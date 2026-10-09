extends SceneTree
## Evoluciones de las armas (D-06, segunda tanda, 09-10-2026): una por cada arma que aún no
## tenía, cada una con su objeto. Parte del arma a nivel 5, le aplica su cambio (EVO.mods:
## "x*" multiplica, "x+" suma, "x=" fija) y escala el daño (damage, zone_dps, curse_dps) para
## que rinda EVO_DPS veces el nivel 5 según DamageRules. Escribe data/weapons/<evo>.tres, enlaza
## el arma base (evolves_with, evolution) y deja la nota de la Biblioteca.
##   godot --headless --path . -s tools/gen_evoluciones.gd

const EVO_DPS := 1.4
const DAMAGE_KEYS := ["damage", "zone_dps", "curse_dps"]

# arma base: [id evolución, nombre, objeto, descripción, cambios, nota de la Biblioteca]
const EVO := {
	"arpon": ["arpon_nantucket", "Arpón de Nantucket", "plomada", "Dos arpones lastrados que atraviesan a todos los de la línea y los arrastran.",
		{"count+": 1, "spread_deg+": 10.0, "pierce=": 99, "knockback*": 1.6},
		"El arpón de un ballenero de Nantucket que volvió del Pacífico sin barco y sin tripulación. Pesa como un ancla y no suelta lo que atrapa."],
	"bengalas": ["bengala_faro", "Bengala del faro", "capa", "Una bengala enorme que atrae a los enemigos el doble de tiempo y prende el suelo.",
		{"lure*": 2.0, "aoe_radius*": 1.3, "zone=": 1, "zone_radius=": 2.0, "zone_time=": 4.0, "zone_dps=": 6.0},
		"La luz del viejo faro de Kingsport, metida en un cartucho. Ninguna criatura de la costa se resiste a mirarla."],
	"bumeran": ["bumeran_hueso", "Bumerán de hueso", "esquis", "Tres bumeranes de hueso tallado que van más lejos y más deprisa.",
		{"count+": 2, "spread_deg+": 30.0, "range*": 1.25, "projectile_speed*": 1.25},
		"Tallado en un hueso que no es de ningún animal conocido. Vuelve siempre, y a veces trae algo consigo."],
	"corredera": ["escopeta_trinchera", "Escopeta de trinchera", "bandolera", "Un anillo de perdigones el doble de denso que barre todo alrededor y empuja más.",
		{"count*": 1.8, "knockback*": 1.4, "cooldown*": 0.85},
		"Escopeta de trinchera de la Gran Guerra con la bandolera llena. En un pasillo estrecho no hay nada que se le acerque."],
	"daga": ["daga_sacrificio", "Daga del sacrificio", "colmillo", "La maldición dura más, quema más y salta a cuatro enemigos al morir el maldito.",
		{"curse*": 1.5, "curse_spread+": 3, "range*": 1.2},
		"La hoja ondulada con que la Orden degollaba en las noches de luna. El colmillo de ghoul del pomo tiene hambre propia."],
	"estoque": ["estoque_duelista", "Estoque del duelista", "piedra_afilar", "Estocada más larga y más fina que atraviesa toda la línea dos veces más rápido.",
		{"range*": 1.4, "cooldown*": 0.6, "projectile_radius*": 1.2},
		"El bastón de un caballero de Providence que se batía en duelo con algo que no vemos. La hoja, afilada hasta ver a través de ella."],
	"farolero": ["linterna_fatuos", "Linterna de los fatuos", "pipa", "El doble de fuegos fatuos, que buscan a sus presas con más ganas.",
		{"count*": 2.0, "homing*": 1.6, "range*": 1.2},
		"El báculo del farolero, encendido con la pipa de espuma. Los fuegos que salen ya no zigzaguean: cazan."],
	"flammenwerfer": ["aliento_moloch", "Aliento de Moloch", "fosforos", "Un chorro más largo y más ancho que deja fuego en el suelo durante más tiempo.",
		{"range*": 1.35, "spread_deg*": 1.4, "zone_time*": 1.6, "zone_radius*": 1.3},
		"El lanzallamas cebado con los fósforos de Cthugha. Su fuego no es del todo de este mundo, y tarda en apagarse."],
	"formula": ["exorcismo_mayor", "Exorcismo mayor", "signo_primigenio", "Una onda mayor que empuja más lejos y aturde el doble.",
		{"aoe_radius*": 1.4, "stun*": 2.0, "knockback*": 1.5},
		"La fórmula completa, dicha con el Signo Primigenio en la mano. Lo que no es de este mundo tiene que retroceder."],
	"fuegos": ["castillo_fuegos", "Gran castillo de fuegos", "petardos", "Tres cohetes por disparo que se abren en el doble de chispas.",
		{"count+": 2, "spread_deg+": 30.0, "split_count*": 2.0},
		"Todo el castillo de la fiesta de Kingsport en un solo cañón. Desde el puerto se ve como un amanecer."],
	"lanzaquimicos": ["botica_arkham", "Botica de Arkham", "laudano", "Dos frascos por disparo; charcos más grandes que dejan vulnerables más tiempo.",
		{"count+": 1, "zone_radius*": 1.4, "vulnerable*": 1.6},
		"Lo peor del dispensario de Arkham mezclado en el mismo frasco. El láudano no es para calmar a nadie."],
	"lente": ["ojo_eter", "Ojo del Éter", "catalejo", "Un rayo más largo cuyo daño crece más deprisa y hasta más arriba.",
		{"range*": 1.4, "ramp*": 1.6, "ramp_max*": 1.4},
		"La lente encajada en el catalejo del Alert. Por ella se ve el éter, y lo que vive en él nos ve a nosotros."],
	"lewis": ["nido_ametralladoras", "Nido de ametralladoras", "manual_tiro", "Torretas que duran el doble y disparan más rápido.",
		{"duration*": 2.0, "hit_interval*": 0.7, "range*": 1.2},
		"Montada según el manual, con sacos y cargadores de sobra. Aguanta lo que le echen hasta que se le acabe la munición, y no se le acaba."],
	"lugers": ["lugers_as", "Lugers del as", "gafas", "Tres balas por cañón, delante y detrás, más deprisa.",
		{"count+": 2, "spread_deg+": 16.0, "cooldown*": 0.8},
		"Las pistolas de un as de la aviación alemana que se estrelló en la Antártida. Con sus gafas, no falla ni volando del revés."],
	"machete": ["machete_canaveral", "Machete del cañaveral", "guantes", "Un tajo mucho más amplio que empuja más y golpea más a menudo.",
		{"aoe_radius*": 1.4, "knockback*": 1.5, "cooldown*": 0.8},
		"El machete de los cañaverales de Luisiana, con guantes de estibador para no soltarlo. Corta caña, cuerda y lo que haga falta."],
	"martillo": ["martillo_barrera", "Martillo de la Barrera", "crampones", "Una grieta más larga y más ancha que aturde más tiempo.",
		{"range*": 1.5, "aoe_radius*": 1.4, "stun*": 1.6},
		"Con los crampones bien clavados, un golpe de este martillo abre la Barrera de Ross de punta a punta."],
	"mauser": ["mauser_tillinghast", "Mauser de Tillinghast", "reloj", "Ráfagas más largas y más seguidas.",
		{"count+": 3, "cooldown*": 0.75},
		"Una Mauser que Tillinghast trucó con piezas de su máquina. Dispara antes de que se apriete el gatillo."],
	"migo": ["enjambre_yuggoth", "Enjambre de Yuggoth", "cristal", "Cuatro orbes más que vuelan alrededor más tiempo.",
		{"count+": 4, "duration*": 1.3},
		"Los orbes encontraron el cristal de Ithaqua y se multiplicaron con el frío. Zumban como un enjambre venido de Yuggoth."],
	"molotov": ["coctel_emma", "Cóctel del Emma", "petaca", "Dos botellas que dejan charcos de fuego más grandes y duraderos.",
		{"count+": 1, "zone_radius*": 1.35, "zone_time*": 1.5},
		"El ron de la goleta Emma arde mejor de lo que se bebe. Johansen lo descubrió una noche de tormenta."],
	"necronomicon": ["necronomicon_completo", "Necronomicón completo", "manuscritos", "El doble de páginas girando en un círculo mayor.",
		{"count*": 2.0, "aoe_radius*": 1.3, "duration*": 1.2},
		"Con los manuscritos pnakóticos cosidos entre sus hojas, el Necronomicón está por fin completo. No debería estarlo."],
	"polvo": ["polvo_antiguos", "Polvo de los Antiguos", "mapa_leng", "Una nube mucho mayor que frena y debilita más.",
		{"zone_radius*": 1.5, "zone_time*": 1.4, "slow_factor*": 0.7, "weaken*": 0.8},
		"La receta de Ibn-Ghazi, con un ingrediente que solo se encuentra en la meseta de Leng. Lo que respira el polvo ve lo que no debe."],
	"red": ["red_innsmouth", "Red de Innsmouth", "escamas", "Una red más grande que inmoviliza el doble de tiempo.",
		{"aoe_radius*": 1.4, "root*": 2.0},
		"Red de los pescadores de Innsmouth, tejida con algo más que cáñamo. Lo que cae en ella no se suelta solo."],
	"resonador": ["gran_resonador", "Gran resonador", "nodens", "Una onda mayor que deshace las balas más lejos y más a menudo.",
		{"aoe_radius*": 1.5, "cooldown*": 0.75},
		"El resonador de Tillinghast con la concha de Nodens en el lugar de la válvula. Ahora sí se oye la música de las esferas."],
	"signo": ["signo_mayor", "Signo Mayor", "escapulario", "Un signo mucho mayor que frena aún más las balas enemigas.",
		{"aoe_radius*": 1.5, "bullet_slow*": 0.6, "duration*": 1.3},
		"El Signo Arcano trazado con la tinta bendita del escapulario. Las cosas de fuera tardan en cruzarlo."],
	"springfield": ["springfield_francotirador", "Springfield del francotirador", "ojo_pickman", "Críticos más probables y de cuádruple daño que atraviesan a tres enemigos.",
		{"crit_chance+": 0.25, "crit_mult=": 4.0, "pierce+": 3},
		"Con el ojo de Pickman en la mira, el tirador ve el punto débil de cualquier cosa. Y lo que ve, cae."],
	"tesla": ["bobina_nikola", "Bobina de Nikola", "vara", "El rayo salta al doble de enemigos y más lejos.",
		{"count*": 2.0, "aoe_radius*": 1.4},
		"La vara de zahorí hace de antena: la bobina encuentra a cada criatura de la zona y les manda la tormenta."],
	"thompson": ["thompson_chicago", "Thompson de Chicago", "oro_obed", "Tambor de cien balas: muchas más por ráfaga.",
		{"count*": 1.8, "spread_deg*": 1.3},
		"Comprada con el oro de Obed Marsh a unos señores de Chicago que no hacían preguntas. Ellos tampoco las hacían con la Thompson."],
	"trapezoedro": ["trapezoedro_despierto", "Trapezoedro despierto", "idolo", "Un rayo más largo y el doble de ancho.",
		{"range*": 1.3, "projectile_radius*": 2.0},
		"Puesto junto al ídolo, el trapezoedro despertó. Su luz roja ya no muestra lo que hay en la caja: lo que hay en la caja mira."],
	"west": ["reactivo_perfecto", "Reactivo perfeccionado", "botiquin", "El suero atraviesa y los inyectados se levantan el doble de tiempo.",
		{"ally_time*": 2.0, "pierce+": 2, "cooldown*": 0.8},
		"La fórmula final de Herbert West. Funciona, por fin. Eso es lo que da miedo."],
	"yith": ["rayo_gran_raza", "Rayo de la Gran Raza", "clepsidra", "Una estasis más larga y el rayo atraviesa a tres enemigos.",
		{"stasis*": 1.6, "pierce+": 3},
		"El arma de la Gran Raza afinada con su propia clepsidra. Lo que alcanza se queda fuera del tiempo, y paga al volver."],
	"recortada": ["recortada_contrabandista", "Recortada del contrabandista", "diente", "Tres disparos seguidos con más perdigones y más empuje.",
		{"volleys+": 1, "count+": 3, "knockback*": 1.4},
		"La recortada del contrabandista de Kingsport al que encontraron vivo dentro de un shoggoth. Dicen que la usó desde dentro."],
	"antitanque": ["canon_antitanque", "Cañón antitanque", "medallon", "Un disparo aún más pesado que derriba a los grandes.",
		{"knockback*": 2.0, "projectile_radius*": 1.5, "cooldown*": 0.8},
		"Ya no es un fusil: es un cañón que alguien lleva al hombro. Las élites lo oyen llegar y no les sirve de nada."],
	"mortero": ["bateria_morteros", "Batería de morteros", "polvora", "Tres proyectiles por disparo con explosiones mayores.",
		{"count+": 2, "aoe_radius*": 1.2},
		"Tres tubos atados y la pólvora de Ponape. La ciudad ciclópea no ha oído nada parecido en un millón de años."],
	"bar": ["bar_asalto", "BAR de asalto", "velocidad", "Más balas por ráfaga que rebotan tres veces más.",
		{"bounces+": 3, "count+": 2},
		"El fusil ametrallador del sargento Elwood en el Argonne. Las balas buscan solas a la siguiente criatura."],
	"nagant": ["nagant_vigia", "Nagant del vigía", "lupa", "Su cadencia llega a cuatro veces la inicial y acelera antes.",
		{"spinup=": 4.0, "spinup_time*": 0.6},
		"Danforth no ha dejado de vigilar desde lo que vio sobre las montañas. Su revólver tampoco descansa."],
	"ancla": ["ancla_johansen", "Ancla de Johansen", "coraza", "Dos anclas más grandes y pesadas que giran más lejos.",
		{"count+": 1, "aoe_radius*": 1.25, "projectile_radius*": 1.4, "knockback*": 1.4},
		"Las dos anclas del Alert, encadenadas a un hombre que embistió a Cthulhu con un barco. Nada se le acerca."],
	"gas": ["gas_mostaza", "Gas mostaza", "elixir", "Una nube mayor y más duradera que avanza más deprisa.",
		{"zone_radius*": 1.4, "zone_time*": 1.4, "drift*": 1.5},
		"Mezclado con el elixir de Curwen, el gas cambia de color y de intención. Lo que lo respira no vuelve a ser lo que era."],
	"latigo": ["latigo_domador", "Látigo del domador", "silbato", "Un latigazo más largo que barre todo alrededor.",
		{"range*": 1.35, "spread_deg=": 300.0},
		"Con el silbato en los labios, el látigo silba también. El domador de un circo de Arkham lo usaba con fieras que no eran de este mundo."],
	"cepos": ["cepos_cazador", "Cepos del cazador", "collar", "El doble de cepos que atrapan más tiempo.",
		{"count*": 2.0, "root*": 1.5},
		"Los cepos del cazador de Profundos, con colmillos en lugar de dientes de hierro. Muerden a los suyos."],
	"ballesta": ["ballesta_fortuna", "Ballesta de la fortuna", "dado", "Tres virotes con mucha probabilidad de crítico.",
		{"count+": 2, "spread_deg+": 14.0, "crit_chance+": 0.3},
		"Una ballesta con un dado de hueso engastado en la culata. El tirador dice que no apunta: deja que el dado decida."],
	"cthugha": ["llama_culto", "Llama del culto", "talisman", "Una bola de fuego mayor con un rastro que arde mucho más.",
		{"projectile_radius*": 1.5, "zone_time*": 1.8, "zone_radius*": 1.3},
		"El talismán de la Orden aviva la llama. Cthugha responde, y su fuego ya no se apaga."],
	"ithaqua": ["wendigo", "Aliento del Wendigo", "pemmican", "Un viento helado más largo y ancho que congela antes.",
		{"range*": 1.35, "spread_deg*": 1.5, "duration*": 1.4},
		"Los tramperos lo llaman Wendigo y dejan pemmican en la nieve para que pase de largo. El aliento se queda."],
	"yog": ["puerta_yog", "La Puerta y la Llave", "llave", "Una esfera mayor que atrae con mucha más fuerza y dura más.",
		{"aoe_radius*": 1.4, "pull*": 1.8, "duration*": 1.4},
		"Yog-Sothoth es la puerta, Yog-Sothoth es la llave. Con la llave de plata, la esfera se abre del todo."],
	"shub": ["mil_crias", "Las Mil Crías", "tablilla", "El doble de tentáculos, más grandes, que aturden más.",
		{"count*": 2.0, "aoe_radius*": 1.3, "stun*": 1.5},
		"La tablilla de Eltdown nombra a las Mil Crías una a una. Cada nombre leído es un tentáculo más que brota."],
	"signo_amarillo": ["rey_amarillo", "El Rey de Amarillo", "salterio", "Enloquece al doble de enemigos durante más tiempo.",
		{"count*": 2.0, "duration*": 1.5, "range*": 1.3},
		"Al leer el salterio al revés aparece el segundo acto. Quien lo ve se pone la máscara, y la máscara no se quita."],
	"lampara": ["lampara_alhazred", "Lámpara del Árabe Loco", "ankh", "Dos haces de luz que giran más deprisa y más lejos.",
		{"count=": 2, "range*": 1.25, "projectile_speed*": 1.3},
		"La lámpara de Abdul Alhazred, avivada con el ankh de Nephren-Ka. Su luz recorre los desiertos de dos en dos."],
}

func _init() -> void:
	var notes := {}
	for base_id: String in EVO:
		var e: Array = EVO[base_id]
		var base: WeaponData = load("res://data/weapons/%s.tres" % base_id)
		var lv5 := _at_level(base, base.max_level)
		var evo := lv5.duplicate() as WeaponData
		evo.id = StringName(e[0]); evo.display_name = e[1]; evo.description = e[3]
		evo.evolved = true; evo.max_level = 1
		evo.level_mods = []; evo.level_text = []
		evo.evolves_with = &""; evo.evolution = &""
		evo.icon = null
		for k: String in e[4]:
			var stat := k.left(-1)
			var v: float = float(e[4][k])
			match k.right(1):
				"*": evo.set(stat, float(evo.get(stat)) * v)
				"+": evo.set(stat, float(evo.get(stat)) + v)
				"=": evo.set(stat, v)
		var want := DamageRules.dps(lv5) * EVO_DPS
		var now := DamageRules.dps(evo)
		if now > 0.0:
			var kk := want / now
			for d in DAMAGE_KEYS: evo.set(d, snappedf(float(evo.get(d)) * kk, 0.1))
		ResourceSaver.save(evo, "res://data/weapons/%s.tres" % e[0])
		_link(base_id, e[2], e[0])
		notes[e[0]] = e[5]
		print("%-26s %-14s dps nivel 5 %.1f -> %.1f" % [e[0], e[2], DamageRules.dps(lv5), DamageRules.dps(evo)])
	_notes(notes)
	quit()

## Copia del arma con las estadísticas de un nivel ya aplicadas.
func _at_level(w: WeaponData, level: int) -> WeaponData:
	var c := w.duplicate() as WeaponData
	for p in w.get_property_list():
		if not (p.usage & PROPERTY_USAGE_STORAGE): continue
		if p.type == TYPE_FLOAT: c.set(p.name, w.stat(p.name, level))
	return c

## evolves_with y evolution en el .tres del arma base, sin reescribir el resto del fichero.
func _link(base_id: String, item: String, evo_id: String) -> void:
	var path := "res://data/weapons/%s.tres" % base_id
	var lines := Array(FileAccess.get_file_as_string(path).split("\n"))
	lines = lines.filter(func(l: String) -> bool: return not (l.begins_with("evolves_with") or l.begins_with("evolution")))
	var at := lines.find("max_level = 5")
	if at < 0: at = lines.size() - 1
	lines.insert(at, 'evolution = &"%s"' % evo_id)
	lines.insert(at, 'evolves_with = &"%s"' % item)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("\n".join(lines))

func _notes(notes: Dictionary) -> void:
	var path := "res://data/library/textos.json"
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	for k in notes: d["weapons"][k] = notes[k]
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(d, "\t", false) + "\n")
