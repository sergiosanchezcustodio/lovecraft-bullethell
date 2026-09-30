shader_type spatial;
// Suelo de nieve en voxel fino (30-09-2026): celdas de `cell` m con altura en escalones
// (ventisqueros grandes y sastrugi alargados por el viento), sombreado por un relieve falso
// en la normal, placas de hielo azulado y nieve pisada alrededor del campamento.
// Todo en coordenadas del mundo: no depende de cómo esté hecha la malla.

uniform float cell = 0.125;
uniform vec3 snow_hi : source_color = vec3(0.93, 0.95, 0.98);
uniform vec3 snow_lo : source_color = vec3(0.78, 0.84, 0.93);
uniform vec3 ice : source_color = vec3(0.62, 0.78, 0.90);
uniform vec3 trampled : source_color = vec3(0.74, 0.76, 0.80);
uniform vec3 edge_col : source_color = vec3(0.55, 0.70, 0.82);
uniform vec2 wind = vec2(0.8, 0.6);
uniform float camp_radius = 14.0;
uniform float relief = 1.6;

varying vec3 wpos;
varying vec3 wnrm;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

float vnoise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

float fbm(vec2 p) {
	float s = 0.0, a = 0.5;
	mat2 r = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
	for (int i = 0; i < 4; i++) { s += a * vnoise(p); p = r * p * 2.03; a *= 0.5; }
	return s;
}

// Altura de la celda c (en escalones enteros)
float height(vec2 c) {
	vec2 p = c * cell;
	vec2 wd = normalize(wind);
	vec2 q = vec2(dot(p, wd), dot(p, vec2(-wd.y, wd.x)));
	float drift = fbm(p * 0.07) * 6.0;                            // ventisqueros
	float sas = fbm(vec2(q.x * 1.6, q.y * 0.35)) * 1.4;            // sastrugi, alargados por el viento
	float grain = hash(c) * 0.3;                                   // grano de voxel
	return floor(drift + sas + grain);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	if (wnrm.y < 0.5) {                                            // frente de la orilla
		ALBEDO = edge_col;
		ROUGHNESS = 0.4;
	} else {
		vec2 c = floor(wpos.xz / cell);
		float h = height(c);
		float hx = height(c + vec2(1, 0)) - height(c - vec2(1, 0));
		float hz = height(c + vec2(0, 1)) - height(c - vec2(0, 1));
		vec3 n = normalize(vec3(-hx * 0.18 * relief, 1.0, -hz * 0.18 * relief));
		NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);

		float t = clamp(h / 7.0, 0.0, 1.0);
		vec3 col = mix(snow_lo, snow_hi, t);
		col *= 0.97 + 0.05 * hash(c + 17.0);                       // variación por celda
		// placas de hielo (en las hondonadas y por manchas)
		float icy = fbm(wpos.xz * 0.05 + 40.0);
		float ice_m = step(0.64, icy) * step(h, 3.0);
		// nieve pisada alrededor del campamento, a manchas
		float d = length(wpos.xz);
		float tr = step(fbm(wpos.xz * 0.35 + 9.0), 0.52 - (d - camp_radius) * 0.04) * step(d, camp_radius + 4.0);
		col = mix(col, trampled * (0.96 + 0.06 * hash(c)), tr * 0.8);
		col = mix(col, ice * (0.95 + 0.08 * hash(c + 3.0)), ice_m);
		ALBEDO = col;
		ROUGHNESS = mix(0.9, 0.35, ice_m);
		SPECULAR = mix(0.3, 0.6, ice_m);
	}
}
