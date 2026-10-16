"""Graba un clip de una arena para revisar lo que se mueve (ambiente de los escenarios, 16-10-2026).

  python tools/grabar_clip.py <arena> [--s 8] [--fps 30] [--pos x,z] [--cam 15] [--extra "..."] [--nombre x]

Graba con --write-movie (fotogramas PNG a tiempo fijo, en ventana) y deja:
  shots/videos/amb_<nombre>.mp4      el clip (ffmpeg, H.264)
  shots/videos/amb_<nombre>_tira.png 6 fotogramas repartidos (para comparar a ojo)
  --keep: deja también los fotogramas en shots/videos/amb_<nombre>_fotogramas/
"""
import subprocess, sys, os, glob, shutil, tempfile
from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
args = sys.argv[1:]
def opt(k, d): return args[args.index(k) + 1] if k in args else d
arena = args[0]
secs = float(opt('--s', '8')); fps = int(opt('--fps', '30'))
name = opt('--nombre', arena)
tmp = tempfile.mkdtemp(prefix='clip_')
frames = int(secs * fps)
cmd = ['godot', '--path', '.', '--resolution', opt('--res', '1280x720'), '--write-movie', os.path.join(tmp, 'f.png'),
       '--fixed-fps', str(fps), '--quit-after', str(frames + 30), '--',
       'nolevel=true', 'arena=res://data/arenas/%s.json' % arena, 'mute=true', 'god=true', 'noweapons=true', 'nobreakables=true', 'cam=' + opt('--cam', '15')]
if '--pos' in args: cmd.append('pos=' + opt('--pos', '0,0'))
cmd += opt('--extra', '').split()
subprocess.run(' '.join(cmd), shell=True, cwd=ROOT, capture_output=True)
fs = sorted(glob.glob(os.path.join(tmp, 'f*.png')))[30:]          # sin el primer segundo (carga)
out = os.path.join(ROOT, 'shots', 'videos'); os.makedirs(out, exist_ok=True)
mp4 = os.path.join(out, 'amb_%s.mp4' % name)
subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-framerate', str(fps), '-start_number', '30', '-i', os.path.join(tmp, 'f%08d.png'),
                '-frames:v', str(len(fs)), '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '20', mp4])
if fs:
    pick = [fs[int(i * (len(fs) - 1) / 5)] for i in range(6)]
    ims = [Image.open(p).convert('RGB') for p in pick]
    w, h = ims[0].size
    sheet = Image.new('RGB', (w * 3, h * 2))
    for i, im in enumerate(ims): sheet.paste(im, ((i % 3) * w, (i // 3) * h))
    sheet = sheet.resize((w * 3 // 2, h))
    sheet.save(os.path.join(out, 'amb_%s_tira.png' % name))
print('%d fotogramas -> %s' % (len(fs), mp4))
if '--keep' in args:                                                # fotogramas sueltos (comprobar de cerca)
    kd = os.path.join(out, 'amb_%s_fotogramas' % name); shutil.rmtree(kd, ignore_errors=True); shutil.copytree(tmp, kd, dirs_exist_ok=True)
    print('fotogramas en', kd)
shutil.rmtree(tmp, ignore_errors=True)
