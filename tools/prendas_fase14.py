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
