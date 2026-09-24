"""Acechador (Profundo agazapado) - versión detallada. Voxel S=2 (32 vox/m)."""
import json, math, random
random.seed(21); S=2; V={}
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
def cone(a,b,r,part,cb,ct,tip_r=0.5):
    n=int(max(abs(b[i]-a[i]) for i in range(3))*S*3)+1
    for i in range(n+1):
        t=i/n; c=[a[k]+(b[k]-a[k])*t for k in range(3)]; rr=max(tip_r,r*(1-t)**1.2)
        col=tuple(cb[j]*(1-t)+ct[j]*t for j in range(3)); ell(c[0],c[1],c[2],rr,rr,rr,part,col)
def lerp(a,b,t): return tuple(a[i]*(1-t)+b[i]*t for i in range(3))
# ---------- ruido de valor 3D (para manchas) ----------
_h={}
def hsh(i,j,k):
    if (i,j,k) not in _h: _h[(i,j,k)]=random.random()
    return _h[(i,j,k)]
def vnoise(x,y,z,s):
    x/=s;y/=s;z/=s; i,j,k=int(math.floor(x)),int(math.floor(y)),int(math.floor(z)); fx,fy,fz=x-i,y-j,z-k
    fx,fy,fz=[f*f*(3-2*f) for f in (fx,fy,fz)]
    v=0
    for a in (0,1):
        for b in (0,1):
            for c in (0,1):
                w=(fx if a else 1-fx)*(fy if b else 1-fy)*(fz if c else 1-fz); v+=w*hsh(i+a,j+b,k+c)
    return v
# ---------- paleta ----------
DORSAL=(0.05,0.10,0.10); SIDE=(0.11,0.20,0.19); BELLY=(0.34,0.36,0.28); SPOT=(0.20,0.33,0.29)
SPOT_D=(0.015,0.03,0.03); LATERAL=(0.40,0.46,0.38)
BONE_B=(0.16,0.14,0.10); BONE_T=(0.92,0.87,0.68); MEMB=(0.10,0.07,0.08); MEMB_E=(0.30,0.22,0.18)
EYE_A=(1.0,0.86,0.25); EYE_B=(0.70,0.36,0.05); PUPIL=(0.01,0.01,0.01); SOCKET=(0.015,0.03,0.03)
MAW=(0.08,0.01,0.03); GUM=(0.42,0.10,0.14); TONGUE=(0.55,0.20,0.25); TOOTH=(0.88,0.85,0.72); TOOTH_B=(0.62,0.58,0.44)
CLAW=(0.10,0.10,0.08); CLAW_T=(0.55,0.52,0.42); GILL=(0.45,0.07,0.12); GILL_D=(0.22,0.03,0.06); WEB=(0.06,0.12,0.12)
# ================= VOLÚMENES =================
# torso agazapado
ell(0,10.5,0.6,5.6,4.6,5.2,'torso','skin')
ell(0,13.0,-1.4,5.9,3.4,4.5,'torso','skin')
ell(0,8.6,2.2,4.6,3.2,4.0,'torso','skin')                  # vientre bajo
# cabeza ancha y plana, proyectada
HX,HY,HZ=0,16.8,5.9
ell(HX,HY,HZ,7.2,3.6,6.2,'head','skin')
ell(0,15.0,6.7,6.8,2.4,5.8,'head','skin')                  # mandíbula
ell(0,14.2,4.0,5.2,2.0,4.0,'head','skin')                  # garganta/papada
# arcos oculares
for s in (-1,1):
    capsule((s*2.8,19.9,9.0),(s*6.2,20.4,6.0),1.05,0.9,'head','ridge')
