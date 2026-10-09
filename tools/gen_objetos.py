"""Objetos de la subida de nivel (D-38, GDD 5.5): escribe data/upgrades/<id>.tres y su nota
en data/library/textos.json. Los iconos los hace tools/generar_iconos_objetos.py.

Uso: python tools/gen_objetos.py
Cada objeto: id, nombre, descripción, grupo, estadística, multiplica, suma, tope, otros
efectos ("also", con la sintaxis de WeaponData.level_mods) y nota de diario.
"""
import json
import os

RAIZ = os.path.join(os.path.dirname(__file__), "..")

COLORES = {
    "ataque": (0.95, 0.45, 0.3),
    "proteccion": (0.45, 0.8, 0.5),
    "esquive": (0.55, 0.8, 1.0),
    "utilidad": (1.0, 0.82, 0.3),
    "disparador": (0.75, 0.5, 1.0),
}

# id, nombre, descripción, grupo, stat, multiply, add, max_level, also, nota
OBJETOS = [
    # Los cinco de siempre (solo se les pone el grupo; conservan su icono)
    ("vida", "Abrigo de reno", "+20 de vida máxima", "proteccion", "max_health", 1.0, 20.0, 5, {}, None),
    ("cordura", "Diario de campo", "+20 de cordura máxima", "proteccion", "max_sanity", 1.0, 20.0, 5, {}, None),
    ("iman", "Brújula de Lake", "+30 % de radio para recoger experiencia", "utilidad", "pickup_radius", 1.3, 0.0, 5, {}, None),
    ("velocidad", "Botas de nieve", "+8 % de velocidad al andar", "esquive", "move_speed", 1.08, 0.0, 5, {}, None),
    ("reflejos", "Reflejos", "El esquive se recarga un 10 % antes", "esquive", "dodge_cooldown", 0.9, 0.0, 5, {}, None),
    # Ataque
    ("bandolera", "Bandolera", "+1 proyectil en las armas de balas y lanzados", "ataque", "proj_count_add", 1.0, 1.0, 3, {},
     "Bandolera de cuero con cartuchos de todos los calibres. Nunca sobran."),
    ("catalejo", "Catalejo", "+10 % de alcance de las armas", "ataque", "range_mult", 1.1, 0.0, 5, {},
     "Catalejo de latón del Alert. Johansen lo usaba para ver venir la tormenta; ahora, otras cosas."),
    ("polvora", "Pólvora de Ponape", "+12 % de velocidad de los proyectiles", "ataque", "proj_speed_mult", 1.12, 0.0, 5, {},
     "Pólvora negra de las islas, de un comerciante que la vendía junto a ciertas joyas de oro pálido."),
    ("mapa_leng", "Mapa de Leng", "+10 % de área de explosiones, zonas, ondas y tajos", "ataque", "area_mult", 1.1, 0.0, 5, {},
     "Un mapa estelar de la meseta de Leng. Las constelaciones no son las nuestras, pero las distancias se agrandan al mirarlo."),
    ("reloj", "Reloj de Tillinghast", "Las armas se recargan un 6 % antes", "ataque", "weapon_cooldown_mult", 0.94, 0.0, 5, {},
     "Reloj de bolsillo de Crawford Tillinghast. Adelanta: según él, porque oye lo que viene."),
    ("clepsidra", "Clepsidra de Yith", "+15 % de duración de zonas, órbitas, rayos y torretas", "ataque", "duration_mult", 1.15, 0.0, 5, {},
     "Clepsidra de cristal con una arena que a veces sube. La Gran Raza no medía el tiempo como nosotros."),
    ("piedra_afilar", "Piedra de afilar", "Las balas atraviesan 1 enemigo más", "ataque", "pierce_add", 1.0, 1.0, 3, {},
     "Piedra de afilar de un ballenero de Kingsport. Con ella, hasta las balas cortan."),
    ("ojo_pickman", "Ojo de Pickman", "+5 % de probabilidad de crítico (daño ×1,5)", "ataque", "crit_chance", 1.0, 0.05, 5, {},
     "Ojo de cristal que Pickman usaba como modelo. Encuentra el punto débil de cualquier cosa, por horrible que sea."),
    ("collar", "Collar de colmillos", "+15 % de daño de los críticos", "ataque", "crit_bonus", 1.0, 0.15, 5, {},
     "Collar de colmillos de Profundo comprado en el puerto de Innsmouth. El vendedor no quiso decir de dónde salían."),
    ("petaca", "Petaca de ron", "+8 % de daño", "ataque", "damage_mult", 1.08, 0.0, 5, {},
     "Petaca de ron del Emma. Un trago antes de disparar y el pulso no tiembla."),
    ("manual_tiro", "Manual de tiro", "+12 % de daño de las armas de fuego", "ataque", "firearm_mult", 1.12, 0.0, 5, {},
     "Manual de tiro del Ejército de los Estados Unidos, edición de 1917, con notas a lápiz del sargento Elwood."),
    ("guantes", "Guantes de estibador", "+12 % de daño de las armas físicas y +10 % de empuje", "ataque", "physical_mult", 1.12, 0.0, 5,
     {"knockback_mult*": 1.1}, "Guantes de cuero curtido de los muelles de Arkham. Para cargar fardos o para lo que haga falta."),
    ("manuscritos", "Manuscritos pnakóticos", "+12 % de daño de las armas mágicas", "ataque", "magic_mult", 1.12, 0.0, 5, {},
     "Hojas sueltas copiadas de los Manuscritos Pnakóticos. Nadie sabe quién los escribió ni en qué época."),
    ("medallon", "Medallón del cazador", "+20 % de daño a élites y seres únicos", "ataque", "elite_mult", 1.0, 0.2, 5, {},
     "Medallón con la marca de una cofradía de cazadores de Providence. Dicen que solo persiguen presas grandes."),
    ("plomada", "Plomada", "+25 % de empuje", "ataque", "knockback_mult", 1.25, 0.0, 5, {},
     "Plomada de pescador de Innsmouth, demasiado pesada para su tamaño."),
    # Protección y recuperación
    ("coraza", "Coraza de foca", "−2 al daño físico de cada golpe", "proteccion", "armor", 1.0, 2.0, 5, {},
     "Coraza de piel de foca curtida, a la manera de los cazadores del norte. Los colmillos resbalan."),
    ("signo_primigenio", "Signo Primigenio", "−10 % de daño mental, también de las auras", "proteccion", "mental_mult", 0.9, 0.0, 5, {},
     "Estrella de cinco puntas con un ojo en llamas, tallada en piedra gris. Algunas cosas no se acercan a ella."),
    ("botiquin", "Botiquín", "Recupera 0,3 de vida por segundo", "proteccion", "health_regen", 1.0, 0.3, 5, {},
     "Botiquín de campaña con vendas, yodo y morfina. La doctora Whipple lo repasa cada mañana."),
    ("pipa", "Pipa de espuma", "Recupera 0,4 de cordura por segundo", "proteccion", "sanity_regen", 1.0, 0.4, 5, {},
     "Pipa de espuma de mar. Mientras dura el tabaco, el mundo parece normal."),
    ("colmillo", "Colmillo de ghoul", "Cada enemigo abatido cura 0,5 de vida", "proteccion", "heal_on_kill", 1.0, 0.5, 5, {},
     "Colmillo de ghoul de los cementerios de Boston. Quien lo lleva se alimenta, a su manera, de lo que cae."),
    ("salterio", "Salterio", "Cada enemigo abatido devuelve 0,3 de cordura", "proteccion", "sanity_on_kill", 1.0, 0.3, 5, {},
     "Libro de salmos con las tapas gastadas. Cada horror vencido es un versículo más."),
    ("escapulario", "Escapulario", "+25 % de invulnerabilidad tras recibir un golpe", "proteccion", "hit_iframes", 1.25, 0.0, 5, {},
     "Escapulario de una iglesia de Kingsport. Da unos segundos de gracia."),
    ("laudano", "Láudano", "Las crisis de locura duran un 20 % menos", "proteccion", "crisis_mult", 0.8, 0.0, 5, {},
     "Frasco de láudano del dispensario de Arkham. Calma los nervios; demasiado, otras cosas."),
    # Esquive
    ("crampones", "Crampones", "+15 % de distancia del esquive", "esquive", "dodge_speed", 1.15, 0.0, 5, {},
     "Crampones de acero de la expedición. En el hielo, un salto con ellos vale por dos."),
    ("gafas", "Gafas de aviador", "+0,08 s de invulnerabilidad al esquivar", "esquive", "dodge_iframes", 1.0, 0.08, 5, {},
     "Gafas de aviador de Danforth. Desde que voló sobre las montañas, ve venir los golpes antes."),
    # Utilidad
    ("lupa", "Lupa", "+10 % de experiencia", "utilidad", "xp_mult", 1.1, 0.0, 5, {},
     "Lupa de anticuario con mango de hueso. Se aprende mucho mirando de cerca."),
    ("dado", "Dado de hueso", "+15 % de suerte: a veces una opción más al subir de nivel", "utilidad", "luck", 1.0, 0.15, 5, {},
     "Dado de hueso traído de Leng. Las caras no tienen puntos, sino signos, y casi siempre sale el bueno."),
    ("oro_obed", "Oro de Obed", "+15 % de dólares para el equipo", "utilidad", "money_mult", 1.0, 0.15, 5, {},
     "Lingote de oro pálido de la refinería de Obed Marsh. No es oro de ninguna mina conocida."),
    ("vara", "Vara de zahorí", "Los baúles arcanos aparecen un 15 % más a menudo", "utilidad", "chest_mult", 1.0, 0.15, 5, {},
     "Vara de avellano en horquilla. En Dunwich la usan para buscar agua; aquí tiembla cerca de otras cosas."),
    ("pemmican", "Pemmican", "La comida y las pociones curan un 30 % más", "utilidad", "pickup_heal_mult", 1.0, 0.3, 5, {},
     "Pemmican de las provisiones de la expedición: grasa, carne seca y bayas. Sabe mal y alimenta mucho."),
    ("silbato", "Silbato de Lake", "+20 % de daño y velocidad del compañero", "utilidad", "pet_mult", 1.0, 0.2, 5, {},
     "Silbato de perrero del campamento de Lake. Los animales lo obedecen con más ganas."),
    ("talisman", "Talismán esotérico", "Las armas mágicas cuestan un 12 % menos de cordura", "utilidad", "arcane_cost_mult", 0.88, 0.0, 5, {},
     "Talismán de la Orden Esotérica de Dagon, robado en el registro de su templo. Lo que cuesta, cuesta menos."),
]


