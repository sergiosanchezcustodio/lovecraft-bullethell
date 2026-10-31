"""Ordena la carpeta shots/ por temas y fechas (14-10-2026).

Las capturas nuevas siguen cayendo en la raíz de shots/ (el juego y las herramientas escriben
ahí); este script las reparte cuando se acumulan:

  shots/partida/AAAA-MM-DD/      capturas de la partida (game_*)
  shots/revision/AAAA-MM-DD/     hojas de revisión y comparaciones (rev_*, revision_*, cmp_*, hoja_*, fix_*)
  shots/modelos/<grupo>/         renders de modelos con `still` y `anim`
                                 (personajes, enemigos, companeros, atrezo, vestuario, otros)
  shots/menus/                   portada, selección, tienda, biblioteca, HUD...
  shots/videos/                  gif, mp4 y carpetas de fotogramas (mov*)
  shots/referencias/             material de referencia (ref_*)

Actualiza también las rutas `shots/...` de CLAUDE.md y docs/*.md que apunten a archivos movidos.
Uso: python tools/ordenar_shots.py [--prueba]   (--prueba: solo cuenta, no mueve nada)
"""
import os, re, sys, time, shutil

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
SH = os.path.join(ROOT, 'shots')
DRY = '--prueba' in sys.argv

PERSONAJES = {'dyer', 'olmstead', 'legrasse', 'johansen', 'peaslee', 'varga', 'whipple', 'blake', 'iwanicki',
              'elwood', 'malone', 'armitage', 'west', 'anciano', 'lineup', 'humano', 'personajes', 'cuerpo',
              'cabezas', 'manos', 'innsmouth'}
COMPANEROS = {'perro', 'gato', 'rata', 'sapo', 'buho', 'shoggoth', 'byakhee', 'cuervo', 'polilla', 'gaviota',
              'mi', 'migo', 'tindalos', 'yig', 'dhole', 'pez', 'cabra', 'mascotas', 'pet'}
ENEMIGOS = {'pinguino', 'fragmento', 'acechador', 'clasico', 'bruto', 'abisal', 'antiguo', 'profundo', 'hydra',
            'dagon', 'cthulhu', 'engendro', 'diablo', 'pesadilla', 'polipo', 'primigenio', 'hibrido', 'cultista',
            'sacerdote', 'acolito', 'diacono', 'sumo', 'pescador', 'vecino', 'barnabas', 'pththya', 'emanacion',
            'shoggoth_grande', 'shoggoth_ojos', 'vecinos', 'mujer', 'viejo', 'enemigos', 'bestiario'}
ATREZO = {'atrezo', 'inn', 'alr', 'prv', 'rly', 'lui', 'pan', 'tej', 'arr', 'prt', 'cth', 'costa', 'tempano',
          'monticulo', 'iceberg', 'barrera', 'muro', 'proj', 'icono', 'recompensa', 'gema', 'tienda'}
MENUS = {'titulo', 'portada', 'seleccion', 'select', 'menu', 'biblioteca', 'hud', 'ficha', 'logros', 'intro',
         'relato', 'mapa', 'tienda', 'nivel', 'pausa', 'levelup', 'tragaperras', 'vest', 'debug', 'panel'}
REVISION = ('rev_', 'revision_', 'cmp_', 'hoja', 'fix_', 'mascaras_')


def day(path):
    return time.strftime('%Y-%m-%d', time.localtime(os.path.getmtime(path)))


def dest(name, path):
    low = name.lower()
    ext = os.path.splitext(low)[1]
    first = re.split(r'[_\-.]', low)[0]
    if os.path.isdir(path):
        if low.startswith('mov'): return 'videos'
        if low.startswith('ref'): return 'referencias'
        return None
    if ext in ('.gif', '.mp4', '.webm', '.ogv', '.avi'): return 'videos'
    if low.startswith('ref_'): return 'referencias'
    if low.startswith('game_'): return 'partida/' + day(path)
    if low.startswith(REVISION): return 'revision/' + day(path)
    if first.startswith('vest'): return 'modelos/vestuario'
    if first in PERSONAJES: return 'modelos/personajes'
    if first in ENEMIGOS: return 'modelos/enemigos'
    if first in COMPANEROS: return 'modelos/companeros'
    if first in ATREZO: return 'modelos/atrezo'
    if first in MENUS: return 'menus'
    if first == 'anim': return 'modelos/otros'
    return 'otros/' + day(path)


def main():
    moved = {}
    counts = {}
    keep = {'partida', 'revision', 'modelos', 'menus', 'videos', 'referencias', 'otros', 'LEEME.md', '.gdignore', '.gitkeep'}
    for name in sorted(os.listdir(SH)):
        if name in keep: continue
        p = os.path.join(SH, name)
        d = dest(name, p)
        if d is None: continue
        counts[d.split('/')[0]] = counts.get(d.split('/')[0], 0) + 1
        moved['shots/' + name] = 'shots/%s/%s' % (d, name)
        if DRY: continue
        os.makedirs(os.path.join(SH, d), exist_ok=True)
        shutil.move(p, os.path.join(SH, d, name))
    for k, v in sorted(counts.items()): print('%-12s %5d' % (k, v))
    if DRY or not moved: return
    # rutas en la documentación
    docs = [os.path.join(ROOT, p, 'CLAUDE.md') for p in ('', 'tools', 'scripts', os.path.join('scripts', 'title'))] + [os.path.join(ROOT, 'docs', f) for f in os.listdir(os.path.join(ROOT, 'docs')) if f.endswith('.md')]
    rx = re.compile(r'shots/[A-Za-z0-9_.\-]+')
    for f in docs:
        t = open(f, encoding='utf-8').read()
        n = rx.sub(lambda m: moved.get(m.group(0), m.group(0)), t)
        if n != t:
            open(f, 'w', encoding='utf-8').write(n)
            print('rutas actualizadas en', os.path.relpath(f, ROOT))


if __name__ == '__main__': main()
