"""Fichas de las prendas de la fase 14 (data/outfits/<id>.tres): nombre, descripción, hueco, precio
y, si hace falta, la postura del brazo, el efecto y el personaje del icono. Las geometrías están en
tools/gen_vestuario.py. Escribe solo las que faltan o cambian; el orden sigue a las que ya había.
Uso: python tools/prendas_fase14.py
"""
import os, re

HEAD, BODY, FEET, ACC, HANDS, BACK = range(6)

# id, nombre, descripción, hueco, precio, extras
PRENDAS = [
    # cabeza
    ('gorra_marinero', 'Gorra de marinero', 'Lana azul de los pescadores de Innsmouth, con verdín del salitre.', HEAD, 1200, {}),
    ('fez', 'Fez de la Orden', 'Granate con borla, de la Orden Esotérica de Dagon.', HEAD, 1800, {}),
    ('capucha_cultista', 'Capucha de cultista', 'Negra, con la cara en sombra: solo se ven los ojos.', HEAD, 3000, {}),
    ('tiara', 'Tiara de los Marsh', 'Oro raro de Innsmouth, con perlas y una piedra que brilla.', HEAD, 4000, {}),
    ('gorra_chofer', 'Gorra de chófer', 'Negra, con visera de charol, para llevar un Packard.', HEAD, 1300, {}),
    ('sombrero_hule', 'Sombrero de hule', 'Sueste amarillo de pescador, a juego con el chubasquero.', HEAD, 1200, {}),
    ('casco_aviador', 'Casco de aviador', 'Cuero con orejeras y las gafas en la frente, como en la expedición.', HEAD, 2200, {}),
    ('birrete', 'Birrete de la Miskatonic', 'El de los catedráticos, con su borla dorada.', HEAD, 1500, {}),
    ('panuelo_gitana', 'Pañuelo de gitana', 'Rojo con lunares, anudado en la nuca, y aros de oro.', HEAD, 1400, {}),
    ('corona_algas', 'Corona de algas', 'Algas, conchas y una estrella de mar, de los que vuelven del mar.', HEAD, 2500, {}),
    ('fedora_ganster', 'Fedora de gánster', 'Gris perla con cinta negra, de Chicago.', HEAD, 2000, {}),
    ('gorro_dormir', 'Gorro de dormir', 'Rayas y borla, para las pesadillas.', HEAD, 800, {}),
    ('casco_buzo', 'Casco de buzo', 'Cobre y latón con ojo de buey, para bajar al arrecife.', HEAD, 5000, {}),
    # cuerpo
    ('gabardina', 'Gabardina', 'Beis, cruzada y con cinturón, de detective de Boston.', BODY, 2400, {}),
    ('tunica_cultista', 'Túnica de cultista', 'Negra hasta los pies, con ribete rojo y el signo bordado.', BODY, 3000, {}),
    ('traje_buzo', 'Traje de buzo', 'Lona engomada y cinturón de plomos, a juego con el casco.', BODY, 3500, {}),
    ('uniforme_enfermera', 'Uniforme de enfermera', 'Del hospital de Arkham, con delantal y la cruz roja.', BODY, 1800, {}),
    ('mono_mecanico', 'Mono de mecánico', 'Azul y con grasa, de los talleres del puerto.', BODY, 1200, {}),
    ('esmoquin', 'Esmoquin', 'Negro con solapas de raso y pajarita, para las fiestas de Kingsport.', BODY, 2600, {}),
    ('vestido_charleston', 'Vestido de charlestón', 'Dorado, de talle bajo, con flecos y lentejuelas.', BODY, 2800, {}),
    ('jersey_marinero', 'Jersey de marinero', 'Rayas azules y crudas, de cuello alto.', BODY, 1000, {}),
    ('parka_inuit', 'Parka inuit', 'Piel de caribú con bandas bordadas y capucha.', BODY, 2600, {}),
    ('sotana_exorcista', 'Sotana de exorcista', 'Roquete de encaje y estola morada, para expulsar lo que no es.', BODY, 2400, {}),
    ('capa_terciopelo', 'Capa de terciopelo', 'Carmesí forrada de morado, con broche dorado.', BODY, 3200, {}),
    ('uniforme_lake', 'Uniforme de la expedición', 'Caqui, de la expedición Lake de la Miskatonic.', BODY, 2000, {}),
    ('harapos', 'Harapos', 'Lo que queda de la ropa después de tres noches.', BODY, 500, {}),
    # pies
    ('botas_agua', 'Botas de agua', 'Goma verde para los charcos del muelle.', FEET, 900, {}),
    ('zapatos_bicolor', 'Zapatos bicolores', 'Blancos y marrones, de gánster con estilo.', FEET, 1600, {}),
    ('sandalias_calcetines', 'Sandalias y calcetines', 'Lo que se pone el turista de Arkham.', FEET, 700, {}),
    ('botas_montar', 'Botas de montar', 'Negras, de caña alta y con espuela.', FEET, 1800, {}),
    ('raquetas_nieve', 'Raquetas de nieve', 'Madera y tripa trenzada, para no hundirse en la Antártida.', FEET, 1500, {}),
    ('zapatillas', 'Zapatillas de casa', 'De cuadros y con borla, a juego con el gorro de dormir.', FEET, 600, {}),
    ('botas_buzo', 'Botas de buzo', 'Plomo y latón, a juego con el casco.', FEET, 2500, {}),
    ('pies_membrana', 'Pies de Innsmouth', 'Descalzos, con membrana entre los dedos. Ya no tiene remedio.', FEET, 3000, {}),
    # complementos
    ('monoculo', 'Monóculo', 'De oro, con cadenita, para mirar por encima del hombro.', ACC, 1400, {}),
    ('pipa', 'Pipa de brezo', 'Encendida, echa su humo.', ACC, 1600, {}),
    ('collar_signo', 'Signo Primigenio', 'La estrella de piedra que los aparta. O eso dicen.', ACC, 3500, {}),
    ('bolsa_cartero', 'Bolsa de cartero', 'Lona y cuero, cruzada, para las notas de campo.', ACC, 1000, {}),
    ('canana', 'Cananas', 'Dos, cruzadas y cargadas.', ACC, 1500, {}),
    ('antifaz', 'Antifaz', 'Seda negra, para los bailes de máscaras de Kingsport.', ACC, 1100, {}),
    ('mascara_gas', 'Máscara de gas', 'De la Gran Guerra. Por si el aire de R\'lyeh.', ACC, 2400, {}),
    ('medico_peste', 'Máscara de la peste', 'Pico largo y cristales rojos.', ACC, 3000, {}),
    ('vendas_parche', 'Vendas y parche', 'Lo que dejó la última noche.', ACC, 700, {}),
    ('clavel', 'Clavel', 'Rojo, en el ojal.', ACC, 500, {}),
    ('panuelo_vaquero', 'Pañuelo de vaquero', 'Rojo, tapando la cara, para el polvo y los testigos.', ACC, 900, {}),
    ('estetoscopio', 'Estetoscopio', 'Para escuchar lo que late donde no debería.', ACC, 1200, {}),
    ('camara_fuelle', 'Cámara de fuelle', 'Para fotografiar lo que nadie creerá.', ACC, 2000, {}),
    ('rosario', 'Rosario', 'Cuentas de madera y cruz de plata.', ACC, 900, {}),
    ('ojos_innsmouth', 'Ojos de Innsmouth', 'Saltones, sin párpados, y unas agallas. La cara de Innsmouth.', ACC, 3500, {}),
    # manos
    ('guantes_cuero', 'Guantes de cuero', 'De conducir, marrones.', HANDS, 800, {}),
    ('guantes_boxeo', 'Guantes de boxeo', 'Rojos. No sirven de nada contra un shoggoth.', HANDS, 1500, {}),
    ('manoplas', 'Manoplas', 'De lana roja con copos, para la Antártida.', HANDS, 700, {}),
    ('baston', 'Bastón de ébano', 'Con puño de plata.', HANDS, 1800, {'hold': 'cane'}),
    ('paraguas', 'Paraguas', 'Negro y abierto, para la lluvia de Innsmouth.', HANDS, 1600, {'hold': 'umbrella'}),
    ('linterna', 'Linterna eléctrica', 'Encendida: alumbra por delante.', HANDS, 2500, {'hold': 'lantern'}),
    # espalda
    ('mochila', 'Mochila de expedición', 'Con el saco de dormir y el cazo.', BACK, 1800, {}),
    ('tentaculo', 'Tentáculo', 'Le sale de la espalda. Ya no lo esconde.', BACK, 4000, {}),
]