def fnum(x):
    return repr(float(x))


def tres(o, icon_path):
    oid, nombre, desc, grupo, stat, mul, add, tope, also, _ = o
    c = COLORES[grupo]
    lineas = ['[gd_resource type="Resource" script_class="UpgradeData" load_steps=%d format=3]' % (3 if icon_path else 2), "",
              '[ext_resource type="Script" path="res://scripts/progression/upgrade_data.gd" id="1"]']
    if icon_path:
        lineas.append('[ext_resource type="Texture2D" path="%s" id="2"]' % icon_path)
    lineas += ["", "[resource]", 'script = ExtResource("1")', 'id = &"%s"' % oid, 'display_name = "%s"' % nombre,
               'description = "%s"' % desc, 'stat = "%s"' % stat, "multiply = %s" % fnum(mul), "add = %s" % fnum(add),
               "max_level = %d" % tope]
    if stat in ("max_health", "max_sanity"):
        lineas.append("heal = true")
    lineas.append("color = Color(%s, %s, %s, 1)" % c)
    if icon_path:
        lineas.append('icon = ExtResource("2")')
    if also:
        lineas.append("also = " + "{\n" + ",\n".join('"%s": %s' % (k, fnum(v)) for k, v in also.items()) + "\n}")
    lineas.append('group = "%s"' % grupo)
    return "\n".join(lineas) + "\n"


def main():
    ruta_txt = os.path.join(RAIZ, "data", "library", "textos.json")
    with open(ruta_txt, encoding="utf-8") as f:
        textos = json.load(f)
    for o in OBJETOS:
        oid = o[0]
        icon = "res://resources/items/icons/%s.png" % oid
        icon = icon if os.path.exists(os.path.join(RAIZ, "resources", "items", "icons", oid + ".png")) else None
        with open(os.path.join(RAIZ, "data", "upgrades", oid + ".tres"), "w", encoding="utf-8", newline="\n") as f:
            f.write(tres(o, icon))
        if o[9]:
            textos["items"][oid] = o[9]
    with open(ruta_txt, "w", encoding="utf-8", newline="\n") as f:
        json.dump(textos, f, ensure_ascii=False, indent="	")
        f.write("\n")
    print("%d objetos" % len(OBJETOS))


if __name__ == "__main__":
    main()
