// Cielo de los relatos (hito 16.35, RelatoScreen): lo que la cámara de la partida nunca enseña,
// detrás del mapa del nivel. Degradado de la noche, estrellas que titilan, luna y nubes «voxel»
// (el ruido se cuantiza en bloques y la luz de la luna aclara el borde de arriba de cada una).
// mode: 0 luna y nubes; 1 aurora (la Antártida); 2 tormenta (nubes cerradas, lluvia y
// relámpagos: `flash` lo pone el script); 3 R'lyeh (cielo verdoso, nubes que giran despacio y
// una luna grande y enferma). Sin sin() con argumentos grandes (night_sky.gdshaderinc).
shader_type canvas_item;

uniform int mode = 0;
uniform vec3 top_col : source_color = vec3(0.02, 0.03, 0.07);
uniform vec3 hor_col : source_color = vec3(0.10, 0.11, 0.17);
uniform vec3 cloud_dark : source_color = vec3(0.05, 0.06, 0.09);
uniform vec3 cloud_lit : source_color = vec3(0.32, 0.34, 0.42);
uniform vec3 moon_col : source_color = vec3(0.92, 0.9, 0.8);
uniform vec3 glow_a : source_color = vec3(0.2, 0.95, 0.55);   // aurora, abajo
uniform vec3 glow_b : source_color = vec3(0.55, 0.25, 0.75);  // aurora, arriba
uniform vec2 moon_pos = vec2(0.76, 0.15);
uniform float moon_r = 0.05;
uniform float cover = 0.52;                     // cuánto cielo tapan las nubes (umbral del ruido)
uniform float block = 0.009;                    // lado del bloque de las nubes (fracción del alto)
uniform float aspect = 1.7778;
uniform float flash = 0.0;
uniform float bolt_x = 0.4;
uniform float dim = 1.0;
uniform float seed = 0.0;

float h21(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1.0, 0.0)), f.x), mix(h21(i + vec2(0.0, 1.0)), h21(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * vnoise(p);
		p = p * 2.03 + vec2(17.1, 9.2);
		a *= 0.5;
	}
	return v;
}

// densidad de las nubes en p (en unidades de alto), con su deriva
float clouds(vec2 p, float t) {
	vec2 q = p;
	if (mode == 3) {                             // R'lyeh: el cielo gira alrededor de la luna
		vec2 c = vec2(moon_pos.x * aspect, moon_pos.y);
		vec2 d = q - c;
		float r = length(d);
		float a = 0.35 / (0.4 + r) * sin(t * 0.03) + t * 0.006 / (0.3 + r);
		q = c + mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a))) * d;
	}
	float drift = mode == 2 ? 0.02 : 0.008;
	return fbm(q * vec2(2.4, 6.0) + vec2(t * drift + seed, seed * 0.37));
}

