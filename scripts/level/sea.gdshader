// Mar de la costa en voxel fino (rehecho el 16-10-2026, encargo del autor: "más detalle, más
// definición, más cadencia real de oleaje"). Celdas de `cell` m con la altura en escalones.
// - Mar de fondo que llega de mar adentro con su periodo (4-7,5 s según `state`): cerca de la
//   costa frena (menos fondo), las crestas se juntan, se ponen paralelas a la orilla, crecen,
//   se afilan y rompen; cada ola tiene su altura y llegan en series (unas cuantas grandes y luego
//   calma). Detrás de la cresta que rompe queda espuma que se deshace en encaje; contra la pared
//   se amontona y rebota (clapoteo).
// - Marejadilla del viento (`wind_dir`, rachas `gust`): cuatro trenes cortos con la velocidad de
//   las olas de verdad (ω² = g·k) y, con mal tiempo, crestas blancas.
// - La superficie sube y baja de verdad (la malla está subdividida): el agua se mueve contra
//   las paredes y los cascos. Ambient.sea_height repite la cuenta del mar de fondo para que lo
//   que flota suba y baje con cada ola.
// - Hielo menudo que deriva (`brash_amount`), estrellas reflejadas de noche (night_sky).
// Ojo: nada de fract(sin(x) * 43758) con argumentos grandes (en la GPU sale en hileras).
shader_type spatial;
render_mode cull_disabled, shadows_disabled;

#include "res://scripts/fx/night_sky.gdshaderinc"

uniform vec3 deep : source_color = vec3(0.07, 0.17, 0.27);
uniform vec3 mid : source_color = vec3(0.14, 0.32, 0.44);
uniform vec3 shallow : source_color = vec3(0.26, 0.50, 0.60);
uniform vec3 crest : source_color = vec3(0.50, 0.68, 0.78);
uniform vec3 brash : source_color = vec3(0.78, 0.86, 0.92);
uniform float brash_amount = 1.0;            // hielo menudo (0: puerto sin hielo, hito 6.2)
uniform vec3 foam : source_color = vec3(0.80, 0.87, 0.93);
uniform float cell = 0.0625;
uniform vec2 shore = vec2(32.0, 32.0);       // la orilla: x = shore.x (este) y z = shore.y (sur)
uniform float north_shore = -100000.0;       // orilla norte (un muelle con agua detrás); por defecto, ninguna
uniform vec2 drift = vec2(0.05, 0.03);       // deriva del hielo menudo (m/s)
uniform float swell = 1.0;                   // multiplica el mar de fondo (0: sin olas que lleguen)
uniform float state = 0.35;                  // estado de la mar: 0 calma chicha .. 1 temporal
uniform vec2 wind_dir = vec2(0.8, 0.5);      // hacia dónde sopla (en el suelo)
uniform float gust = 1.0;                    // rachas: 1 lo normal, más con las rachas
uniform float coast_amp = 0.0;               // costa natural: cuánto avanza la tierra (ArenaBuilder.coast_offset)
uniform float period_override = 0.0;         // periodo del mar de fondo (s); 0: según el estado
// faroles junto al agua (Ambient, cada fotograma): su reflejo es un rastro de luz que tiembla
uniform int lamp_n = 0;
uniform vec4 lamp_pos[8];                    // xyz del farol, w = intensidad
uniform vec4 lamp_col[8];
// rocas, témpanos, pilotes y barcas en el agua (Ambient): la ola rompe a su alrededor
uniform int rock_n = 0;
uniform vec4 rocks[24];                      // xz del centro, z = radio

varying vec3 wpos;

const float C_WALL = 1.4;                    // m/s de la ola junto a la pared (poco fondo)
const float L_DEPTH = 7.0;                   // m en que el fondo (y la velocidad) crece

float vnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(sky_hash(i), sky_hash(i + vec2(1, 0)), f.x), mix(sky_hash(i + vec2(0, 1)), sky_hash(i + vec2(1, 1)), f.x), f.y);
}

