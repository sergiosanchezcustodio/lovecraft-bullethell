"""Criaturas de R'lyeh (fase 7, hito 7.5), recoloreadas de modelos existentes:
  emanacion        masa gelatinosa verde que brota de la puerta negra (el fragmento
                   protoplásmico en verde translúcido, con burbujas que brillan)
  primigenio_menor uno de los que yacen con Cthulhu: el engendro con piel de piedra
                   verdinegra agrietada, como una estatua que despierta, con los ojos y las
                   grietas en verde
Si cambian fragmento.json o engendro.json, vuelve a ejecutarlo.
Uso: python tools/gen_rlyeh_criaturas.py
"""
import json, random

def recolor(src, dst, fn, glow_fn):
    d = json.load(open('models/%s.json' % src))
    rng = random.Random(dst)
    for v in d['voxels']:
        x, y, z, part, r, g, b, gl = v
        if gl: v[4:7] = glow_fn(r, g, b); continue
        nr, ng, nb, ngl = fn(x, y, z, r, g, b, rng)
        v[4:8] = [round(nr, 3), round(ng, 3), round(nb, 3), ngl]
    json.dump(d, open('models/%s.json' % dst, 'w'))
    print(dst, len(d['voxels']), 'voxels')

def gel(x, y, z, r, g, b, rng):
    l = (r + g + b) / 3
    if rng.random() < 0.025: return 0.55, 1.0, 0.55, 1                 # burbujas que brillan
    return 0.10 + l * 0.4, 0.42 + l * 0.7, 0.18 + l * 0.35, 0

def stone(x, y, z, r, g, b, rng):
    l = (r + g + b) / 3
    if (x * 7 + y * 3 + z * 5) % 41 == 0 and y % 6 < 2: return 0.25, 0.85, 0.45, 1    # grietas con luz verde
    k = 0.85 + 0.3 * rng.random()
    return (0.13 + l * 0.35) * k, (0.18 + l * 0.4) * k, (0.15 + l * 0.35) * k, 0

recolor('fragmento', 'emanacion', gel, lambda r, g, b: (0.70, 1.0, 0.55))
recolor('engendro', 'primigenio_menor', stone, lambda r, g, b: (0.35, 1.0, 0.55))
