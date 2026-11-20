"""Lanza un comando y limita los procesos de Godot que salgan de él a unos núcleos (hito 23.7: medir
como en un portátil de 4 núcleos sin tener uno). La afinidad se pone en cuanto aparece el proceso
(en el primer segundo, antes de medir nada) y se repite por si arranca otro; al acabar, dice qué
máscara tenía. Uso:
  python tools/afinidad.py 4 -- godot --path . -- level=p3_n2 bot=smart perf=20
`4`: cuatro núcleos físicos (uno de cada pareja del hyperthreading: 0, 2, 4, 6); `4l`: los cuatro
primeros lógicos (dos físicos con hyperthreading, lo más parecido a un portátil flojo de 2+2).
"""
import subprocess
import sys
import time

import psutil


def cpus(spec):
    n = int(spec.rstrip('l'))
    if spec.endswith('l'): return list(range(n))
    step = psutil.cpu_count() // psutil.cpu_count(logical=False)
    return [i * step for i in range(n)]


def main():
    i = sys.argv.index('--')
    want = cpus(sys.argv[1])
    cmd = sys.argv[i + 1:]
    p = subprocess.Popen(['bash', '-lc', ' '.join("'%s'" % c for c in cmd)])
    seen = {}
    while p.poll() is None:
        for q in psutil.process_iter(['name']):
            try:
                if 'godot' in (q.info['name'] or '').lower() and q.pid not in seen:
                    q.cpu_affinity(want)
                    seen[q.pid] = q.cpu_affinity()
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                pass
        time.sleep(0.2)
    print('AFINIDAD', sys.argv[1], ' '.join('%d:%s' % (k, v) for k, v in seen.items()), flush=True)
    sys.exit(p.returncode)


if __name__ == '__main__':
    main()
