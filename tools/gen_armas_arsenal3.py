"""Arsenal III (D-38, GDD 5.4): escribe data/weapons/<id>.tres de las 16 armas nuevas y su
nota en data/library/textos.json. El daño de nivel 1 lo ajustan después las reglas de daño:
  godot --headless --path . -s tools/reglas_dano.gd -- aplicar
Uso: python tools/gen_armas_arsenal3.py
"""
import json
import os

RAIZ = os.path.join(os.path.dirname(__file__), "..")

DELIVERY = {"BULLET": 0, "THROWN": 1, "MELEE": 2, "ORBIT": 3, "BEAM": 4, "WAVE": 5, "FLAME": 6, "SIGIL": 7,
            "PULSE": 8, "TETHER": 9, "CLOUD": 10, "DRONE": 11, "STAB": 12, "CHAIN": 13, "TURRET": 14,
            "BOOMERANG": 15, "FISSURE": 16, "THRUST": 17, "WHIP": 18, "TRAP": 19, "FIREBALL": 20, "VORTEX": 21,
            "SPIKES": 22, "MADDEN": 23, "SWEEP": 24}
TARGETING = {"NEAREST": 0, "DENSEST": 1, "MOVE_DIR": 2, "AROUND": 3, "STRONGEST": 4, "FRONT_BACK": 5}
CATEGORY = {"PHYSICAL": 0, "FIREARM": 1, "MAGIC": 2}
ZONE = {"NONE": 0, "FIRE": 1, "ACID": 2, "DUST": 3, "GAS": 4}