// Distancia a la orilla (m) y coordenada a lo largo de ella.
void shore_coords(vec2 p, out float d, out float along) {
	d = length(max(p - shore, vec2(0.0)));
	if (p.x < shore.x) d = p.y - shore.y;
	if (p.y < shore.y) d = p.x - shore.x;
	if (p.y < north_shore) d = north_shore - p.y;
	along = (p.x < shore.x || p.y < north_shore) ? p.x : p.y;
	if (coast_amp > 0.0 && p.y >= north_shore) {   // la orilla con entrantes y salientes (misma cuenta que ArenaBuilder)
		float ac = (floor(along / 0.0625) + 0.5) * 0.0625;
		float v = 0.5 + 0.28 * sin(ac * 0.83 + 1.3) + 0.2 * sin(ac * 1.97 + 0.4) + 0.12 * sin(ac * 4.3 + 2.1) + 0.07 * sin(ac * 9.7 + 0.7);
		d -= floor(coast_amp * clamp(v, 0.0, 1.0) / 0.0625 + 0.5) * 0.0625;
	}
}

float period() { return period_override > 0.0 ? period_override : mix(4.2, 7.5, state); }

// Tiempo que tarda la ola en llegar desde d hasta la pared: frena al perder fondo.
float travel(float d) { return 2.0 * L_DEPTH / C_WALL * (sqrt(1.0 + max(d, 0.0) / L_DEPTH) - 1.0); }

// Altura de cada ola: series de grandes y calma, y algo de variedad (solo senos de números
// pequeños: Ambient.sea_height hace la misma cuenta en el juego y tiene que salir igual).
float wave_size(float n) {
	float s = 0.5 + 0.5 * sin(TAU * n / 7.3 + 0.7);
	return mix(0.45, 1.25, s * s) * (0.85 + 0.3 * (0.5 + 0.5 * sin(n * 2.39 + 1.1)));
}

// Mar de fondo en p (m): altura (m), fase f (0 al pasar la cresta, sube hasta 1 con la
// siguiente), tamaño de la ola y lo que tiene de rompiente (0..1).
float swell_at(vec2 p, float t, out float f, out float size, out float surf) {
	float d; float along;
	shore_coords(p, d, along);
	d = max(d, 0.0);                     // bajo tierra (d < 0), como en la pared: si no, las cuentas se disparan
	float T = period();
	float wob = 0.9 * sin(along * 0.09 + 1.3) + 0.5 * sin(along * 0.23 - 0.6);   // crestas algo oblicuas
	float th = (t + travel(d)) / T + wob / TAU;
	float n = floor(th);
	f = th - n;
	size = mix(wave_size(n), wave_size(n + 1.0), smoothstep(0.0, 1.0, f));
	size *= 0.8 + 0.4 * (0.5 + 0.5 * sin(along * 0.31 + n * 1.7) * sin(along * 0.07 - n * 0.9));   // rompe a trozos
	float a0 = mix(0.015, 0.42, state) * swell;
	float grow = 1.0 + 0.9 * exp(-d / 5.0);                                    // crece al llegar
	float d_break = mix(1.2, 5.0, state) * size;
	surf = 1.0 - smoothstep(d_break * 0.6, d_break, d);
	float a = a0 * grow * size * mix(0.3, 1.0, smoothstep(0.0, d_break, d));  // rota, baja
	float k = mix(1.2, 2.8, clamp(grow - 1.0 + surf * 0.6, 0.0, 1.0));       // se afila
	float u = cos(TAU * f);
	float y = a * (2.0 * pow(0.5 + 0.5 * u, k) - 0.6);
	// rebote contra la pared: una ola que vuelve, pequeña, cruza la que llega (clapoteo)
	float back = (t - travel(d)) / T + wob / TAU;
	y += 0.35 * a0 * exp(-d / 2.5) * cos(TAU * back + 3.14159);
	return y;
}