# PATAS de rana
for s in (-1,1):
    p='leg_l' if s<0 else 'leg_r'
    hip=(s*4.2,8.8,-1.2); knee=(s*7.6,6.8,3.6); ank=(s*6.4,1.6,-1.8)
    capsule(hip,knee,2.7,2.1,p,'skin'); capsule(knee,ank,2.0,1.3,p,'skin')
    ell(s*6.6,0.9,0.4,1.8,0.9,2.8,p,'hand')
    for tx,tz in ((-1.4,5.8),(0,6.6),(1.4,5.8)):
        a=(s*6.6+tx*0.4,0.8,1.2); b=(s*6.6+tx*1.3,0.6,tz)
        capsule(a,b,0.7,0.5,p,'hand')
        for k in range(3): put((b[0])*S,0+ (1 if k==0 else 0),(b[2]+0.5)*S+k,p,'claw' if k<2 else 'clawt')
    for x in range(int((s*6.6-2.2)*S),int((s*6.6+2.2)*S)+1):
        for z in range(int(1.6*S),int(5.6*S)): put(x,0,z,p,'web',over=False)
# BRAZOS largos apoyados delante
for s in (-1,1):
    p='arm_l' if s<0 else 'arm_r'
    sh=(s*6.2,12.4,2.4); el=(s*8.6,7.6,4.2); wr=(s*7.0,2.4,8.4)
    ell(*sh,2.2,2.3,2.2,p,'skin'); capsule(sh,el,1.6,1.35,p,'skin'); capsule(el,wr,1.35,1.05,p,'skin')
    ell(s*7.0,1.0,9.4,2.0,0.95,1.9,p,'hand')                # palma sobre el suelo
    fingers=[(-1.9,11.8),(-0.6,12.8),(0.7,12.8),(1.9,11.6)]
    for fx,fz in fingers:
        a=(s*7.0+fx*0.45,1.0,10.0); b=(s*7.0+fx*1.25,0.8,fz)
        capsule(a,b,0.6,0.45,p,'hand')
        put(b[0]*S,1,(b[2]+0.4)*S,p,'claw'); put(b[0]*S,0,(b[2]+0.9)*S,p,'claw'); put(b[0]*S,0,(b[2]+1.4)*S,p,'clawt')
    for x in range(int((s*7.0-2.6)*S),int((s*7.0+2.6)*S)+1):
        for z in range(int(10.0*S),int(11.8*S)): put(x,0,z,p,'web',over=False)
    # púas del antebrazo
    for i in range(3):
        t=0.25+i*0.25; b=[el[j]*(1-t)+wr[j]*t for j in range(3)]; b[0]+=s*0.9; b[2]-=0.4
        cone(b,(b[0]+s*1.6,b[1]+1.2,b[2]-1.2),0.95,p,BONE_B,BONE_T)
# ================= PIEL =================
def surface_normal(k):
    x,y,z=k; n=[0,0,0]
    for i,d in enumerate(((1,0,0),(0,1,0),(0,0,1))):
        a=(x+d[0],y+d[1],z+d[2]) in V; b=(x-d[0],y-d[1],z-d[2]) in V
        n[i]=(0 if a else 1)-(0 if b else 1)
    return n
