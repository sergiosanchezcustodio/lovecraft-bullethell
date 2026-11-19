"""Clips del manual del investigador (hito 21.19): partidas cortas con bot grabadas con Godot y
pasadas a vídeo Theora para la Biblioteca (tomo «Manual del investigador», `Manual`, `data/manual.json`).

Cada página monta su escena con opciones de prueba (crisis_at, emitters, evolve_at, final_at,
objective…), se graba a 30 fps con --write-movie, se recorta el centro (el jugador) y se pasa a
640 × 360 con ffmpeg. El principio se descarta (fundido y rótulo del nivel).

  python tools/grabar_manual.py                 # todas
  python tools/grabar_manual.py crisis esquive  # solo esas
  python tools/grabar_manual.py --hoja          # además, hoja de fotogramas en tools/local/manual_<id>.png

Al juego: resources/manual/<id>.ogv. Necesita ffmpeg con libtheora en el PATH.
"""
import os, shutil, subprocess, sys, tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'resources', 'manual')
FPS = 30
QUALITY = 4                     # Theora, 0-10: con 4, la mitad que con 6 y casi igual a 640 × 360
COMMON = 'mute=true god=true cfg_quality=2 res=1280x720 tips=false night_events=false peddler=false bond_talk=false seed=7'

# id: (opciones, segundo en que empieza el clip, segundos que dura[, recortar el centro])
# 'nivel' va sin bot (con bot la subida se elige sola, sin ventana) y sin recorte (la ventana, entera).
CLIPS = {
    'cordura': ('level=p2_n1 character=varga bot=circle cam=10 crisis_at=6.5 '
                'foes=profundo,3,1;profundo,-2,2.5;hibrido_h,1,-3', 4.5, 7.0),
    'esquive': ('level=p2_n1 character=olmstead bot=circle dodge_every=0.9 cam=10 emitters=true objectives=false', 5.0, 6.0),
    'evolucion': ('level=p2_n1 character=malone bot=circle cam=10 weapons=thompson wlevel=5 items=oro_obed '
                  'evolve_at=6 evo_branch=0 autopick=true foes=profundo,4,1;profundo,-3,3;profundo,1,-4;hibrido_h,-4,-2',
                  4.5, 7.0),
    'elite': ('level=p2_n1 character=legrasse bot=idle dodge_every=999 cam=9 traits=escudo,icor '
              'foes=acechador,3.5,-2.5', 4.5, 7.0),
    'nivel': ('level=p2_n1 character=dyer cam=10 levelup_at=5.5 pick_after=2.6 xp=0 '
              'foes=profundo,4,1;profundo,-3,3;hibrido_h,1,-4', 4.5, 7.0, False),
    # hito 23.5: lo de las fases 16 a 21
    'signos': ('level=p1_n2 character=dyer bot=circle cam=10 signs=cthugha weapons=granada wlevel=4 '
               'foes=pinguino,4,1;pinguino,-3,3;pinguino,1,-4;pinguino,-4,-2;pinguino,3,-3', 4.5, 7.0),
    'vinculos': ('level=p2_n1 character=legrasse bots=1 bot_chars=johansen bot=circle cam=10 bond_talk=true objectives=false', 4.5, 7.0),
    'sucesos': ('level=p1_n2 character=peaslee bot=circle cam=12 night_events=true night_event=estrellas night_at=5 objectives=false', 4.5, 7.0, False),
    'revelaciones': ('level=p2_n1 character=varga cam=10 crisis_at=5 pick_after=2.6 '
                     'foes=profundo,3,1;profundo,-2,2.5;hibrido_h,1,-3', 4.5, 8.0, False),
    'objetivo': ('level=p2_n1 character=peaslee bot=idle dodge_every=999 cam=10 objective=ritual objective_at=4 objective_near=true', 4.5, 7.0),
}


def record(cid, opts, start, dur, sheet, crop=True):
    tmp = tempfile.mkdtemp(prefix='manual_')
    frames = int((start + dur) * FPS) + 10
    cmd = ['godot', '--path', '.', '--write-movie', os.path.join(tmp, 'f.png'), '--fixed-fps', str(FPS),
           '--quit-after', str(frames), '--'] + (COMMON + ' ' + opts).split()
    print('grabando', cid, flush=True)
    # con el comando godot de Git Bash (desde Claude Code abre la ventana en el escritorio aparte)
    subprocess.run(['bash', '-lc', ' '.join("'%s'" % c for c in cmd).replace('\\', '/')], cwd=ROOT,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    os.makedirs(OUT, exist_ok=True)
    dst = os.path.join(OUT, cid + '.ogv')
    first = int(start * FPS)
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-framerate', str(FPS), '-start_number', str(first),
                    '-i', os.path.join(tmp, 'f%08d.png'), '-frames:v', str(int(dur * FPS)),
                    '-vf', ('crop=920:518:180:100,' if crop else '') + 'scale=640:360:flags=lanczos,fade=t=in:st=0:d=0.4,fade=t=out:st=%.2f:d=0.4' % (dur - 0.4),
                    '-c:v', 'libtheora', '-q:v', str(QUALITY), '-an', dst], check=True)
    print('  ->', dst, '%d kB' % (os.path.getsize(dst) // 1024), flush=True)
    if sheet:
        from PIL import Image
        os.makedirs(os.path.join(ROOT, 'tools', 'local'), exist_ok=True)
        ims = []
        for k in range(6):
            i = first + int(k * (dur * FPS - 1) / 5)
            ims.append(Image.open(os.path.join(tmp, 'f%08d.png' % i)).convert('RGB').crop((180, 100, 1100, 618) if crop else (0, 0, 1280, 720)).resize((640, 360)))
        o = Image.new('RGB', (1280, 1080))
        for k, im in enumerate(ims): o.paste(im, ((k % 2) * 640, (k // 2) * 360))
        o.save(os.path.join(ROOT, 'tools', 'local', 'manual_%s.png' % cid))
    shutil.rmtree(tmp, ignore_errors=True)


def main():
    args = sys.argv[1:]
    ids = [a for a in args if a in CLIPS] or list(CLIPS)
    for cid in ids:
        o, s, d = CLIPS[cid][:3]
        record(cid, o, s, d, '--hoja' in args, CLIPS[cid][3] if len(CLIPS[cid]) > 3 else True)


if __name__ == '__main__':
    main()