// Marejadilla del viento: cuatro trenes cortos, cada uno a su velocidad (ω² = g·k).
float chop_at(vec2 p, float t, int count) {
	vec2 w = normalize(wind_dir + vec2(1e-4));
	float amp = mix(0.25, 1.0, state) * gust;
	float y = 0.0;
	for (int i = 0; i < 4; i++) {
		if (i >= count) break;
		float fi = float(i);
		float ang = (fi == 0.0 ? -0.35 : (fi == 1.0 ? 0.25 : (fi == 2.0 ? 0.55 : -0.15)));
		float lam = (fi == 0.0 ? 3.2 : (fi == 1.0 ? 1.9 : (fi == 2.0 ? 1.15 : 0.7)));
		vec2 dir = vec2(w.x * cos(ang) - w.y * sin(ang), w.x * sin(ang) + w.y * cos(ang));
		float k = TAU / lam;
		float om = sqrt(9.8 * k);
		y += amp * lam * 0.03 * sin(k * dot(dir, p) - om * t + fi * 1.7);
	}
	return y;
}

float sea_h(vec2 p, float t) {
	float f; float sz; float sf;
	return swell_at(p, t, f, sz, sf) + chop_at(p, t, 4);
}

// Encaje de espuma (bordes de celdas de Worley): 0 en el borde de las burbujas, 1 lejos.
float lace(vec2 x) {
	vec2 i = floor(x); vec2 fr = fract(x);
	float f1 = 8.0; float f2 = 8.0;
	for (int y = -1; y <= 1; y++) {
		for (int xx = -1; xx <= 1; xx++) {
			vec2 g = vec2(float(xx), float(y));
			vec2 o = vec2(sky_hash(i + g), sky_hash(i + g + 19.1));
			float dd = length(g + o - fr);
			if (dd < f1) { f2 = f1; f1 = dd; } else if (dd < f2) { f2 = dd; }
		}
	}
	return f2 - f1;
}

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float f; float sz; float sf;
	float y = swell_at(w.xz, TIME, f, sz, sf) + chop_at(w.xz, TIME, 2);
	VERTEX.y += y;
	wpos = w + vec3(0.0, y, 0.0);
}

