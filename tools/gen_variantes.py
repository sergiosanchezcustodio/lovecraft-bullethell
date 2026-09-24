"""Generador paramétrico de Profundos voxel (S=2 => 32 voxels/m). Sin ropa ni adornos."""
import json, math, random
S=2
def build(cfg):
    random.seed(cfg['seed']); V={}
    P=cfg['pal']
    def put(x,y,z,part,col,glow=0,over=True):
        k=(int(math.floor(x)),int(math.floor(y)),int(math.floor(z)))
        if over or k not in V: V[k]=[part,col,glow]
    def ell(cx,cy,cz,rx,ry,rz,part,col,over=True):
        cx,cy,cz,rx,ry,rz=[v*S for v in (cx,cy,cz,rx,ry,rz)]
        for x in range(int(cx-rx)-2,int(cx+rx)+2):
            for y in range(int(cy-ry)-2,int(cy+ry)+2):
                for z in range(int(cz-rz)-2,int(cz+rz)+2):
                    if ((x+.5-cx)/rx)**2+((y+.5-cy)/ry)**2+((z+.5-cz)/rz)**2<=1: put(x,y,z,part,col,0,over)
    def capsule(a,b,r0,r1,part,col,over=True):
        n=int(max(abs(b[i]-a[i]) for i in range(3))*S*2)+1
        for i in range(n+1):
            t=i/n; c=[a[k]+(b[k]-a[k])*t for k in range(3)]; r=r0+(r1-r0)*t
            ell(c[0],c[1],c[2],r,r,r,part,col,over)
    def spike(a,b,r,part,cb,ct):          # púa cónica con degradado base->punta
        n=int(max(abs(b[i]-a[i]) for i in range(3))*S*2.5)+1
        for i in range(n+1):
            t=i/n; c=[a[k]+(b[k]-a[k])*t for k in range(3)]; rr=max(0.3,r*(1-t))
            col=tuple(cb[j]*(1-t)+ct[j]*t for j in range(3))
            ell(c[0],c[1],c[2],rr,rr,rr,part,col)
    def surf_front(x,y):
        zs=[k[2] for k in V if k[0]==x and k[1]==y]; return max(zs) if zs else None
    def surf_top(x,z,parts=None):
        ys=[k[1] for k,v in V.items() if k[0]==x and k[2]==z and (parts is None or v[0] in parts)]; return max(ys) if ys else None
    c=cfg
    # ---------------- PIERNAS
    hip=c['hip']; sw=c['stance']
    for s in (-1,1):
        p='leg_l' if s<0 else 'leg_r'
        knee=(s*(sw+0.4),hip*0.52,c['knee_fwd']); ank=(s*(sw+0.6),1.4,-0.3)
        capsule((s*sw,hip,0),knee,c['thigh_r'],c['thigh_r']*0.8,p,'skin')
        capsule(knee,ank,c['thigh_r']*0.7,c['thigh_r']*0.55,p,'skin')
        for tx in (-1.6,0,1.6):
            capsule((s*(sw+0.6)+tx*0.5,0.6,0.5),(s*(sw+0.6)+tx*1.1,0.45,c['foot_len']),0.8,0.5,p,'hand')
            put((s*(sw+0.6)+tx*1.1)*S,0,(c['foot_len']+0.5)*S,p,'claw'); put((s*(sw+0.6)+tx*1.1)*S,0,(c['foot_len']+1.0)*S,p,'claw')
        for x in range(int((s*(sw+0.6)-1.8)*S),int((s*(sw+0.6)+1.8)*S)+1):
            for z in range(2*S,int(c['foot_len']*S)): put(x,0,z,p,'web',over=False)
    # ---------------- TORSO
    ty=c['torso_y']; tw,th,td=c['torso_r']
    ell(0,ty,0.5,tw,th,td,'torso','skin')
    ell(0,ty+th*0.55,-c['hump'],tw*1.05,th*0.7,td*0.95,'torso','skin')
    # ---------------- CABEZA
    hx,hy,hz=0,c['head_y'],c['head_z']; hw,hh,hd=c['head_r']
    ell(hx,hy,hz,hw,hh,hd,'head','skin')
    ell(0,hy-hh*0.55,hz+0.6,hw*c['jaw_w'],hh*0.6,hd*0.95,'head','skin')      # mandíbula
    if c.get('brow'):
        for s in (-1,1):
            capsule((s*1.2,hy+hh*0.35,hz+hd*0.8),(s*hw*0.85,hy+hh*0.62,hz+hd*0.35),1.3,1.1,'head','skin')
    # ---------------- BRAZOS
    al=c['arm_len']
    for s in (-1,1):
        p='arm_l' if s<0 else 'arm_r'
        sh=(s*(tw+0.9),ty+th*0.55,0.5); el=(s*(tw+2.0),sh[1]-5.5*al,2.3); wr=(s*(tw+1.6),sh[1]-10.5*al,c['wrist_z'])
        ell(*sh,c['arm_r']*1.35,c['arm_r']*1.4,c['arm_r']*1.35,p,'skin'); capsule(sh,el,c['arm_r'],c['arm_r']*0.85,p,'skin'); capsule(el,wr,c['arm_r']*0.85,c['arm_r']*0.7,p,'skin')
        ell(wr[0],wr[1]-1.1,wr[2]+0.5,1.9*c['hand'],1.5*c['hand'],1.8*c['hand'],p,'hand')
        for dx in (-1.2,0,1.2):
            a=(wr[0]+dx*c['hand'],wr[1]-2,wr[2]+1); b=(wr[0]+dx*1.35*c['hand'],wr[1]-2-2.2*c['hand']*c['finger'],wr[2]+2.3)
            capsule(a,b,0.6,0.45,p,'hand')
            for k in range(int(3*c['claw'])): put(b[0]*S,(b[1]-0.4)*S-k,b[2]*S+(1 if k<2 else 0),p,'claw')
        if c.get('arm_spines'):
            for i in range(4):
                t=0.2+i*0.2; b=[el[j]*(1-t)+wr[j]*t for j in range(3)]; b[2]-=c['arm_r']*0.6
                spike(b,(b[0]+s*0.9,b[1]+0.5,b[2]-1.8),0.7,p,P['spine_b'],P['spine_t'])
    # ---------------- COLOREADO base (escamas, vientre, dorso)
    for k,v in V.items():
        x,y,z=k; p,col=v[0],v[1]
        if not isinstance(col,str): continue
        zc=z/S; xc=abs((x+.5)/S)
        if col=='skin':
            belly=(p=='torso' and zc>td*0.6 and xc<tw*0.55) or (p=='head' and y<(hy-hh*0.45)*S and zc>hz+1 and xc<hw*0.7)
            if belly:
                base=P['belly'] if (y//2)%2 else tuple(q*0.8 for q in P['belly'])
            else:
                base=P['dorsal'] if zc<-0.5 or (p=='head' and y>(hy+hh*0.45)*S) else P['side']
                if (x+y)%4==0 or (y-x+z)%4==0: base=tuple(q*0.84 for q in base)
                elif ((x+y)//4+(y-x+z)//4)%6==0: base=tuple(min(1,q*1.12) for q in base)
                if random.random()<P.get('spot_p',0.03): base=P['spot']
            v[1]=base
        elif col=='hand': v[1]=P['side'] if random.random()>0.2 else tuple(q*0.8 for q in P['side'])
        elif col=='web': v[1]=tuple(q*0.7 for q in P['dorsal'])
        elif col=='claw': v[1]=P['claw']
    # ---------------- BOCA
    mw=hw*c['mouth_w']; droop=c['mouth_droop']; my=hy-hh*0.35
    for x in range(int(-mw*S),int(mw*S)):
        xr=abs((x+.5)/S)/mw
        yb=my*S-(xr**2)*droop*S
        gap=max(1,int((1-xr**2)*c['mouth_gap']))
        for y in range(int(yb)-gap//2,int(yb)+gap-gap//2+1):
            zf=surf_front(x,y)
            if zf is None: continue
            for d in range(4):
                if (x,y,zf-d) in V:
                    if d<2 and xr<0.92: del V[(x,y,zf-d)]
                    else: V[(x,y,zf-d)][1]=P['maw'] if d>=2 else P['gum']
        if xr<0.88 and random.random()<c['teeth']:
            top=int(yb)+gap-gap//2; zf=surf_front(x,top+1) or 0
            for k in range(random.choice(c['tooth_len'])): put(x,top-k,zf-1,'head',P['tooth'])
        if xr<0.8 and random.random()<c['teeth']*0.7:
            bot=int(yb)-gap//2-1; zf=surf_front(x,bot) or 0
            for k in range(random.choice(c['tooth_len'][:2])): put(x,bot+1+k,zf-1,'head',P['tooth'])
    # ---------------- OJOS
    er=c['eye_r']
    for s in (-1,1):
        ex,ey,ez=s*hw*c['eye_x'],hy+hh*c['eye_y'],hz+hd*c['eye_z']
        ell(ex,ey,ez,er+0.35,er+0.35,er+0.35,'head',P['socket'])
        ell(ex+s*0.35,ey,ez+0.25,er,er,er,'head','eye')
        for k,v in V.items():
            if v[1]=='eye': v[1]=P['eye']; v[2]=1 if c.get('eye_glow') else 2
        cc=((ex+s*0.35)*S,ey*S,(ez+0.25)*S); r=er*S
        d=(s*c['look_side'],0.0,math.sqrt(1-c['look_side']**2))
        for k,v in list(V.items()):
            if v[2] in (1,2):
                rel=(k[0]+.5-cc[0],k[1]+.5-cc[1],k[2]+.5-cc[2])
                dot=(rel[0]*d[0]+rel[1]*d[1]+rel[2]*d[2])/r
                side=abs(rel[0]*d[2]-rel[2]*d[0])/r
                if dot>0.70 and (abs(rel[1])/r<c['pupil'][1]) and side<c['pupil'][0]: v[1]=P['pupil']; v[2]=0
        for k,v in V.items():
            if v[2]==2: v[2]=0
        if c.get('brow'):
            for x in range(int((ex-er-0.5)*S),int((ex+er+0.5)*S)+1):
                for z in range(int((ez-er)*S),int((ez+er+1)*S)):
                    y=int((ey+er*0.75)*S)
                    if (x,y,z) in V and V[(x,y,z)][2]==0 and V[(x,y,z)][1]!=P['pupil']: V[(x,y,z)][1]=P['dorsal']
    # ---------------- AGALLAS
    for s in (-1,1):
        for gy in c['gills']:
            y=int(gy*S)
            for z in range(int(0.3*S),int(3.0*S)):
                xs_=[k[0] for k in V if k[1]==y and k[2]==z and (k[0]>0 if s>0 else k[0]<0) and V[k][0] in('torso','head')]
                if xs_:
                    xx=max(xs_) if s>0 else min(xs_); V[(xx,y,z)][1]=P['gill']
    # ---------------- CRESTA
    crest=c['crest']
    zs=list(range(int(c['crest_z'][0]*S),int(c['crest_z'][1]*S)))
    tops={z:surf_top(0,z,('head','torso')) for z in zs}
    for z in zs:
        top=tops[z]
        if top is None: continue
        part='head' if z>=int((hz-hd*0.4)*S) else 'torso'
        zb=(z-zs[0])/len(zs)
        H=int((c['crest_h'][0]+c['crest_h'][1]*math.sin(zb*math.pi))*S)
        if crest in('fin','both'):
            ray=(z%5==0); h=H if ray else int(H*0.7)
            for k in range(1,h+1):
                col=P['fin_ray'] if ray else (P['fin'] if k<h-1 else tuple(q*1.4 for q in P['fin']))
                put(0,top+k,z,part,col); put(-1,top+k,z,part,col)
    if crest in('spines','both'):
        step=c['spine_step']
        for i,z in enumerate(zs[::step]):
            top=tops[z]
            if top is None: continue
            part='head' if z>=int((hz-hd*0.4)*S) else 'torso'
            zb=(z-zs[0])/len(zs); L=(c['crest_h'][0]+c['crest_h'][1]*math.sin(zb*math.pi))*c['spine_len']
            b=(0,top/S-0.3,z/S); spike(b,(0,b[1]+L*0.8,b[2]-L*0.6),c['spine_r'],part,P['spine_b'],P['spine_t'])
            if c.get('side_spines') and i%2==0:
                for s in (-1,1):
                    tt=surf_top(int(s*2.2*S),z,('head','torso'))
                    if tt: bb=(s*2.2,tt/S-0.3,z/S); spike(bb,(s*3.2,bb[1]+L*0.4,bb[2]-L*0.5),c['spine_r']*0.7,part,P['spine_b'],P['spine_t'])
    # ---------------- EXTRAS biológicos
    if c.get('warts'):
        for k,v in list(V.items()):
            if v[0] in('head','torso') and v[2]==0 and random.random()<c['warts']:
                n=(k[0],k[1]+1,k[2])
                if n not in V and v[1] not in (P['tooth'],P['maw'],P['gum'],P['pupil'],P['eye']): V[n]=[v[0],P['wart'],0]
    if c.get('biolum'):
        for k,v in list(V.items()):
            if v[0] in('head','torso','arm_l','arm_r','leg_l','leg_r') and v[2]==0 and v[1] not in(P['tooth'],P['maw'],P['pupil']):
                x,y,z=k
                exposed=any((x+a,y+b,z+cc_) not in V for a,b,cc_ in((1,0,0),(-1,0,0),(0,0,1),(0,0,-1),(0,1,0)))
                if not exposed: continue
                line = (abs(x)>=int(3*S) and abs(z-int(0.5*S))<=1 and y%3==0) or (v[0]=='head' and abs(x)>=int(4*S) and abs(y-int(20*S))<=0 and z%3==0)
                if line or random.random()<c['biolum']: v[1]=P['lum']; v[2]=1
    out=[]
    for (x,y,z),(p,col,g) in V.items():
        if isinstance(col,str): col=P['side']
        j=random.uniform(-0.022,0.022)
        out.append([x,y,z,p,round(max(0,col[0]+j),3),round(max(0,col[1]+j),3),round(max(0,col[2]+j),3),g])
    pv={'torso':[0,hip,0],'head':[0,hy-hh*0.8,hz-1],'arm_l':[-(tw+0.9),ty+th*0.55,0.5],'arm_r':[tw+0.9,ty+th*0.55,0.5],
        'leg_l':[-sw,hip+0.5,0],'leg_r':[sw,hip+0.5,0]}
    return {'voxels':out,'pivots':{k:[a*S for a in v] for k,v in pv.items()},'name':c['name']}

BASE=dict(seed=1,hip=9,stance=3.6,knee_fwd=2.2,thigh_r=2.3,foot_len=4.3,torso_y=12.5,torso_r=(6,5.2,4.4),hump=1.2,
    head_y=20.5,head_z=4.0,head_r=(6.6,4.2,5.6),jaw_w=0.92,arm_len=1.0,arm_r=1.6,wrist_z=4.3,hand=1.0,finger=1.0,claw=1.0,
    mouth_w=0.9,mouth_droop=2.4,mouth_gap=3.5,teeth=0.55,tooth_len=[1,2,2,3],eye_r=1.9,eye_x=0.8,eye_y=0.35,eye_z=0.35,
    look_side=0.55,pupil=(0.45,0.25),gills=(15,16.3,17.6),crest='fin',crest_z=(-6,8.5),crest_h=(1.5,3.2),spine_step=5,
    spine_len=1.0,spine_r=0.9)
VAR=[
 dict(BASE,name='Clasico',seed=3,torso_r=(4.5,5.9,3.6),torso_y=14.0,hip=11.5,thigh_r=1.6,arm_r=1.15,arm_len=1.22,head_y=22.0,head_r=(5.8,3.9,6.4),head_z=4.8,stance=3.0,
      eye_r=2.0,eye_x=0.84,eye_z=0.3,look_side=0.72,pupil=(0.42,0.42),crest='spines',spine_step=3,spine_len=1.0,crest_h=(1.4,2.4),
      mouth_droop=2.0,arm_spines=True,side_spines=False,
      pal=dict(dorsal=(0.12,0.16,0.14),side=(0.25,0.30,0.25),belly=(0.52,0.52,0.42),spot=(0.08,0.10,0.09),claw=(0.2,0.2,0.16),
               eye=(0.80,0.78,0.36),pupil=(0.02,0.02,0.02),socket=(0.05,0.07,0.06),maw=(0.12,0.02,0.03),gum=(0.38,0.10,0.12),
               tooth=(0.82,0.80,0.66),gill=(0.50,0.10,0.12),fin=(0.2,0.2,0.18),fin_ray=(0.5,0.48,0.4),spine_b=(0.10,0.12,0.10),
               spine_t=(0.62,0.60,0.50),spot_p=0.06)),
 dict(BASE,name='Bruto',seed=8,torso_r=(7.6,6.0,5.4),hump=2.0,torso_y=12.8,hip=8.5,stance=4.4,thigh_r=3.0,arm_r=2.3,arm_len=0.9,
      hand=1.35,finger=1.1,claw=1.3,head_r=(7.4,4.6,5.8),head_y=21.0,jaw_w=1.08,brow=True,eye_r=1.35,eye_x=0.62,eye_y=0.38,eye_z=0.62,
      look_side=0.3,pupil=(0.3,0.3),mouth_w=0.95,mouth_droop=3.2,mouth_gap=4.5,teeth=0.85,tooth_len=[1,2,3,3],crest='both',
      crest_h=(1.2,2.8),spine_step=6,spine_len=0.9,warts=0.035,wrist_z=4.8,
      pal=dict(dorsal=(0.07,0.10,0.06),side=(0.19,0.23,0.14),belly=(0.40,0.40,0.28),spot=(0.28,0.30,0.20),claw=(0.15,0.14,0.10),
               eye=(0.95,0.75,0.12),pupil=(0.02,0.01,0.0),socket=(0.03,0.04,0.02),maw=(0.10,0.02,0.02),gum=(0.35,0.08,0.08),
               tooth=(0.80,0.74,0.55),gill=(0.45,0.08,0.08),fin=(0.14,0.16,0.08),fin_ray=(0.40,0.38,0.24),spine_b=(0.08,0.09,0.05),
               spine_t=(0.55,0.52,0.36),wart=(0.30,0.32,0.22),spot_p=0.02)),
 dict(BASE,name='Acechador',seed=5,hip=6.5,knee_fwd=3.6,stance=4.6,thigh_r=2.2,torso_y=10.5,torso_r=(5.6,4.6,4.8),hump=2.2,
      head_y=17.2,head_z=5.2,head_r=(7.2,3.6,6.0),arm_len=0.82,arm_r=1.4,hand=1.25,finger=1.2,wrist_z=5.5,
      eye_r=2.5,eye_x=0.62,eye_y=0.78,eye_z=0.25,look_side=0.45,pupil=(0.18,0.34),mouth_w=1.0,mouth_droop=1.4,mouth_gap=2.6,
      teeth=0.6,crest='spines',crest_z=(-6,9),crest_h=(2.2,3.6),spine_step=3,spine_len=1.25,spine_r=1.0,side_spines=True,gills=(13,14.2,15.4),
      pal=dict(dorsal=(0.04,0.09,0.09),side=(0.10,0.19,0.18),belly=(0.36,0.38,0.30),spot=(0.18,0.28,0.26),claw=(0.12,0.12,0.10),
               eye=(0.98,0.78,0.20),pupil=(0.02,0.02,0.02),socket=(0.02,0.04,0.04),maw=(0.12,0.02,0.04),gum=(0.40,0.10,0.12),
               tooth=(0.85,0.82,0.70),gill=(0.50,0.10,0.14),fin=(0.1,0.1,0.1),fin_ray=(0.4,0.4,0.4),spine_b=(0.20,0.18,0.12),
               spine_t=(0.90,0.84,0.62),spot_p=0.05)),
 dict(BASE,name='Abisal',seed=12,torso_r=(5.4,5.2,4.2),head_r=(6.8,4.4,6.4),head_z=4.4,eye_r=2.0,eye_x=0.8,look_side=0.6,
      pupil=(0.0,0.0),eye_glow=True,mouth_w=0.98,mouth_droop=1.2,mouth_gap=4.8,teeth=0.75,tooth_len=[2,3,3,4],crest='fin',
      crest_h=(1.4,3.0),arm_len=1.08,arm_spines=True,biolum=0.0012,
      pal=dict(dorsal=(0.02,0.03,0.06),side=(0.06,0.08,0.14),belly=(0.16,0.18,0.24),spot=(0.10,0.12,0.20),claw=(0.25,0.28,0.35),
               eye=(0.55,0.95,1.0),pupil=(0.0,0.0,0.0),socket=(0.01,0.01,0.02),maw=(0.03,0.01,0.03),gum=(0.18,0.05,0.12),
               tooth=(0.85,0.88,0.92),gill=(0.20,0.45,0.55),fin=(0.05,0.07,0.12),fin_ray=(0.10,0.15,0.24),spine_b=(0.05,0.06,0.1),
               spine_t=(0.4,0.5,0.6),lum=(0.35,0.95,1.0),spot_p=0.02)),
]
if __name__=='__main__':
    import sys
    for cfg in VAR:
        m=build(cfg); json.dump(m,open(f"models/{cfg['name'].lower()}.json",'w')); print(cfg['name'],len(m['voxels']))
