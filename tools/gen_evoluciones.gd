extends SceneTree
## Evoluciones de las armas (D-06, segunda tanda, 09-10-2026; segunda rama, hito 16.8): una por cada arma que aún no
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

# Segunda rama (hito 16.8, 03-11-2026): al abrir el baúl se elige entre la evolución de EVO
# (o la de la primera tanda, hecha a mano) y esta, con el mismo objeto. Cada una va por otro
# camino que la primera (si la primera da más proyectiles, esta da menos y más pesados...).
# arma base: [id, nombre, descripción, cambios, nota de la Biblioteca]
const EVO_B := {
	"arpon": ["lanza_bomba", "Lanza bomba", "Un arpón con carga en la punta: al clavarse revienta en metralla y frena a los que alcanza.",
		{"split_count+": 8, "root+": 0.8, "cooldown*": 0.75},
		"La lanza bomba de los balleneros, con una carga de pólvora en la punta. Los de Nantucket la cebaban con algo más que pólvora."],
	"bengalas": ["bengala_magnesio", "Bengala de magnesio", "Tres bengalas que atraen menos tiempo, pero su fogonazo deja clavados a los que se acercan.",
		{"count+": 2, "lure*": 0.6, "root=": 1.5, "cooldown*": 0.85},
		"Magnesio de los fotógrafos de la expedición, apretado en cartuchos. Lo que lo mira de cerca se queda quieto, y no siempre por la luz."],
	"bisturis": ["bisturi_anatomista", "Bisturí del anatomista", "Dos hojas finísimas que atraviesan y buscan el punto débil: muchos críticos de triple daño.",
		{"count=": 2, "spread_deg=": 6.0, "crit_chance+": 0.35, "crit_mult=": 3.0, "pierce+": 2, "projectile_speed*": 1.3},
		"Los bisturís de un anatomista de Arkham que diseccionó cuerpos que no debían existir. Sabe exactamente dónde cortar."],
	"bumeran": ["bumeran_guerra", "Bumerán de guerra", "Un solo bumerán enorme y más lento que arrolla y empuja a todo lo que cruza.",
		{"projectile_radius*": 2.2, "knockback*": 2.5, "projectile_speed*": 0.8},
		"Un bumerán de guerra del desierto occidental, del tamaño de un remo. Los antiguos lo usaban contra lo que salía de debajo de la arena."],
	"corredera": ["escopeta_postas", "Escopeta de postas", "Cinco postas en un cono cerrado que llegan el doble de lejos y atraviesan.",
		{"count=": 5, "spread_deg=": 18.0, "range*": 1.8, "pierce+": 2, "projectile_speed*": 1.4},
		"Cargada con postas de cazar osos. En la Antártida no había osos, pero lo que había agradeció el cambio."],
	"daga": ["daga_obsidiana", "Daga de obsidiana", "Puñaladas el doble de seguidas y desde más lejos; la maldición, breve y sin saltar.",
		{"cooldown*": 0.5, "curse_spread=": 0, "curse*": 0.6, "range*": 1.3},
		"Obsidiana del Yucatán tallada por un sacerdote sin rostro. Corta antes de tocar."],
	"estoque": ["sable_husar", "Sable del húsar", "Una estocada ancha y pesada que echa atrás a toda la línea.",
		{"projectile_radius*": 2.2, "knockback*": 3.0, "cooldown*": 1.2},
		"El sable de un húsar que cargó contra algo en los bosques de Galitzia en 1916 y volvió solo. No se para a esquivar."],
	"farolero": ["fuego_santelmo", "Fuego de San Telmo", "Un fuego fatuo enorme que atraviesa a tres y, al apagarse, se parte en seis.",
		{"count=": 1, "projectile_radius*": 2.0, "projectile_size*": 2.0, "split_count+": 6, "pierce+": 3},
		"El fuego que se posa en los mástiles antes de la tormenta. El farolero lo atrapó una noche en el Alert y no lo ha soltado."],
	"flammenwerfer": ["lanza_termica", "Lanza térmica", "Un chorro estrecho y larguísimo que se recarga antes; deja menos fuego en el suelo.",
		{"spread_deg*": 0.45, "range*": 1.7, "cooldown*": 0.7, "zone_time*": 0.5},
		"Una lanza de oxígeno de los astilleros de Kiel montada en el Flammenwerfer. Corta acero, y lo que no es acero también."],
	"formula": ["letania", "Letanía de expulsión", "Una onda algo menor, más del doble de seguida y a mitad de cordura.",
		{"cooldown*": 0.45, "aoe_radius*": 0.8, "knockback*": 0.6, "sanity_cost*": 0.5},
		"La fórmula recitada sin pausa, como una letanía. Cada palabra es una onda; el sacerdote ya no recuerda cuándo empezó."],
	"fuegos": ["cohete_feria", "Cohete de la feria", "Un solo cohete grande que atraviesa a cuatro y estalla en una lluvia de chispas.",
		{"count=": 1, "pierce+": 4, "split_count*": 2.5, "projectile_radius*": 1.6, "projectile_size*": 1.6},
		"El cohete que cerraba la feria de Arkham, el que nadie se atrevía a encender. Arde en verde, y no por el cobre."],
	"granada": ["racimo_granadas", "Racimo de granadas", "Cinco granadas pequeñas repartidas por el grupo, más a menudo.",
		{"count+": 3, "aoe_radius*": 0.7, "cooldown*": 0.8},
		"Un cinto entero de granadas de huevo de la Gran Guerra. Se lanzan a puñados."],
	"lanzaquimicos": ["agua_regia", "Agua regia", "Frascos más seguidos de un ácido concentrado: charcos pequeños que dejan vulnerables el doble.",
		{"zone_radius*": 0.7, "zone_time*": 0.7, "cooldown*": 0.6, "vulnerable*": 2.0},
		"Lo que disuelve el oro. En el laboratorio de la Miskatonic descubrieron que también disuelve lo que no es de este mundo."],
	"lente": ["prisma_eter", "Prisma del Éter", "Un rayo sin espera: hace todo su daño desde el primer instante y vuelve antes.",
		{"ramp=": 0.0, "ramp_max=": 1.0, "cooldown*": 0.6},
		"La lente tallada en prisma descompone la luz del éter. Ya no tiene que mirar fijamente: lo ve todo de golpe."],
	"lewis": ["puestos_tiro", "Puestos de tiro", "Torretas mucho más a menudo y de más alcance, que duran menos.",
		{"cooldown*": 0.45, "duration*": 0.6, "range*": 1.4},
		"Una Lewis en cada esquina, como en las trincheras de Flandes. Se montan, se vacían y se dejan atrás."],
	"lugers": ["lugers_feria", "Lugers de feria", "Cada bala rebota en otros dos enemigos.",
		{"bounces+": 2, "cooldown*": 0.85},
		"Las pistolas del tirador de una barraca de feria de Kingsport. Nunca necesitó apuntar a dos sitios: las balas se buscan solas."],
	"machete": ["machetes_zafra", "Machetes de zafra", "Tajos el doble de seguidos, que apenas empujan: no dejan respirar.",
		{"cooldown*": 0.5, "aoe_radius*": 0.9, "knockback*": 0.6},
		"Dos machetes de la zafra de Luisiana, uno en cada mano. Los cortadores no paran hasta que no queda caña en pie."],
	"martillo": ["piolet_pabodie", "Piolet de Pabodie", "Grietas más cortas y rapidísimas, el doble de seguidas.",
		{"cooldown*": 0.5, "range*": 0.7, "projectile_speed*": 1.6},
		"El piolet del ingeniero Pabodie, el de las perforadoras de la expedición. Abre el hielo a golpes cortos, sin descanso."],
	"mauser": ["carabina_mauser", "Carabina Mauser", "Con la culata puesta: un solo disparo que llega lejos y atraviesa a cinco.",
		{"count=": 1, "pierce+": 4, "range*": 1.5, "projectile_speed*": 1.4, "cooldown*": 0.6},
		"La funda de madera de la C96 encajada como culata. Así deja de ser una pistola y se convierte en algo que no falla a cien metros."],
	"migo": ["cilindro_migo", "Cilindro de los Mi-Go", "Orbes que disparan el doble de rápido en una órbita más amplia.",
		{"hit_interval*": 0.5, "aoe_radius*": 1.4},
		"Los Mi-Go guardan cerebros vivos en cilindros de metal. Este dispara por su cuenta, y con prisa."],
	"molotov": ["bomba_queroseno", "Bomba de queroseno", "Revienta al caer y deja un fuego más breve.",
		{"aoe_radius=": 2.5, "damage=": 20.0, "zone_time*": 0.6},
		"Queroseno de las lámparas del faro y una mecha corta. Primero el golpe, después el fuego."],
	"necronomicon": ["al_azif", "Al Azif", "Dos páginas enormes que giran muy deprisa.",
		{"count=": 2, "projectile_speed*": 1.6, "projectile_radius*": 1.6},
		"El original árabe: Al Azif, el zumbido de los insectos de la noche que los antiguos tomaban por el aullido de los demonios. Sus páginas cortan."],
	"palanca": ["rifle_caza_mayor", "Rifle de caza mayor", "Un disparo pesado que deja clavados y echa atrás a los que atraviesa.",
		{"count=": 1, "root+": 0.8, "knockback*": 2.0, "cooldown*": 0.85},
		"Calibre para elefantes, encargado en Londres por un cazador que volvió del Congo hablando de otra cosa. Lo que alcanza no da un paso más."],
	"polvo": ["polvo_schacabao", "Polvo de Ibn Schacabao", "Una nube que apenas frena, pero deja vulnerables a los que la respiran y hace más daño.",
		{"vulnerable=": 3.0, "zone_dps*": 3.0, "slow_factor=": 0.85, "cooldown*": 0.8},
		"Según Ibn Schacabao, dichosa la tumba donde no yace ningún mago. Su polvo es para que los demás no lo sean."],
	"red": ["redes_arrastre", "Redes de arrastre", "Tres redes más pequeñas a la vez.",
		{"count+": 2, "aoe_radius*": 0.75, "cooldown*": 0.8},
		"Las redes de arrastre de los pesqueros de Innsmouth, que salen de noche hacia el arrecife del Diablo. Vuelven siempre llenas."],
	"resonador": ["resonador_crawford", "Resonador de Crawford", "Una onda que golpea más fuerte y lanza el triple de lejos lo que alcanza, algo menos seguida.",
		{"damage*": 3.0, "knockback*": 3.0, "cooldown*": 1.2},
		"El primer prototipo de Crawford Tillinghast, sin el regulador que puso después. Lo que suena ya no se oye: se nota en los huesos."],
	"signo": ["signo_koth", "Signo de Koth", "Un signo algo menor y mucho más seguido que empuja con fuerza hacia fuera.",
		{"cooldown*": 0.6, "aoe_radius*": 0.85, "knockback*": 2.5},
		"El signo grabado en la torre de los gugs, en el mundo de los sueños. Lo que lo ve se aparta sin saber por qué."],
	"springfield": ["springfield_belleau", "Springfield de Belleau", "Dispara más del doble de seguido y atraviesa a uno más; menos críticos.",
		{"cooldown*": 0.45, "crit_chance*": 0.5, "pierce+": 1},
		"El fusil de un marine del bosque de Belleau, en 1918. Allí no había tiempo para apuntar dos veces."],
	"tesla": ["rayo_wardenclyffe", "Rayo de Wardenclyffe", "Salta a la mitad de enemigos, pero los deja aturdidos casi un segundo.",
		{"count*": 0.5, "stun*": 6.0, "aoe_radius*": 1.2},
		"La torre de Wardenclyffe iba a mandar la electricidad por el aire a todo el mundo. La bobina recuerda cómo."],
	"thompson": ["thompson_federal", "Thompson del agente federal", "Ráfagas cortas y precisas, el doble de seguidas, que atraviesan a dos.",
		{"count*": 0.5, "pierce+": 2, "cooldown*": 0.5, "spread_deg*": 0.5},
		"La Thompson de los agentes federales que asaltaron Innsmouth en el invierno de 1927. Ráfagas cortas, como manda el reglamento."],
	"trapezoedro": ["trapezoedro_blake", "Trapezoedro de Blake", "Un rayo más fino, el doble de seguido.",
		{"cooldown*": 0.5, "projectile_radius*": 0.7, "range*": 1.2},
		"El trapezoedro que Robert Blake miró desde la iglesia de Federal Hill. Su luz es más estrecha, y lo encuentra todo."],
	"webly": ["webly_seis_tiros", "Webly de seis tiros", "Vacía el tambor: seis balas en abanico de una vez.",
		{"count=": 6, "spread_deg=": 30.0, "burst_delay=": 0.0, "cooldown*": 1.3},
		"Seis balas en lo que tarda en caer un casquillo. Dyer aprendió a disparar así en la Antártida, cuando apuntar dejó de servir."],
	"west": ["suero_halsey", "Suero de Halsey", "Tres dardos por disparo: más resucitados, que duran menos.",
		{"count+": 2, "spread_deg+": 20.0, "ally_time*": 0.7},
		"La fórmula que West probó en el decano Halsey. Funcionó a medias, y en cantidad."],
	"yith": ["rayo_pnakotus", "Rayo de Pnakotus", "Dos rayos, más del doble de seguidos, con una estasis más corta.",
		{"cooldown*": 0.45, "stasis*": 0.5, "count+": 1, "spread_deg+": 14.0},
		"Las armas de los archivos de Pnakotus, hechas para la guerra contra los pólipos. No paran el tiempo: lo tartamudean."],
	"recortada": ["recortada_matadero", "Recortada del matadero", "Un solo disparo de tres balas gruesas que atraviesan y lanzan lejos.",
		{"volleys=": 1, "count=": 3, "spread_deg=": 10.0, "pierce+": 3, "knockback*": 2.0, "range*": 1.5},
		"La recortada del matadero de Innsmouth, cargada con balas para reses. Lo que se mueve en la nave no es ganado."],
	"antitanque": ["fusil_cazacarros", "Fusil del cazacarros", "Dispara el doble de seguido, con algo menos de empuje.",
		{"cooldown*": 0.5, "knockback*": 0.6},
		"El cazacarros que lo llevaba aprendió a recargar tumbado en el barro. Ahora carga más deprisa que nadie."],
	"mortero": ["mortero_incendiario", "Mortero incendiario", "Un proyectil enorme que deja el suelo ardiendo, algo menos seguido.",
		{"aoe_radius*": 1.7, "zone=": 1, "zone_radius=": 2.5, "zone_time=": 3.0, "zone_dps=": 6.0, "cooldown*": 1.2},
		"Granadas de fósforo del Somme que nadie llegó a disparar. En R'lyeh, el fuego también prende en la piedra mojada."],
	"bar": ["bar_tirador", "BAR del tirador", "Ráfagas que ya no rebotan, pero atraviesan a tres y llegan más lejos.",
		{"bounces=": 0, "pierce+": 3, "range*": 1.4, "cooldown*": 0.8},
		"Con bípode y mira de tirador, el BAR deja de rociar: cada ráfaga va a donde se manda, y sigue."],
	"nagant": ["nagant_siete", "Nagant de siete tiros", "Siempre a toda cadencia desde el primer disparo, y atraviesa.",
		{"spinup=": 1.0, "cooldown*": 0.45, "pierce+": 1},
		"Siete balas, siete pasos. Danforth contó los suyos al bajar de las montañas de la locura, y no se equivocó en ninguno."],
	"ancla": ["molinete_alert", "Molinete del Alert", "Un ancla que gira muy deprisa y muy cerca, golpeando más a menudo.",
		{"projectile_speed*": 1.8, "aoe_radius*": 0.8, "hit_interval*": 0.6},
		"El molinete del Alert, que subía el ancla, sigue girando sin que nadie lo mueva. Lo que se acerca, entra en la rueda."],
	"gas": ["fosgeno", "Fosgeno", "Una nube quieta que deja vulnerables a los que la cruzan.",
		{"drift=": 0.0, "vulnerable=": 2.5, "zone_radius*": 0.85, "cooldown*": 0.8},
		"Huele a heno recién cortado. Los soldados que lo respiraron en Ypres no lo notaron hasta el día siguiente; las criaturas, tampoco."],
	"latigo": ["latigo_mayoral", "Látigo del mayoral", "Un chasquido estrecho que llega casi el doble de lejos, más seguido.",
		{"spread_deg=": 30.0, "range*": 1.8, "cooldown*": 0.7},
		"El látigo de un mayoral de diligencias de Nueva Inglaterra. Alcanza a la mula del fondo sin tocar a las de delante."],
	"cepos": ["cepo_oso", "Cepo de oso", "Un solo cepo enorme que atrapa a todos los de alrededor.",
		{"count=": 1, "aoe_radius*": 2.5, "root*": 0.6},
		"Un cepo de oso de los tramperos del Yukón, de dientes como cuchillos. Pensado para algo más grande que un oso."],
	"ballesta": ["ballesta_cranequin", "Ballesta de cranequín", "Un virote que atraviesa a seis y deja clavado a cada uno.",
		{"root*": 3.0, "pierce+": 4, "projectile_speed*": 1.3},
		"Una ballesta de asedio con su cranequín de manivela. Tarda en tensarse, y lo que atraviesa se queda en el suelo."],
	"cthugha": ["chispas_fomalhaut", "Chispas de Fomalhaut", "Bolas de fuego rápidas, el doble de seguidas, con un rastro más corto.",
		{"projectile_speed*": 2.2, "cooldown*": 0.5, "zone_time*": 0.6},
		"Cthugha mora junto a Fomalhaut, a veinticinco años de luz. Lo que llega de allí son chispas, y vienen deprisa."],
	"ithaqua": ["viento_ithaqua", "El que camina con el viento", "Un aliento helado estrecho que llega muy lejos.",
		{"spread_deg*": 0.5, "range*": 1.8},
		"Ithaqua camina sobre el viento y se lleva a quien lo ve. Su aliento cruza el hielo de punta a punta."],
	"yog": ["umr_tawil", "Umr at-Tawil", "Esferas más pequeñas y rápidas, el doble de seguidas.",
		{"cooldown*": 0.5, "aoe_radius*": 0.75, "duration*": 0.7, "projectile_speed*": 2.0},
		"El Más Antiguo, el guía de la Puerta. No abre la esfera del todo: la abre muchas veces."],
	"shub": ["cabra_negra", "La Cabra Negra", "Menos tentáculos, enormes, que aturden el doble.",
		{"count*": 0.5, "aoe_radius*": 2.0, "stun*": 2.0},
		"La Cabra Negra de los Bosques no manda a sus crías: brota ella misma, y donde brota no queda nada en pie."],
	"signo_amarillo": ["carcosa", "Carcosa", "Enloquece desde mucho más lejos y más a menudo.",
		{"range*": 1.6, "cooldown*": 0.6},
		"Junto al lago de Hali, bajo las lunas negras, las torres de Carcosa se ven desde todas partes. Y todas partes las ven a ellas."],
	"lampara": ["faro_irem", "Faro de Irem", "Un haz mucho más largo que gira despacio y dura más.",
		{"range*": 1.6, "projectile_speed*": 0.6, "duration*": 1.3},
		"La luz de Irem, la ciudad de los pilares, se ve desde el otro lado del desierto. Gira despacio: no tiene prisa por encontrarte."],
}

