"""Partida de prueba «del juego completo» (hito 23.2): todo visto, ganado y comprado.

La usa tools/probar_demo.sh para abrir la demo como la abriría alguien que ya tiene el juego entero
(comparten la partida): la Biblioteca enseña todas las criaturas, lugares, relatos y finales, la
tienda tiene todos los personajes y todas las prendas, y el vestuario los lleva puestos.

Uso: python tools/partida_completa.py [carpeta]   (por defecto, user://demo_completa/slot_1.json)
"""
import glob
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
USER = os.path.join(os.environ.get('APPDATA', ''), 'Godot', 'app_userdata', 'Lovecraft Bullet Hell')


def ids(folder):
    return sorted(os.path.basename(p)[:-5] for p in glob.glob(os.path.join(ROOT, 'data', folder, '*.tres')))


def main():
    out_dir = os.path.join(USER, sys.argv[1] if len(sys.argv) > 1 else 'demo_completa')
    os.makedirs(out_dir, exist_ok=True)
    levels = ids('levels')
    chars = ids('characters')
    outfits = ids('outfits')
    enemies = ids('enemies')
    pets = ids('pets')
    weapons = ids('weapons')
    items = ids('upgrades')
    fishing = json.load(open(os.path.join(ROOT, 'data', 'fishing.json'), encoding='utf-8')).get('catches', [])
    stories = json.load(open(os.path.join(ROOT, 'data', 'fragments.json'), encoding='utf-8'))
    pages = sorted(set(re.findall(r'"level"\s*:\s*"([^"]+)"', json.dumps(stories))))
    save = {
        'version': 2, 'rev': 1, 'cloud_base': -1, 'created': '2026-11-18T12:00:00', 'updated': '2026-11-18T12:00:00',
        'created_with': '0.9.0', 'saved_with': '0.9.0', 'device': 'PRUEBA', 'unlock_all': False,
        'money': 999999, 'play_time': 36000.0,
        'levels_won': levels, 'characters': chars, 'outfits': outfits, 'pets': pets,
        'purchases': {}, 'achievements': {}, 'toggles': {},
        # Dyer con prendas puestas; y Pickman, que no es de la demo, también (no debe pedirlas)
        'worn': {'dyer': {'body': 'abrigo_nieve', 'feet': 'zapatos_tacon'}, 'pickman': {'body': 'abrigo_nieve', 'feet': 'zapatos_tacon'}},
        'seen': {'enemies': enemies, 'places': levels, 'weapons': weapons, 'items': items,
                 'epilogues': ['epilogo', 'epilogo_locura', 'epilogo_kadath']},
        'records': {'bestiary': {e: {'kills': 10.0, 'by': {'dyer': 10.0}} for e in enemies},
                    'fragments': pages,
                    'fishing': {str(c.get('id')): {'caught': 1, 'kept': 1} for c in fishing}},
        'stats': {},
    }
    path = os.path.join(out_dir, 'slot_1.json')
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(save, f, ensure_ascii=False, indent=1)
    print('partida completa:', path, '(%d niveles, %d criaturas, %d personajes, %d prendas)' % (
        len(levels), len(enemies), len(chars), len(outfits)))


if __name__ == '__main__':
    main()