# id: (nombre, descripción, entrega, categoría, apuntado, estadísticas, mejoras [(mods, texto)], nota)
ARMAS = {
    # ---------------- De fuego ----------------
    "recortada": ("Recortada", "Dos disparos seguidos de perdigones en un cono corto y ancho que empuja mucho.",
        "BULLET", "FIREARM", "NEAREST",
        dict(bullet_look="pellet", cooldown=1.6, range=5.0, damage=4.0, count=6, spread_deg=40.0, volleys=2,
             volley_delay=0.22, projectile_speed=18.0, projectile_radius=0.16, projectile_size=0.13, knockback=2.5),
        [({"count+": 2}, "Dos perdigones más"), ({"damage*": 1.25}, "+25 % de daño"),
         ({"cooldown*": 0.85}, "Recarga un 15 % más rápido"), ({"volleys+": 1, "knockback*": 1.2}, "Un tercer disparo y más empuje")],
        "Escopeta de dos cañones aserrados, de las que llevaban los contrabandistas de Kingsport. A dos pasos no falla, y a diez no sirve."),
    "antitanque": ("Antitanque Mauser", "Disparo muy lento que atraviesa a todos los enemigos de la línea.",
        "BULLET", "FIREARM", "STRONGEST",
        dict(bullet_look="rifle", cooldown=2.6, range=20.0, damage=60.0, pierce=99, projectile_speed=40.0,
             projectile_radius=0.22, projectile_size=0.2, knockback=3.0),
        [({"damage*": 1.25}, "+25 % de daño"), ({"cooldown*": 0.85}, "Recarga un 15 % más rápido"),
         ({"damage*": 1.25}, "+25 % de daño"), ({"knockback*": 1.5, "projectile_radius*": 1.4}, "Bala más gruesa y más empuje")],
        "Fusil antitanque alemán de 1918, de casi dos metros. Pensado para el blindaje de los carros; también sirve para lo que tiene la piel más dura."),
    "mortero": ("Mortero Stokes", "Proyectil en arco alto al grupo más denso a distancia; explosión grande.",
        "THROWN", "FIREARM", "DENSEST",
        dict(look="granada", cooldown=2.4, range=16.0, damage=30.0, aoe_radius=3.0, flight_time=1.1, fuse=0.0,
             arc_height=7.0, knockback=2.0),
        [({"aoe_radius*": 1.15}, "Explosión un 15 % más grande"), ({"damage*": 1.25}, "+25 % de daño"),
         ({"count+": 1}, "Dos proyectiles por disparo"), ({"cooldown*": 0.85}, "Recarga un 15 % más rápido")],
        "Mortero de trinchera británico. Se lanza la granada por la boca y cae del cielo donde más duele."),
    "bar": ("BAR M1918", "Ráfagas cuyas balas rebotan hacia otro enemigo cercano.",
        "BULLET", "FIREARM", "NEAREST",
        dict(bullet_look="smg", cooldown=1.0, range=11.0, damage=7.0, count=3, burst_delay=0.08, bounces=1,
             projectile_speed=26.0, projectile_radius=0.16, projectile_size=0.13, knockback=1.0),
        [({"bounces+": 1}, "Un rebote más"), ({"count+": 1}, "Una bala más por ráfaga"),
         ({"damage*": 1.25}, "+25 % de daño"), ({"bounces+": 1, "cooldown*": 0.9}, "Un rebote más y algo más de cadencia")],
        "Fusil ametrallador Browning del ejército de los Estados Unidos. Las balas de la Gran Guerra rebotan en la piedra y en las escamas."),
    "nagant": ("Nagant de Danforth", "Revólver cuya cadencia se acelera mientras tiene a quién disparar, hasta dos veces y media.",
        "BULLET", "FIREARM", "NEAREST",
        dict(cooldown=0.7, range=10.0, damage=9.0, spinup=2.5, spinup_time=3.0, projectile_speed=24.0,
             projectile_radius=0.16, projectile_size=0.14),
        [({"damage*": 1.25}, "+25 % de daño"), ({"cooldown*": 0.9}, "Recarga un 10 % más rápido"),
         ({"count+": 1, "spread_deg+": 8.0}, "Dos balas por disparo"), ({"damage*": 1.25}, "+25 % de daño")],
        "El revólver ruso que Danforth compró en Boston antes de la expedición. Cuanto más dispara, más le tiembla el pulso y más deprisa aprieta."),
    # ---------------- Físicas ----------------
    "ancla": ("Ancla del Alert", "Un ancla con cadena que gira alrededor del personaje a mucha distancia, lenta y pesada.",
        "ORBIT", "PHYSICAL", "AROUND",
        dict(orbit_look="ancla", cooldown=3.0, count=1, aoe_radius=3.0, projectile_speed=100.0, projectile_radius=0.55,
             damage=22.0, duration=5.0, hit_interval=0.8, knockback=3.5),
        [({"damage*": 1.25}, "+25 % de daño"), ({"duration*": 1.3}, "Gira un 30 % más de tiempo"),
         ({"aoe_radius*": 1.15, "projectile_speed+": 20.0}, "Más lejos y más deprisa"), ({"count+": 1}, "Dos anclas")],
        "Ancla de la goleta Alert, arrancada con media cadena. Johansen la blande como si no pesara: algo ha visto que pesa más."),
    "gas": ("Gas de cloro", "Nube tóxica que deriva lentamente hacia los enemigos y los envenena.",
        "CLOUD", "PHYSICAL", "DENSEST",
        dict(zone=4, range=9.0, cooldown=3.0, damage=0.0, zone_radius=1.8, zone_time=5.0, zone_dps=7.0, drift=0.8),
        [({"zone_radius*": 1.15}, "Nube un 15 % más grande"), ({"zone_dps*": 1.25}, "+25 % de daño"),
         ({"zone_time*": 1.25}, "Dura un 25 % más"), ({"cooldown*": 0.85}, "Recarga un 15 % más rápido")],
        "Bombonas de cloro de las trincheras de Ypres. Lo que respira, se ahoga; lo que no respira, ya veremos."),
    "latigo": ("Látigo", "Latigazo largo en arco por delante que golpea a todos los del arco.",
        "WHIP", "PHYSICAL", "NEAREST",
        dict(range=4.5, spread_deg=90.0, cooldown=1.1, damage=14.0, knockback=2.0),
        [({"range*": 1.15}, "Un 15 % más largo"), ({"damage*": 1.25}, "+25 % de daño"),
         ({"spread_deg+": 30.0}, "Arco más ancho"), ({"cooldown*": 0.85}, "Recarga un 15 % más rápido")],
        "Látigo de carretero de cuero trenzado, de los que guiaban las mulas por las colinas de Dunwich."),
    "cepos": ("Cepos", "Deja cepos en el suelo: el primero que los pisa queda atrapado y herido.",
        "TRAP", "PHYSICAL", "NEAREST",
        dict(range=8.0, count=2, aoe_radius=0.7, duration=14.0, damage=40.0, root=2.5, cooldown=1.8),
        [({"count+": 1}, "Un cepo más a la vez"), ({"damage*": 1.3}, "+30 % de daño"),
         ({"root*": 1.3, "aoe_radius*": 1.2}, "Atrapan más tiempo y desde más lejos"), ({"count+": 1}, "Un cepo más a la vez")],
        "Cepos de oso de un trampero de los bosques de Vermont. Tenía muchos; decía que nunca eran bastantes."),
    "ballesta": ("Ballesta", "Virotes que atraviesan y dejan clavado al enemigo un instante.",
        "BULLET", "PHYSICAL", "NEAREST",
        dict(bullet_look="harpoon", cooldown=1.3, range=14.0, damage=20.0, pierce=2, root=0.6, projectile_speed=28.0,
             projectile_radius=0.18, projectile_size=0.15, knockback=1.2),
        [({"pierce+": 1}, "Atraviesa un enemigo más"), ({"damage*": 1.25}, "+25 % de daño"),
         ({"count+": 1, "spread_deg+": 10.0}, "Dos virotes por disparo"), ({"root*": 1.5}, "Clava un 50 % más de tiempo")],
        "Ballesta de caza de un coleccionista de Providence. Silenciosa, como conviene en ciertas casas viejas."),
    # ---------------- Mágicas ----------------
    "cthugha": ("Llama de Cthugha", "Bola de fuego vivo que atraviesa a los enemigos y deja un rastro ardiendo.",
        "FIREBALL", "MAGIC", "NEAREST",
        dict(cooldown=2.0, range=11.0, projectile_speed=7.0, projectile_radius=0.45, damage=18.0, sanity_cost=3.0,
             zone=1, zone_radius=0.9, zone_time=2.5, zone_dps=6.0),
        [({"damage*": 1.25}, "+25 % de daño"), ({"zone_time*": 1.3}, "El rastro arde un 30 % más"),
         ({"cooldown*": 0.85}, "Recarga un 15 % más rápido"), ({"projectile_radius*": 1.3, "zone_radius*": 1.2}, "Bola más grande")],
        "Una chispa de Cthugha, el que habita en Fomalhaut, encerrada en una fórmula. Arde sin consumirse, y quema lo que toca."),
    "ithaqua": ("Aliento de Ithaqua", "Viento helado en cono que frena a los enemigos y congela a los que siguen dentro.",
        "FLAME", "MAGIC", "NEAREST",
        dict(frost=True, cooldown=2.2, range=5.0, spread_deg=40.0, duration=1.0, damage=12.0, sanity_cost=3.0,
             zone_time=0.0),
        [({"range*": 1.15}, "Un 15 % más de alcance"), ({"damage*": 1.25}, "+25 % de daño"),
         ({"duration*": 1.3}, "Sopla un 30 % más"), ({"spread_deg+": 15.0, "cooldown*": 0.9}, "Cono más ancho")],
        "El aliento del que camina sobre el viento, en los bosques helados del norte. Quien lo nota en la nuca no vuelve a entrar en calor."),
    "yog": ("Esfera de Yog-Sothoth", "Orbe lento que atrae a los enemigos hacia su centro y los tritura.",
        "VORTEX", "MAGIC", "DENSEST",
        dict(cooldown=5.0, range=10.0, projectile_speed=2.5, aoe_radius=2.8, damage=6.0, hit_interval=0.4, pull=5.0,
             duration=4.0, sanity_cost=5.0),
        [({"aoe_radius*": 1.15}, "Un 15 % más grande"), ({"pull*": 1.3}, "Atrae un 30 % más"),
         ({"damage*": 1.25}, "+25 % de daño"), ({"duration*": 1.25}, "Dura un 25 % más")],
        "Un conglomerado de esferas iridiscentes: la llave y la puerta, decían los Whateley. Lo que se acerca no vuelve a salir."),
    "shub": ("Tentáculos de Shub", "Tentáculos que brotan del suelo, tras un aviso, bajo enemigos al azar.",
        "SPIKES", "MAGIC", "AROUND",
        dict(cooldown=1.8, range=8.0, count=2, aoe_radius=1.1, damage=26.0, stun=0.4, sanity_cost=2.5),
        [({"count+": 1}, "Un tentáculo más"), ({"damage*": 1.25}, "+25 % de daño"),
         ({"aoe_radius*": 1.2}, "Un 20 % más grandes"), ({"count+": 1}, "Un tentáculo más")],
        "¡Ïa! ¡Shub-Niggurath! La Cabra Negra de los Bosques con sus Mil Crías. Algo responde desde debajo de la tierra."),
    "signo_amarillo": ("Signo Amarillo", "Los enemigos que lo miran enloquecen y atacan a los suyos unos segundos.",
        "MADDEN", "MAGIC", "AROUND",
        dict(cooldown=4.0, range=7.0, count=2, duration=4.0, damage=12.0, sanity_cost=4.0),
        [({"count+": 1}, "Enloquece a uno más"), ({"duration*": 1.3}, "Dura un 30 % más"),
         ({"damage*": 1.3}, "Atacan un 30 % más fuerte"), ({"count+": 1}, "Enloquece a uno más")],
        "Un signo que no es de ningún alfabeto, de la obra que nadie debería leer entera. Los que lo miran ya no distinguen al enemigo."),
    "lampara": ("Lámpara de Alhazred", "Haz de luz que barre en círculo alrededor del personaje.",
        "SWEEP", "MAGIC", "AROUND",
        dict(cooldown=4.5, range=5.5, projectile_radius=0.3, projectile_speed=150.0, damage=14.0, hit_interval=0.3,
             duration=3.0, sanity_cost=4.0),
        [({"duration*": 1.3}, "Gira un 30 % más de tiempo"), ({"damage*": 1.25}, "+25 % de daño"),
         ({"range*": 1.15}, "Un 15 % más de alcance"), ({"projectile_speed*": 1.3}, "Gira un 30 % más deprisa")],
        "Lámpara de aceite de forma árabe. Su luz enseña cosas de otros tiempos y quema a las criaturas que viven en la sombra."),
}