void fragment() {
	float t = TIME;
	vec2 c = floor(wpos.xz / cell);
	vec2 p = (c + 0.5) * cell;
	float d; float along;
	shore_coords(p, d, along);
	float f; float sz; float surf;
	float sw = swell_at(p, t, f, sz, surf);
	float h = sw + chop_at(p, t, 4);
	float amax = mix(0.015, 0.42, state) * swell * 2.3 + mix(0.25, 1.0, state) * 0.2 + 0.02;
	// escalones de altura (10) y normal: la del relieve grande y los cantos de los escalones
	float lv = 10.0;
	float hn = clamp(h / (2.0 * amax) + 0.5, 0.0, 1.0);
	float q0 = floor(hn * lv);
	float qx = floor(clamp(sea_h(p + vec2(cell, 0.0), t) / (2.0 * amax) + 0.5, 0.0, 1.0) * lv);
	float qz = floor(clamp(sea_h(p + vec2(0.0, cell), t) / (2.0 * amax) + 0.5, 0.0, 1.0) * lv);
	float e = 0.25;
	float gx = (sea_h(p + vec2(e, 0.0), t) - sea_h(p - vec2(e, 0.0), t)) / (2.0 * e);
	float gz = (sea_h(p + vec2(0.0, e), t) - sea_h(p - vec2(0.0, e), t)) / (2.0 * e);
	float ripple = vnoise(vec2(p.x * 4.0 + p.y * 1.3, p.y * 4.0 - p.x * 1.3) - wind_dir * t * 1.6) - 0.5;
	float paws = smoothstep(0.45, 0.8, vnoise(p * 0.09 - wind_dir * t * 0.25)) * clamp(gust - 0.6, 0.0, 1.0);   // zarpazos del viento
	vec3 n = normalize(vec3(-gx * 1.4 - (qx - q0) * 0.22 + ripple * 0.12 * (1.0 + paws), 1.0,
		-gz * 1.4 - (qz - q0) * 0.22 + ripple * 0.12 * (1.0 + paws)));
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);

	// color: lejos, más hondo; los valles oscuros y las caras de la ola claras
	float depth = smoothstep(1.0, 26.0, d);
	vec3 lo = mix(mid * 0.8, deep, depth);
	vec3 hi = mix(shallow, mid * 1.5, depth);
	float hq = q0 / lv;
	vec3 col = mix(lo, hi, smoothstep(0.2, 0.85, hq));
	// la ola que se levanta antes de romper: más clara y verdosa (la luz la atraviesa)
	float face = smoothstep(0.75, 0.97, f) * (1.0 - depth) * clamp(sz, 0.0, 1.2) * (0.4 + surf);
	col = mix(col, shallow * 1.25, face * 0.25);
	// línea de cresta: una fila clara en lo alto de cada ola
	float crest_l = (step(f, 0.022) + step(0.992, f)) * smoothstep(0.2, 0.7, sz) * (1.0 - 0.5 * depth);
	col = mix(col, crest * 1.1, crest_l * 0.85);
	col *= 1.0 - 0.1 * paws;
	col *= 0.97 + 0.05 * sky_hash(c);                                   // grano por celda

	// espuma
	vec2 wv = normalize(wind_dir + vec2(1e-4));
	vec2 warp = vec2(vnoise(p * 0.8 + 3.1), vnoise(p * 0.8 + 9.7)) - 0.5;   // celdas torcidas: nada de panal
	float lc = lace(p * 2.1 + warp * 2.2 + wv * t * 0.12);                 // encaje, a escala de 0,5 m
	float lf = lace(p * 5.3 + warp * 3.0 - wv * t * 0.2 + 7.0);           // y burbujas finas
	float clump = vnoise(p * 1.1 + warp + wv * t * 0.08);                  // la espuma va a manchas
	float age = f * period();                                            // s desde que pasó la cresta
	// rompiente: la cresta rota avanza como un rulo blanco y deja espuma que se deshace
	float white = surf * exp(-age / 1.1) * clamp(sz, 0.0, 1.3) * smoothstep(0.08, 0.45, state * swell);
	// contra la pared: se amontona al llegar cada ola y se retira
	float wall = (1.0 - smoothstep(0.12, 0.18 + 1.1 * exp(-age / 0.9) * sz, d)) * smoothstep(0.03, 0.2, state * swell);
	float land = step(-0.3, d);                                          // dentro de la orilla (huecos bajo el muelle): sin espuma
	white = max(white, wall * 0.95);
	// borreguillos mar adentro con mal tiempo: en las crestas grandes, con el viento
	float caps = smoothstep(0.45, 0.95, state * gust) * exp(-age / 1.1) * smoothstep(0.85, 1.15, sz)
		* step(0.45, vnoise(vec2(along * 0.4, floor((t + travel(d)) / period()) * 1.7)));
	white = max(white, caps * 0.85);
	// alrededor de rocas y témpanos: un aro de encaje siempre y, al pasar cada ola, espuma que rompe
	float rk = 1e4;
	for (int i = 0; i < 24; i++) {
		if (i >= rock_n) break;
		rk = min(rk, length(p - rocks[i].xy) - rocks[i].z);
	}
	if (rk < 2.5) {
		float hit = exp(-age / 0.9) * clamp(sz, 0.0, 1.3);
		float rim = (1.0 - smoothstep(0.03, 0.08 + 0.75 * hit * smoothstep(0.02, 0.3, state * swell), rk)) * smoothstep(-0.6, -0.2, rk);
		float lee = 1.0 - smoothstep(0.0, 1.8, rk);                       // y la que queda flotando
		white = max(white, rim * mix(0.22, 0.95, hit) + lee * 0.1 * smoothstep(0.3, 0.7, vnoise(p * 1.3 - wv * t * 0.2)));
	}
	float old = surf * 0.18 * smoothstep(0.3, 0.7, vnoise(p * 0.5 + wv * t * 0.1));   // espuma vieja en la rompiente
	white = max(white, old) * land;
	// a manchas que se encogen al deshacerse, con agujeros de encaje; solo recién rota, entera
	// vetas paralelas a la cresta (la espuma se estira a lo largo de la ola) más manchas y grano
	float streak = vnoise(vec2(along * 0.55, d * 2.2) + warp * 1.5);
	float blob = 0.45 * streak + 0.3 * clump + 0.25 * vnoise(p * 3.7 - warp * 2.0 + wv * t * 0.15);
	float fo = step(1.0 - white * 0.8, blob) * step(0.11, lc) * step(0.06, white);
	fo = max(fo, step(lc, white * 0.2) * step(0.25, white));              // la red fina alrededor
	fo = max(fo, step(0.93, white) * step(0.07, lf));                     // solo el rulo recién roto, entero
	col = mix(col, foam * (0.92 + 0.1 * sky_hash(c + 3.0)), fo * 0.85);

	// hielo menudo: placas de 1-3 celdas que derivan (y se mecen con el agua)
	vec2 qb = (wpos.xz - drift * t - vec2(gx, gz) * 0.15) / 0.25;
	vec2 qc = floor(qb);
	float b = step(0.97, sky_hash(qc + 71.0));
	b *= step(0.72, vnoise(qc * 0.06 + 3.0)) * (1.0 - 0.6 * depth);
	b = step(0.5, b) * brash_amount;
	col = mix(col, brash * (0.92 + 0.1 * sky_hash(qc)), b);

	float ice = max(b, fo);
	ALBEDO = col;
	vec3 em = vec3(0.0);
	if (night > 0.0) {                       // estrellas reflejadas que tiemblan con las olas
		vec2 sp = wpos.xz + n.xz * 0.35;
		em = (star_at(floor(sp * 16.0), t, 0.005) * night * 1.1 + shooting_star(sp)) * (1.0 - ice) * (0.6 + 0.4 * hq);
	}
	// reflejo de los faroles: alrededor del punto donde el agua lo refleja hacia la cámara (a 1,73
	// veces su altura, hacia el que mira), estirado por las olas en trozos que tiemblan
	vec2 vd = vec2(0.70710678, 0.70710678);
	for (int i = 0; i < 8; i++) {
		if (i >= lamp_n) break;
		vec4 L = lamp_pos[i];
		float hh = max(L.y - wpos.y, 0.3);
		vec2 rel = p - L.xz;
		float al = dot(rel, vd);
		float k = al / (1.732 * hh);
		if (k < 0.3 || k > 2.6) continue;
		float ac = dot(rel, vec2(-vd.y, vd.x));
		float wdt = 0.1 + 0.11 * k;
		float wob = (gx - gz) * 0.4 + 0.07 * sin(al * 5.0 - t * 2.3);
		float core = 1.0 - smoothstep(wdt * 0.35, wdt, abs(ac + wob));
		float dash = step(0.42, vnoise(vec2(al * 5.5 - t * 1.2, ac * 2.5 + t * 0.5)));
		float fall = exp(-abs(k - 1.0) * 1.5);
		em += lamp_col[i].rgb * lamp_col[i].rgb * L.w * core * dash * fall * (1.0 - ice * 0.8);   // al cuadrado: más cálido, no blanco
	}
	EMISSION = em;
	ROUGHNESS = mix(0.22, 0.85, ice);
	SPECULAR = mix(0.45, 0.3, ice);
}