void fragment() {
	vec2 uv = UV;
	vec2 p = vec2(uv.x * aspect, uv.y);
	float t = TIME;
	vec3 col = mix(top_col, hor_col, smoothstep(0.0, 0.62, uv.y));
	// estrellas: una por celda, si le toca; se apagan hacia el horizonte
	vec2 sc = p * 150.0;
	vec2 cid = floor(sc);
	float sh = h21(cid + seed);
	if (sh > 0.982 && mode != 2) {
		vec2 sp = cid + vec2(h21(cid + 3.1), h21(cid + 7.7)) * 0.6 + 0.2;
		float d = length(sc - sp);
		float tw = 0.65 + 0.35 * sin(t * (1.2 + sh * 2.0) + sh * 40.0);
		vec3 sccol = mode == 3 ? vec3(0.95, 0.75, 0.6) : vec3(0.85, 0.9, 1.0);
		col += sccol * (1.0 - smoothstep(0.0, 0.55, d)) * tw * (1.0 - smoothstep(0.15, 0.55, uv.y)) * 0.9;
	}
	// aurora: cortinas que ondulan, en columnas como de bloques
	if (mode == 1) {
		float xq = floor(p.x / (block * 0.6)) * block * 0.6;
		for (int k = 0; k < 2; k++) {
			float fk = float(k);
			float xw = xq * (1.4 + fk * 0.7) + 0.25 * sin(xq * 2.1 + t * 0.07 + fk * 2.0) + fk * 3.0;
			float curtain = pow(fbm(vec2(xw * 3.0, t * 0.04 + fk * 5.0)), 2.2) * 2.4;
			float base = 0.2 + 0.07 * sin(xq * 1.3 + fk + t * 0.05) + fk * 0.04;    // borde de abajo
			float above = base - uv.y;
			float band = smoothstep(-0.015, 0.01, above) * exp(-max(above, 0.0) * (5.0 + fk * 3.0));
			vec3 ac = mix(glow_a, glow_b, smoothstep(0.0, 0.22, above));
			float rays = 0.35 + 0.65 * vnoise(vec2(xq * 38.0 + fk * 11.0, t * 0.25));   // rayos verticales
			col += ac * curtain * rays * band * (0.6 - fk * 0.2);
		}
	}
	// luna (no en la tormenta): disco con manchas y halo
	if (mode != 2) {
		vec2 mp = vec2(moon_pos.x * aspect, moon_pos.y);
		float r = length(p - mp);
		float disc = 1.0 - smoothstep(moon_r - 0.002, moon_r, r);
		float spots = fbm((p - mp) * 55.0 + 3.0);
		vec3 mc = moon_col * (0.78 + 0.28 * smoothstep(0.35, 0.7, spots));
		if (mode == 3) {                         // gibosa: la sombra se come un lado
			float sh2 = length(p - mp - vec2(moon_r * 0.55, -moon_r * 0.1));
			mc *= mix(0.12, 1.0, smoothstep(moon_r * 0.85, moon_r * 1.05, sh2));
		}
		col = mix(col, mc, disc);
		col += moon_col * exp(-max(r - moon_r, 0.0) * 18.0) * 0.16 * (1.0 - disc);
	}
	// nubes voxel: el ruido en bloques, con el canto de arriba aclarado por la luna
	vec2 qb = floor(p / block) * block + block * 0.5;
	float band = smoothstep(0.03, 0.14, uv.y) * (1.0 - smoothstep(0.34, 0.5, uv.y));
	if (mode == 2) band = 1.0 - smoothstep(0.4, 0.56, uv.y);
	float dc = clouds(qb, t) * band;
	float up = clouds(qb - vec2(0.0, block * 2.0), t) * band;
	float edge = cover + (mode == 2 ? -0.08 : 0.0);
	if (dc > edge) {
		float rim = clamp((dc - up) * 12.0, 0.0, 1.0);          // borde de arriba: más luz
		float deep = smoothstep(edge, edge + 0.18, dc);
		vec3 cc = mix(cloud_lit, cloud_dark, deep);
		cc = mix(cc, cloud_lit * 1.35, rim * 0.6);
		if (mode != 2) {                                       // cerca de la luna, más claras
			vec2 mp = vec2(moon_pos.x * aspect, moon_pos.y);
			cc += moon_col * 0.18 * exp(-length(qb - mp) * 4.0);
		}
		cc += vec3(0.75, 0.8, 1.0) * flash * (0.35 + 0.5 * rim);
		col = mix(col, cc, 0.92);
	} else {
		col += vec3(0.5, 0.55, 0.7) * flash * 0.12;
	}
	// tormenta: lluvia y el rayo
	if (mode == 2) {
		vec2 rp = vec2(p.x * 110.0 + p.y * 22.0, p.y * 6.0 + t * 2.6);
		float colm = h21(vec2(floor(rp.x), 1.0));
		float streak = step(0.86, colm) * smoothstep(0.75, 1.0, fract(rp.y + colm * 7.0));
		col += vec3(0.45, 0.5, 0.6) * streak * 0.12 * smoothstep(0.1, 0.4, uv.y);
		if (flash > 0.4) {
			float bx = bolt_x * aspect + (fbm(vec2(uv.y * 9.0, seed + floor(t))) - 0.5) * 0.22;
			float w = 1.0 - smoothstep(0.0, 0.0035, abs(p.x - bx));
			col += vec3(0.85, 0.9, 1.0) * w * smoothstep(0.05, 0.12, uv.y) * (1.0 - smoothstep(0.45, 0.6, uv.y)) * (flash - 0.4) * 2.5;
		}
	}
	col *= 1.0 - 0.9 * smoothstep(0.42, 0.72, uv.y);          // bajo el horizonte, la tierra a oscuras
	COLOR = vec4(col * dim, 1.0);
}