for k,v in V.items():
    x,y,z=k; p,c=v[0],v[1]
    if not isinstance(c,str): continue
    X,Y,Z=(x+.5)/S,(y+.5)/S,(z+.5)/S
    if c in('skin','ridge'):
        # altura relativa: dorso oscuro -> flanco -> vientre claro
        if p=='head': t=(Y-(HY-2.6))/5.0
        elif p=='torso': t=(Y-8.0)/7.0 - (Z-2.0)*0.08
        else: t=0.45+ (Y-4)/14
        t=max(0,min(1,t))
        base=lerp(SIDE,DORSAL,t**0.8)
        bellyz=(p=='torso' and Z>3.4 and abs(X)<3.6 and Y<11.5) or (p=='head' and Y<15.6 and Z>4.0 and abs(X)<5.2)
        if bellyz:
            base=BELLY if (y//2)%2==0 else lerp(BELLY,SIDE,0.35)
            if abs(X)<0.35 and p=='torso': base=lerp(BELLY,SIDE,0.5)
        else:
            n=vnoise(x,y,z,4.5)
            if t>0.35 and n>0.64: base=SPOT if n<0.74 else lerp(SPOT,SIDE,0.3)
            elif t>0.35 and n>0.60: base=SPOT_D
            # escamas finas
            if (x+y)%4==0 or (y-x+z)%4==0: base=tuple(q*0.86 for q in base)
        if c=='ridge': base=lerp(DORSAL,SPOT_D,0.5)
        # línea lateral
        if p=='torso' and abs(abs(X)-5.4)<0.8 and abs(Y-11.2+(Z*0.18))<0.3 and z%2==0: base=LATERAL
        v[1]=base
    elif c=='hand':
        n=vnoise(x,y,z,3.0); v[1]=lerp(SIDE,DORSAL,0.35) if n<0.6 else SPOT_D
    elif c=='web': v[1]=WEB
    elif c=='claw': v[1]=CLAW
    elif c=='clawt': v[1]=CLAW_T
# ================= BOCA =================
def front(x,y):
    for z in range(60,-40,-1):
        if (x,y,z) in V: return z
    return None
MW=6.9; MY=15.9
for x in range(int(-MW*S),int(MW*S)):
    xr=abs((x+.5)/S)/MW
    yb=int(round(MY*S-(xr**2)*1.5*S))
    gap=max(1,int(round((1-xr**1.6)*3.2)))
    lo,hi=yb-gap//2, yb+gap-gap//2
    for y in range(lo,hi+1):
        zf=front(x,y)
        if zf is None: continue
        for d in range(0,5):
            q=(x,y,zf-d)
            if q in V:
                if d<2 and xr<0.93: del V[q]
                else: V[q][1]=MAW if d>=2 else GUM
    # lengua al fondo
    if xr<0.4:
        zf=front(x,lo)
        if zf: put(x,lo,zf-1,'head',TONGUE)
    # encía superior/inferior
    for yy in (hi+1,lo-1):
        zf=front(x,yy)
        if zf is not None and V[(x,yy,zf)][1] not in(TOOTH,): V[(x,yy,zf)][1]=GUM
    # dientes superiores: alternos, caninos largos
    if xr<0.9 and x%2==0:
        L=2 if xr>0.6 else 3
        if abs(xr-0.42)<0.07: L=5
        zf=front(x,hi+1) or 0
        for k in range(L): put(x,hi-k,zf-1,'head',TOOTH if k>0 else TOOTH_B)
    if xr<0.85 and x%2!=0:
        L=1 if xr>0.5 else 2
        if abs(xr-0.30)<0.07: L=3
        zf=front(x,lo-1) or 0
        for k in range(L): put(x,lo+k,zf-1,'head',TOOTH if k>0 else TOOTH_B)
# ================= OJOS =================
ER=2.5
for s in (-1,1):
    ex,ey,ez=s*4.5,19.6,7.3
    ell(ex,ey,ez,ER+0.4,ER+0.4,ER+0.4,'head',SOCKET)
    ell(ex+s*0.2,ey+0.2,ez+0.2,ER,ER,ER,'head','eye')
    cc=((ex+s*0.2)*S,(ey+0.2)*S,(ez+0.2)*S); r=ER*S
    d=(s*0.45,0.12,0.88); nd=math.sqrt(sum(q*q for q in d)); d=tuple(q/nd for q in d)
    for k,v in list(V.items()):
        if v[1]!='eye': continue
        rel=(k[0]+.5-cc[0],k[1]+.5-cc[1],k[2]+.5-cc[2]); dist=math.sqrt(sum(q*q for q in rel))
        dot=sum(rel[i]*d[i] for i in range(3))/max(dist,1e-6)
        t=max(0,min(1,(dot-0.3)/0.65))
        col=lerp(EYE_B,EYE_A,t)
        if dot<0.34: col=lerp(EYE_B,SOCKET,0.5)                 # anillo exterior
        # rendija vertical
        side=abs(rel[0]*d[2]-rel[2]*d[0])/r
        if dot>0.78 and side<0.14: col=PUPIL
        if dot>0.60 and dot<0.66 and random.random()<0.3: col=lerp(EYE_B,EYE_A,0.3)   # vetas
        v[1]=col; v[2]=0
    # brillo húmedo
    g=(cc[0]-s*0.25*r+0.2*r*d[0], cc[1]+0.55*r, cc[2]+0.72*r)
    put(g[0],g[1],g[2],'head',(1,1,0.95),1); put(g[0],g[1]-1,g[2],'head',(1,1,0.95),1)
    # párpado inferior carnoso
    for x in range(int((ex-ER)*S),int((ex+ER)*S)+1):
        for z in range(int((ez-0.5)*S),int((ez+ER+0.6)*S)):
            y=int((ey-ER*0.72)*S)
            if (x,y,z) in V and V[(x,y,z)][1] not in(PUPIL,): V[(x,y,z)][1]=lerp(SIDE,DORSAL,0.4)
# ================= AGALLAS en volante =================
for s in (-1,1):
    for i,gy in enumerate((13.4,14.6,15.8)):
        for j in range(5):
            z=2.6-j*0.55; x=s*(6.0+ j*0.35 + (0.3 if i==1 else 0)); y=gy-0.2*j
            for dy in (0,0.5):
                put(x*S,(y+dy)*S,z*S,'head',GILL if j<3 else GILL_D)
                put((x+s*0.5)*S,(y+dy)*S,z*S,'head',GILL_D)
# ================= CRESTA de púas con membrana =================
def top(x,z):
    for y in range(80,-1,-1):
        q=(x,y,z)
        if q in V and V[q][0] in('head','torso'): return y
    return None
zs=[z/2 for z in range(int(-7*2),int(8.5*2),3)]          # cada 1.5 unidades base
tops={}
for z in zs:
    t=top(0,int(z*S)); tops[z]=t/S if t is not None else None
spk=[]
for i,z in enumerate(zs):
    if tops[z] is None: continue
    u=i/(len(zs)-1)                                      # 0 = espalda, 1 = frente
    L=2.0+4.2*math.sin(min(1,u*1.25)*math.pi*0.92)       # más altas en la nuca
    part='head' if z>=3.2 else 'torso'
    b=(0,tops[z]-0.4,z); tp=(0,b[1]+L*0.82,z-L*0.55)
    cone(b,tp,1.35,part,BONE_B,BONE_T); spk.append((b,tp,part))
for (b0,t0,p0),(b1,t1,p1) in zip(spk[:-1],spk[1:]):
    part=p1
    for u in [q/16 for q in range(1,13)]:
        a=lerp(b0,t0,u*0.92); c=lerp(b1,t1,u*0.62)
        n=int(abs(a[2]-c[2])*S*2)+2
        for m in range(n+1):
            w=m/n; q=lerp(a,c,w)
            col=MEMB_E if u>0.6 else MEMB
            put(0,q[1]*S,q[2]*S,part,col,over=False); put(-1,q[1]*S,q[2]*S,part,col,over=False)
# púas laterales en los hombros
for s in (-1,1):
    for j,z in enumerate((0.5,-1.5,-3.5)):
        t=top(int(s*3.4*S),int(z*S))
        if t:
            b=(s*3.4,t/S-0.3,z); cone(b,(s*4.8,b[1]+1.8,z-1.5),1.0,'torso',BONE_B,BONE_T)
out=[]
for (x,y,z),(p,c,g) in V.items():
    if isinstance(c,str): c=SIDE
    j=random.uniform(-0.018,0.018)
    out.append([x,y,z,p,round(max(0,c[0]+j),3),round(max(0,c[1]+j),3),round(max(0,c[2]+j),3),g])
pv={'torso':[0,8.5,0],'head':[0,14.0,3.4],'arm_l':[-6.2,12.4,2.4],'arm_r':[6.2,12.4,2.4],'leg_l':[-4.2,8.8,-1.2],'leg_r':[4.2,8.8,-1.2]}
json.dump({'voxels':out,'pivots':{k:[a*S for a in v] for k,v in pv.items()}},open('models/acechador.json','w'))
print(len(out),'voxels')
