"""Compara la versión de antes (arte=v1) y la nueva de un escenario en la misma vista.
Uso: python tools/comparar_arte.py <nivel|-> <x,z> <cam> <nombre> [arena=ruta]
Saca shots/cmp_<nombre>.png con las dos capturas (antes arriba, después abajo)."""
import subprocess, sys, os
from PIL import Image, ImageDraw
lvl, pos, cam, name = sys.argv[1:5]
extra = sys.argv[5:]
shots = []
for v in ('v1', 'v2'):
    tag = '%s_%s' % (name, v)
    args = ['godot', '--path', '.', '--', 'mute=true', 'god=true', 'pos=' + pos, 'cam=' + cam, 'shots=3', 'tag=' + tag,
            'weather=no'] + (['nolevel=true'] if lvl == '-' else ['level=' + lvl, 'spawn_rate=0', 'max_alive=0']) + extra
    if v == 'v1': args.append('arte=v1')
    subprocess.run(' '.join(args), shell=True, capture_output=True)
    shots.append('shots/game_%s_003.0s.png' % tag)
ims = [Image.open(s).convert('RGB').resize((960, 540)) for s in shots]
S = Image.new('RGB', (960, 1090), (20, 20, 20))
for i, im in enumerate(ims):
    S.paste(im, (0, i * 550))
    ImageDraw.Draw(S).text((12, i * 550 + 8), ('ANTES' if i == 0 else 'DESPUES'), fill=(255, 255, 0))
S.save('shots/cmp_%s.png' % name)
print('shots/cmp_%s.png' % name)
