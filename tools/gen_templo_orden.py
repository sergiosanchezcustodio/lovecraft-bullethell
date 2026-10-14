"""El antiguo templo masónico de la Orden de Dagon (calles de Innsmouth, nivel 2 de la parte 2),
rehecho como templo clásico en la revisión de arte del 14-10-2026. Sustituye al de
gen_atrezo_innsmouth.py (hueco, a 32/m, con las columnas pegadas al muro).

Pórtico hexástilo jónico exento sobre un estilóbato con escalinata de seis peldaños: columnas
estriadas con éntasis, basa ática y capitel de volutas; entablamento con arquitrabe de tres
fajas, friso con una greca de olas y peces en relieve y cornisa con dentículos y modillones;
frontón con cornisa inclinada, el tímpano con el símbolo de la Orden (pez en un círculo de olas,
oro deslustrado con verdín) entre olas y tentáculos tallados, y acróteras. Detrás del pórtico,
el muro de la cella en sillería almohadillada: puerta monumental con marco de orejetas, cornisa
sobre ménsulas y dos hojas de bronce con cuarterones (una entreabierta, con una luz verdosa
dentro), y dos ventanas altas con frontoncillo, cegadas con tablas. Tejado de losas de plomo con
nervios. Envejecido sin perder la forma: chorretones bajo la cornisa, liquen y salitre abajo,
grietas, una columna con un trozo del fuste roto, un fragmento de cornisa caído en la escalinata
y hierbajos entre los peldaños.

Resolución en V voxels por metro (40; a 48 eran 2,9 millones de voxels). Paredes de una capa. Frente hacia +z; origen en el centro de la base del muro.
Escribe models/inn_templo.json. Uso: python tools/gen_templo_orden.py
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp, _ih

V = 40
S = V / 16.0
P = 'body'
STONE = (0.60, 0.59, 0.55); STONE_D = (0.46, 0.45, 0.42); STONE_L = (0.70, 0.69, 0.65); JOINT = (0.34, 0.34, 0.32)
COL = (0.70, 0.69, 0.65); COL_D = (0.52, 0.51, 0.48)
STREAK = (0.30, 0.31, 0.29); LICHEN = (0.44, 0.48, 0.34); SALT = (0.30, 0.42, 0.38)
GOLD = (0.60, 0.48, 0.22); GOLD_D = (0.42, 0.33, 0.14); VERDI = (0.30, 0.50, 0.42)
BRONZE = (0.28, 0.22, 0.14); BRONZE_D = (0.18, 0.14, 0.09)
LEAD = (0.28, 0.30, 0.32); LEAD_D = (0.20, 0.22, 0.24); LEAD_L = (0.36, 0.38, 0.40)
WOOD = (0.32, 0.24, 0.16); WOOD_D = (0.20, 0.15, 0.10); IRON = (0.12, 0.12, 0.13)
GLOW_G = (0.24, 0.62, 0.46); DARK = (0.04, 0.05, 0.05); WEED = (0.26, 0.34, 0.18)


def m(v): return int(round(v * V))


M = Model(S=S, seed=72)
put = lambda x, y, z, c, g=0: M.put(x, y, z, P, c, g)

# medidas (en voxels)
HW = m(6.8)              # media anchura de la cella
SW = m(7.25)             # media anchura del estilóbato
ZW = m(-0.4)             # cara del muro de la cella
ZB = m(-2.2)             # fondo (no se ve: sin muro trasero)
ZC = m(2.6)              # eje de las columnas
ZS = m(3.4)              # borde del estilóbato
Y0 = m(1.2)              # suelo del pórtico
CR = m(0.40)             # radio de la columna abajo
CH = m(7.0)              # altura del fuste
YC = Y0 + m(0.30)        # arranque del fuste (sobre la basa)
YT = YC + CH             # capitel
YE = YT + m(0.42)        # arranque del entablamento
YA, YF, YK = YE + m(0.85), YE + m(1.65), YE + m(2.35)   # arquitrabe, friso, cornisa (techo de cada uno)
PH = m(2.0)              # altura del frontón
COLS = [m(v) for v in (-5.75, -3.45, -1.15, 1.15, 3.45, 5.75)]


def weather(c, x, y, z):
    """Envejecido común: chorretones que bajan de la cornisa, liquen y salitre abajo."""
    st = _ih(x // 3, 0, z // 3 if abs(z) > 0 else 0, 11)
    if st > 0.86 and y > YE - m(2.5) - int(m(2.0) * _ih(x // 3, 1, 0, 12)):
        c = lerp(c, STREAK, 0.35 + 0.25 * (st - 0.86) / 0.14)
    if y < m(1.0) + int(m(0.8) * _ih(x // 7, 2, z // 7, 13)) and M.noise(x, y, z, 14.0) > 0.55:
        c = lerp(c, LICHEN if _ih(x, y, z, 14) > 0.4 else SALT, 0.45)
    return c


def ashlar(x, y, z, u):
    """Sillería almohadillada: hiladas de 0,5 m, sillares de 1 m, junta y borde rebajado."""
    row = y // m(0.5)
    off = (row % 2) * m(0.5)
    blk = (u + off + 2000) // m(1.0)
    fu, fv = (u + off + 2000) % m(1.0), y % m(0.5)
    if fu == 0 or fv == 0: return JOINT, True
    c = lerp(STONE, STONE_D if _ih(blk, row, 1) < 0.5 else STONE_L, 0.35 * _ih(blk, row, 2))
    if fu < 2 or fv < 2 or fu > m(1.0) - 3 or fv > m(0.5) - 3: c = lerp(c, STONE_D, 0.3)   # borde rebajado
    if _ih(x, y, z, 3) > 0.93: c = lerp(c, STONE_L, 0.4)
    return weather(c, x, y, z), False


# ---------------- estilóbato y escalinata ----------------
STEPS = 6
SD = m(0.42)
for k in range(STEPS + 1):                    # k = 0: estilóbato; luego peldaños hacia abajo
    top = Y0 - k * (Y0 // STEPS)
    zf = ZS + k * SD
    hw = SW + k * 4
    for x in range(-hw, hw + 1):
        for z in range(ZW - 4 if k == 0 else zf - SD, zf + 1):
            wear = int(2 * _ih(x // 9, k, 0, 5)) if abs(x) < m(1.6) else 0              # gastado en el centro
            yt = top - wear if z > zf - 6 else top
            c = lerp(STONE, STONE_L, 0.3 * _ih(x // m(0.8), k, 1)) if (x + 2000) % m(0.8) else JOINT
            c = weather(c, x, yt, z)
            put(x, yt, z, c)
            if z == zf:                                                         # contrahuella
                for y in range(top - Y0 // STEPS + 1, yt):
                    put(x, y, z, weather(lerp(STONE_D, STONE, 0.5 * _ih(x // m(0.8), k, 2)), x, y, z))
        if k > 0:
            for z in range(zf - SD, zf + 1):
                for x in (-hw, hw):
                    for y in range(0, top): put(x, y, z, STONE_D)
for x in range(-SW, SW + 1):                  # frente del estilóbato hasta el suelo (laterales)
    for s in (-1, 1):
        for z in range(ZB, ZS + 1):
            for y in range(0, Y0 + 1): put(s * SW, y, z, weather(STONE_D, s * SW, y, z)) if abs(x) == SW else None
for _ in range(120):                          # hierbajos entre los peldaños
    x = M.rng.randint(-SW + 10, SW - 10); k = M.rng.randint(1, STEPS)
    z = ZS + k * SD - SD + 1; y = Y0 - k * (Y0 // STEPS)
    for h in range(M.rng.randint(2, 7)): M.put(x + (h // 3), y + 1 + h, z, P, WEED if h % 2 else LICHEN, 0, False)

# ---------------- muro de la cella ----------------
DX, DW, DH = 0, m(1.35), m(5.0)              # puerta: media anchura y alto
WINX = (-m(4.3), m(4.3)); WIN_W, WIN_Y0, WIN_H = m(0.65), Y0 + m(1.8), m(3.4)
for y in range(Y0, YE):
    for x in range(-HW, HW + 1):
        door = abs(x) < DW and y < Y0 + DH
        win = any(abs(x - wx) < WIN_W for wx in WINX) and WIN_Y0 <= y < WIN_Y0 + WIN_H
        if door or win:
            put(x, y, ZW - 6, DARK)
            continue
        c, _ = ashlar(x, y, ZW, x)
        put(x, y, ZW, c)
    for x in (-HW, HW):                       # costados del muro, hasta el fondo
        for z in range(ZB, ZW + 1):
            c, _ = ashlar(x, y, z, z)
            put(x, y, z, c)
# antas (pilastras de esquina)
for s in (-1, 1):
    for y in range(Y0, YE):
        for x in range(HW - m(0.55), HW + 3):
            for z in range(ZW, ZW + 6):
                c = lerp(COL, COL_D, 0.3 * _ih(x, y // 9, z, 4))
                if y < Y0 + m(0.3) or y > YE - m(0.3): c = COL_D if (y // 4) % 2 else COL
                put(s * x, y, z, weather(c, s * x, y, z))
# puerta: marco de orejetas, cornisa sobre ménsulas y hojas de bronce (una entreabierta)
FR = m(0.32)
for x in range(-DW - FR, DW + FR + 1):
    for y in range(Y0, Y0 + DH + FR + 1):
        inside = abs(x) < DW and y < Y0 + DH
        if inside: continue
        ear = y > Y0 + DH - m(0.35) and abs(x) <= DW + FR + m(0.18)
        if abs(x) > DW + FR and not ear: continue
        for z in range(ZW + 1, ZW + 5):
            c = COL if (abs(x) - DW) % 5 and (y - Y0 - DH) % 5 else COL_D
            put(x, y, z, weather(c, x, y, z))
for x in range(-DW - FR - m(0.35), DW + FR + m(0.35) + 1):         # cornisa de la puerta
    for y in range(Y0 + DH + FR + m(0.45), Y0 + DH + FR + m(0.75)):
        dz = 6 + (y - (Y0 + DH + FR + m(0.45))) // 2
        for z in range(ZW + 1, ZW + dz): put(x, y, z, COL if y % 4 else COL_D)
for s in (-1, 1):                                                  # ménsulas
    for y in range(Y0 + DH + FR, Y0 + DH + FR + m(0.45)):
        for x in range(DW + FR + 2, DW + FR + 10):
            for z in range(ZW + 1, ZW + 4 + (y - Y0 - DH - FR) // 2): put(s * x, y, z, COL_D if x % 3 == 0 else COL)
for x in range(-DW + 1, DW):                                       # hojas de bronce
    for y in range(Y0, Y0 + DH):
        left = x < 0
        if not left and x > m(0.45): continue                      # la derecha entreabierta: rendija
        u = (x + DW) % DW
        c = BRONZE if (u % m(0.42) > 2 and (y - Y0) % m(0.62) > 2) else BRONZE_D
        if u % m(0.42) == m(0.21) and (y - Y0) % m(0.31) == 0: c = GOLD_D        # clavos
        if M.noise(x, y, 0, 6.0) > 0.66: c = lerp(c, VERDI, 0.6)
        put(x, y, ZW - 1 if left else ZW - 1 - (x // 3), c)
for x in range(m(0.45), DW):                                       # luz verdosa por la rendija
    for y in range(Y0, Y0 + DH - 4):
        put(x, y, ZW - m(0.6), lerp(GLOW_G, DARK, 0.5 * (1 - (y - Y0) / DH)), 1 if _ih(x, y, 0, 6) > 0.35 else 0)
# ventanas altas cegadas con tablas, marco y frontoncillo
for wx in WINX:
    for x in range(wx - WIN_W - 6, wx + WIN_W + 7):
        for y in range(WIN_Y0 - 8, WIN_Y0 + WIN_H + 6):
            inside = abs(x - wx) < WIN_W and WIN_Y0 <= y < WIN_Y0 + WIN_H
            if inside:
                c = WOOD if (y // 7) % 2 else WOOD_D
                if (y // 7) % 3 == 2 and abs(x - wx) > WIN_W - 6: continue          # tabla suelta
                if abs((x - wx) - (y - WIN_Y0) * 0.35) < 1.5: c = WOOD_D            # tabla cruzada
                put(x, y, ZW - 1, c)
                if (x - wx) % 9 == 0: put(x, y, ZW, IRON)                         # reja
                continue
            put(x, y, ZW + 2, weather(COL if y > WIN_Y0 - 6 else COL_D, x, y, ZW))
        for k in range(m(0.45)):                                                    # frontoncillo
            w = WIN_W + 9 - int(k * (WIN_W + 9) / m(0.45))
            if abs(x - wx) <= w: put(x, WIN_Y0 + WIN_H + 6 + k, ZW + 3, COL if k % 3 else COL_D)

# ---------------- columnas jónicas ----------------
def column(cx, broken=False):
    for y in range(Y0, YC):                                        # basa: plinto y molduras
        t = y - Y0
        if t < m(0.10):
            for x in range(-CR - 5, CR + 6):
                for z in range(-CR - 5, CR + 6):
                    if max(abs(x), abs(z)) in (CR + 5, CR + 4) or t == m(0.10) - 1: put(cx + x, y, ZC + z, COL_D if t % 3 == 0 else COL)
            continue
        r = CR + 4 - (2 if m(0.16) < t < m(0.22) else 0) - (1 if t >= m(0.22) else 0)
        for a in range(0, 720):
            x = int(round(r * math.cos(a * math.pi / 360))); z = int(round(r * math.sin(a * math.pi / 360)))
            put(cx + x, y, ZC + z, COL_D if m(0.16) < t < m(0.22) else COL)
    gap = (m(3.2), m(4.1))                                         # trozo de fuste roto
    for y in range(YC, YT):
        t = (y - YC) / CH
        r = CR * (1 - 0.14 * max(0.0, t - 0.33) / 0.67)            # éntasis
        n = int(2 * math.pi * r * 1.25)
        for i in range(n):
            a = i * 2 * math.pi / n
            fl = math.cos(a * 24)                                  # 24 estrías
            rr = r - (1.6 if fl > 0.35 else 0)
            x = int(round(rr * math.cos(a))); z = int(round(rr * math.sin(a)))
            if broken and gap[0] < y - YC < gap[1] and 0.2 < a < 1.6 and rr > r - 3: continue
            c = COL_D if fl > 0.35 else COL
            if fl > 0.9: c = lerp(COL_D, STREAK, 0.3)
            put(cx + x, y, ZC + z, weather(c, cx + x, y, ZC + z))
        if broken and gap[0] < y - YC < gap[1]:                    # corazón al aire
            for x in range(-int(r) + 4, int(r) - 4):
                for z in range(-int(r) + 4, int(r) - 4):
                    if x * x + z * z < (r - 4) ** 2 and 0.2 < math.atan2(z, x) % (2 * math.pi) < 1.6:
                        put(cx + x, y, ZC + z, STONE_D)
    for y in range(YT, YT + m(0.16)):                              # equino con ovas
        r = CR - 2 + (y - YT) // 2
        for i in range(int(2 * math.pi * r * 1.6)):
            a = i / (r * 1.6)
            x = int(round(r * math.cos(a))); z = int(round(r * math.sin(a)))
            put(cx + x, y, ZC + z, COL_D if (i // 4) % 3 == 0 else COL)
    VR = m(0.20)                                                   # volutas (delante y detrás)
    for y in range(YT + m(0.10), YT + m(0.36)):
        for x in range(-CR - m(0.20), CR + m(0.20) + 1):
            for z in range(-CR + 2, CR - 1):
                put(cx + x, y, ZC + z, COL) if abs(z) > CR - 4 or y in (YT + m(0.10), YT + m(0.36) - 1) or abs(x) > CR + m(0.20) - 3 else None
    for s in (-1, 1):
        for fz in (-CR + 1, CR - 2):
            vx, vy = cx + s * (CR + m(0.04)), YT + m(0.20)
            for i in range(380):                                   # espiral
                a = i * 0.07
                r = VR * (1 - a / 28)
                if r < 1: break
                px, py = vx + s * r * math.cos(a), vy - r * math.sin(a)
                for d in (0, 1):
                    put(int(px), int(py), ZC + fz + (d if fz > 0 else -d), COL_D)
            for x in range(-VR, VR + 1):
                for y in range(-VR, VR + 1):
                    if x * x + y * y <= VR * VR: M.put(vx + x, vy + y, ZC + fz, P, COL, 0, False)
    for y in range(YT + m(0.36), YE):                              # ábaco
        for x in range(-CR - 6, CR + 7):
            for z in range(-CR - 6, CR + 7):
                if max(abs(x), abs(z)) >= CR + 5 or y == YE - 1: put(cx + x, y, ZC + z, COL if (y - YT) % 4 else COL_D)


for i, cx in enumerate(COLS):
    column(cx, broken=(i == 4))

# ---------------- entablamento ----------------
ZF0 = ZC + CR + 4                                                  # cara del arquitrabe
for y in range(YE, YK):
    for x in range(-SW, SW + 1):
        if y < YA:                                                 # arquitrabe de tres fajas
            band = (y - YE) * 3 // (YA - YE)
            zf = ZF0 + band
            c = COL if (y - YE) % ((YA - YE) // 3) else COL_D
        elif y < YF:                                               # friso: greca de olas y peces
            zf = ZF0 + 1
            u, v = (x + 2000) % m(1.15), y - YA
            c = STONE
            h = (YF - YA)
            wave = h * 0.5 + h * 0.28 * math.sin(u / m(1.15) * 2 * math.pi)
            if abs(v - wave) < 3 or (v < wave and (u // 6 + v // 6) % 2 == 0 and v > h * 0.18): zf += 2; c = STONE_L
            fx = (x + 2000 + m(0.57)) % m(1.15) - m(0.57)
            if (fx / m(0.30)) ** 2 + ((v - h * 0.72) / m(0.10)) ** 2 < 1 or (m(0.26) < fx < m(0.40) and abs(v - h * 0.72) < (fx - m(0.26)) * 0.8):
                zf += 3; c = STONE_L                               # pez
        else:                                                      # cornisa
            t = y - YF
            zf = ZF0 + 3
            c = COL
            if t < m(0.18): zf += 2 + (3 if (x + 2000) % 7 < 4 else 0); c = COL if (x + 2000) % 7 < 4 else COL_D   # dentículos
            elif t < m(0.45): zf += 6 + (4 if (x + 2000) % m(0.55) < m(0.14) else 0); c = COL_D if (x + 2000) % m(0.55) < m(0.14) else COL   # modillones
            else: zf += 12 + (t - m(0.45)) // 3                                                 # corona y gola
        put(x, y, zf, weather(c, x, y, zf))
        if y == YK - 1:                                            # cara de arriba de la cornisa
            for z in range(ZW, zf): put(x, y, z, COL)
        for z in range(zf - 1, ZF0 - 1, -1):                       # escalones de las fajas y modillones
            if (x, y - 1, z) in M.V or (x, y + 1, z) in M.V: break
            put(x, y, z, c)
    for s in (-1, 1):                                              # costados del entablamento
        for z in range(ZB, ZF0 + 26):
            put(s * SW, y, z, COL if y % 7 else COL_D)

# ---------------- frontón ----------------
ZT = ZF0 + 1                                                       # tímpano (rehundido)
ZR = ZF0 + 15                                                      # cornisa inclinada
def ped_top(x): return YK + int(PH * (1 - abs(x) / (SW + 14)))
for x in range(-SW - 14, SW + 15):
    top = ped_top(x)
    for y in range(YK, top + 1):
        rake = top - y < m(0.32)
        zf = ZR if rake else ZT
        if rake and top - y < m(0.10) and (x + y) % 7 < 4: zf += 4                       # dentículos del canto
        c = COL if rake else STONE
        put(x, y, zf, weather(c, x, y, zf))
        if rake: put(x, y, zf - 1, c)
    for y in range(YK, YK + m(0.16)):                              # cornisa horizontal bajo el tímpano
        for z in range(ZT, ZR - 4): put(x, y, z, COL if y % 4 else COL_D) if abs(x) <= SW else None
# relieve del tímpano: el símbolo de la Orden entre olas y tentáculos
SYX, SYY = 0, YK + int(PH * 0.42)
SR = m(0.62)
for x in range(-SR - 4, SR + 5):
    for y in range(-SR - 4, SR + 5):
        d = math.hypot(x, y)
        if d > SR + 3: continue
        a = math.atan2(y, x)
        if d > SR - 6:                                             # aro de olas
            if d < SR + 1 + 2 * math.sin(a * 12): c, dz = GOLD, 4
            else: continue
        elif (x / (SR * 0.7)) ** 2 + (y / (SR * 0.32)) ** 2 < 1 or (SR * 0.55 < x < SR * 0.85 and abs(y) < (x - SR * 0.55) * 1.1):
            c, dz = GOLD, 5                                        # pez
            if (x + y) % 6 == 0: c = GOLD_D
        else:
            c, dz = lerp(GOLD_D, DARK, 0.4), 2
        if M.noise(x, y, 0, 5.0) > 0.62: c = lerp(c, VERDI, 0.7)    # verdín
        for z in range(ZT, ZT + dz): put(SYX + x, SYY + y, z, c)
    for k in range(int(m(1.6) * _ih(x, 0, 0, 20))):                # el verdín chorrea del oro
        if _ih(x, 1, 0, 21) > 0.82 and abs(x) < SR: put(SYX + x, SYY - SR - k, ZT + 1, lerp(VERDI, STONE, k / m(1.6)))
for s in (-1, 1):                                                  # olas y tentáculos tallados hacia las esquinas
    for x in range(SR + 10, SW - 8):
        t = (x - SR - 10) / (SW - SR - 18)
        top = ped_top(s * x) - m(0.36)
        for k in range(3):
            yb = YK + m(0.20) + k * m(0.22)
            if yb > top - 6: continue
            yy = yb + int(m(0.10) * math.sin(x / m(0.35) * math.pi + k))
            for d in range(-2, 3):
                put(s * x, yy + d, ZT + 3 - abs(d) // 2, STONE_L if d < 2 else STONE_D)
        ty = YK + m(0.95) * (1 - t) + m(0.12) * math.sin(t * 9)
        if ty < top - 4:                                           # tentáculo que se enrosca
            r = 4 * (1 - t) + 1
            for dy in range(-int(r), int(r) + 1):
                put(s * x, int(ty) + dy, ZT + 3 + (1 if abs(dy) < r - 1 else 0), STONE_L if dy > 0 else STONE_D)
            if int(t * 20) % 3 == 0: put(s * x, int(ty) - int(r), ZT + 4, COL)     # ventosas
# acróteras
for ax, h, w in ((0, m(0.70), m(0.30)), (-SW - 6, m(0.45), m(0.22)), (SW + 6, m(0.45), m(0.22))):
    base = ped_top(ax) if ax == 0 else YK
    for y in range(h):
        for x in range(-w, w + 1):
            for z in range(ZR - 8, ZR + 1):
                if ax == 0:                                        # palmeta
                    a = math.atan2(y - h * 0.3, x)
                    if math.hypot(x, y - h * 0.3) > w * (0.6 + 0.4 * abs(math.cos(a * 4))) or y < 0: continue
                elif abs(x) > w * (1 - y / h): continue
                put(ax + x, base + y, z, COL if (y + x) % 5 else COL_D)

# ---------------- tejado ----------------
for x in range(-SW - 14, SW + 15):
    top = ped_top(x)
    for z in range(ZB - 6, ZR - 2):
        c = LEAD if (x + 2000) % m(0.45) > 2 else LEAD_L                                 # nervios
        if M.noise(x, 0, z, 18.0) > 0.72: c = lerp(c, VERDI, 0.35)
        if _ih(x // 3, 0, z // 40, 22) > 0.95: c = lerp(c, STREAK, 0.6)
        put(x, top + 1, z, c)
for z in range(ZB - 6, ZR - 2):                                    # cumbrera
    for d in range(-3, 4): put(d, ped_top(0) + 2, z, LEAD_L if abs(d) < 2 else LEAD_D)

# ---------------- trozo de cornisa caído en la escalinata ----------------
for x in range(m(2.0), m(3.1)):
    for y in range(0, m(0.30)):
        k = 3
        yb = Y0 - k * (Y0 // STEPS)
        for z in range(ZS + (k - 1) * SD + 4, ZS + k * SD - 2):
            if (x - m(2.0)) * 0.3 + y < m(0.30): put(x, yb + 1 + y, z, COL_D if (x + y) % 5 == 0 else COL)

# vaciado: fuera lo que no se ve (todos los vecinos llenos)
nb = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))
for k in [k for k in M.V if all((k[0] + a, k[1] + b, k[2] + c) in M.V for a, b, c in nb)]: del M.V[k]
n = M.export('models/inn_templo.json', {P: [0, 0, 0]}, jitter=0.006, pivots_in_voxels=True,
             roughness=0.88, specular=0.28, no_bottom=True)
print('inn_templo: %d voxels' % n)
