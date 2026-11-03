"""Partida de prueba para la sala de trofeos (hito 16.28): copia el hueco 2 de demo_saves en
user://trofeos_saves (los tres huecos) con doce jefes vencidos, cinco conjuntos completos y siete
logros grandes. Uso: python tools/partida_trofeos.py "%APPDATA%/Godot/app_userdata/Lovecraft Bullet Hell"
y después: godot --path . -- title saves=trofeos_saves open=menu_biblioteca tome=10
"""
import os, sys, json
U=sys.argv[1]
os.makedirs(U + "/trofeos_saves", exist_ok=True)
d=json.load(open(U+'/demo_saves/slot_2.json',encoding='utf-8'))
b=d.setdefault('records',{}).setdefault('bestiary',{})
for e,n,by in [('antiguo_despierto',4,'dyer'),('gedney',3,'legrasse'),('shoggoth_caverna',2,'dyer'),('guardian_ciudad',2,'peaslee'),('shoggoth_primigenio',1,'dyer'),('diacono',2,'olmstead'),('sumo_sacerdote',1,'olmstead'),('obed_marsh',1,'varga'),('barnabas',1,'johansen'),('dagon',1,'johansen'),('hydra',1,'johansen'),('castro',1,'carter')]:
    b[e]={'kills':n,'by':{by:n}}
sets=json.load(open('data/outfit_sets.json',encoding='utf-8'))['sets']
own=set(d.get('outfits',[]))
for s in sets:
    if s['id'] in ('cultista','ganster','buzo','peste','caballero'): own|=set(s['pieces'].values())
d['outfits']=sorted(own)
a=dict(d.get('achievements',{}))
for k in ('cazador_10000','elites_25','baules_50','rico','bibliotecario','siete_noches','tres_sellos'): a[k]='2026-11-03T12:00:00'
d['achievements']=a
for n in (1,2,3): json.dump(d,open(U+'/trofeos_saves/slot_%d.json'%n,'w',encoding='utf-8'))
print('ok')