func _init() -> void:
	var notes := {}
	for base_id: String in EVO:
		var e: Array = EVO[base_id]
		_make(base_id, e[0], e[1], e[3], e[4], e[2])
		_link(base_id, "evolves_with", e[2])
		_link(base_id, "evolution", e[0])
		notes[e[0]] = e[5]
	for base_id: String in EVO_B:                        # hito 16.8
		var e: Array = EVO_B[base_id]
		var base: WeaponData = load("res://data/weapons/%s.tres" % base_id)
		_make(base_id, e[0], e[1], e[2], e[3], String(base.evolves_with))
		_link(base_id, "evolution_alt", e[0])
		notes[e[0]] = e[4]
	_notes(notes)
	quit()

## Escribe data/weapons/<evo_id>.tres: el arma a nivel 5 con sus cambios, rindiendo EVO_DPS veces.
func _make(base_id: String, evo_id: String, display: String, desc: String, mods: Dictionary, item: String) -> void:
	var base: WeaponData = load("res://data/weapons/%s.tres" % base_id)
	var lv5 := _at_level(base, base.max_level)
	var evo := lv5.duplicate() as WeaponData
	evo.id = StringName(evo_id); evo.display_name = display; evo.description = desc
	evo.evolved = true; evo.max_level = 1
	evo.level_mods = []; evo.level_text = []
	evo.evolves_with = &""; evo.evolution = &""; evo.evolution_alt = &""
	evo.icon = null
	for k: String in mods:
		var stat := k.left(-1)
		var v: float = float(mods[k])
		match k.right(1):
			"*": evo.set(stat, float(evo.get(stat)) * v)
			"+": evo.set(stat, float(evo.get(stat)) + v)
			"=": evo.set(stat, v)
	var want := DamageRules.dps(lv5) * EVO_DPS
	var now := DamageRules.dps(evo)
	if now > 0.0:
		var kk := want / now
		for d in DAMAGE_KEYS: evo.set(d, snappedf(float(evo.get(d)) * kk, 0.1))
	ResourceSaver.save(evo, "res://data/weapons/%s.tres" % evo_id)
	print("%-26s %-14s dps nivel 5 %.1f -> %.1f" % [evo_id, item, DamageRules.dps(lv5), DamageRules.dps(evo)])

## Copia del arma con las estadísticas de un nivel ya aplicadas.
func _at_level(w: WeaponData, level: int) -> WeaponData:
	var c := w.duplicate() as WeaponData
	for p in w.get_property_list():
		if not (p.usage & PROPERTY_USAGE_STORAGE): continue
		if p.type == TYPE_FLOAT: c.set(p.name, w.stat(p.name, level))
	return c

## Una línea `clave = &"valor"` en el .tres del arma base, sin reescribir el resto del fichero.
func _link(base_id: String, key: String, value: String) -> void:
	var path := "res://data/weapons/%s.tres" % base_id
	var lines := Array(FileAccess.get_file_as_string(path).split("\n"))
	var at := -1
	for i in lines.size():
		if (lines[i] as String).begins_with(key + " = "):
			at = i
			break
	if at >= 0: lines.remove_at(at)
	else:
		at = lines.find("max_level = 5")
		if at < 0: at = lines.size() - 1
	lines.insert(at, '%s = &"%s"' % [key, value])
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("\n".join(lines))

func _notes(notes: Dictionary) -> void:
	var path := "res://data/library/textos.json"
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	for k in notes: d["weapons"][k] = notes[k]
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(d, "\t", false) + "\n")
