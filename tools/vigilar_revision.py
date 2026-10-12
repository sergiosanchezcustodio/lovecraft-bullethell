"""Vigila review/peticiones.json (revisión de arte, temporal) e imprime una línea por cada
petición pendiente nueva. Lo lanza Claude con su herramienta Monitor: cada línea le llega como
aviso y atiende la petición (modifica el generador o rehace la imagen y marca 'hecho').

  python tools/vigilar_revision.py
"""
import json, os, sys, time

FILE = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'review', 'peticiones.json')
seen = set()
last = None
while True:
    try:
        m = os.path.getmtime(FILE)
    except OSError:
        m = None
    if m != last:
        last = m
        try:
            data = json.load(open(FILE, encoding='utf-8'))
        except Exception:
            data = {}
        for r in data.get('peticiones', []):
            if r.get('estado') == 'pendiente' and r.get('id') not in seen:
                seen.add(r.get('id'))
                print('PETICION %s [%s/%s] %s: %s' % (r.get('id'), r.get('seccion'), r.get('clave'),
                      r.get('nombre'), r.get('texto', '').replace('\n', ' ')), flush=True)
    time.sleep(3)