TEMPLATE = '''[gd_resource type="Resource" script_class="OutfitData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/save/outfit_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"{id}"
display_name = "{name}"
description = "{desc}"
slot = {slot}
price = {price}
order = {order}
{extra}'''


def main():
    d = 'data/outfits'
    orders = {}
    for f in os.listdir(d):
        if not f.endswith('.tres'): continue
        s = open(os.path.join(d, f), encoding='utf-8').read()
        slot = int(re.search(r'slot = (\d+)', s).group(1)) if 'slot =' in s else 0
        order = int(re.search(r'order = (\d+)', s).group(1)) if 'order =' in s else 0
        orders.setdefault(slot, {})[f[:-5]] = order
    n = 0
    for pid, name, desc, slot, price, ex in PRENDAS:
        mine = orders.setdefault(slot, {})
        order = mine.get(pid, max(mine.values(), default=-1) + 1)
        mine[pid] = order
        extra = ''.join('%s = "%s"\n' % (k, v) for k, v in ex.items())
        text = TEMPLATE.format(id=pid, name=name, desc=desc, slot=slot, price=price, order=order, extra=extra)
        path = os.path.join(d, pid + '.tres')
        if not os.path.exists(path) or open(path, encoding='utf-8').read() != text:
            open(path, 'w', encoding='utf-8', newline='\n').write(text)
            n += 1
    print(n, 'fichas escritas de', len(PRENDAS))


if __name__ == '__main__':
    main()