def num(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    return repr(float(v))


def mods_str(m):
    return "{" + ", ".join('"%s": %s' % (k, num(v)) for k, v in m.items()) + "}"


def tres(wid, a):
    nombre, desc, entrega, cat, apunt, stats, mejoras, _ = a
    out = ['[gd_resource type="Resource" script_class="WeaponData" load_steps=2 format=3]', "",
           '[ext_resource type="Script" path="res://scripts/weapons/weapon_data.gd" id="1"]', "", "[resource]",
           'script = ExtResource("1")', 'id = &"%s"' % wid, 'display_name = "%s"' % nombre, 'description = "%s"' % desc,
           "delivery = %d" % DELIVERY[entrega], "category = %d" % CATEGORY[cat], "targeting = %d" % TARGETING[apunt]]
    for k, v in stats.items():
        if isinstance(v, str): out.append('%s = "%s"' % (k, v))
        elif k == "zone": out.append("zone = %d" % v)
        else: out.append("%s = %s" % (k, num(v)))
    out.append("max_level = 5")
    out.append("level_mods = Array[Dictionary]([%s])" % ", ".join(mods_str(m) for m, _ in mejoras))
    out.append("level_text = Array[String]([%s])" % ", ".join('"%s"' % t for _, t in mejoras))
    return "\n".join(out) + "\n"


def main():
    ruta_txt = os.path.join(RAIZ, "data", "library", "textos.json")
    with open(ruta_txt, encoding="utf-8") as f:
        textos = json.load(f)
    for wid, a in ARMAS.items():
        with open(os.path.join(RAIZ, "data", "weapons", wid + ".tres"), "w", encoding="utf-8", newline="\n") as f:
            f.write(tres(wid, a))
        textos["weapons"][wid] = a[7]
    with open(ruta_txt, "w", encoding="utf-8", newline="\n") as f:
        json.dump(textos, f, ensure_ascii=False, indent="\t")
        f.write("\n")
    print("%d armas" % len(ARMAS))


if __name__ == "__main__":
    main()
