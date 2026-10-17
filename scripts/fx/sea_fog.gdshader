// Niebla que se arrastra por el agua del puerto de noche (ambiente de los escenarios, 16-10-2026):
// jirones bajos estirados con el viento, en celdas de 1/8 m como el resto del voxel, que solo
// están sobre el mar (se deshacen al llegar a la orilla). Ambient pone dos capas a distinta
// altura y velocidad.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

#include "res://scripts/fx/night_sky.gdshaderinc"

uniform vec3 color : source_color = vec3(0.42, 0.47, 0.5);
uniform float amount = 0.5;
uniform vec2 shore = vec2(32.0, 32.0);
uniform float north_shore = -100000.0;
uniform vec2 wind = vec2(0.35, 0.15);        // m/s
uniform float cell = 0.125;
uniform float seed = 0.0;
uniform vec4 beam = vec4(0.0);               // faro: xy origen, z ángulo, w medio ancho (rad)
uniform float beam_k = 0.0;

varying vec3 wp;

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float vn(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(sky_hash(i), sky_hash(i + vec2(1, 0)), f.x), mix(sky_hash(i + vec2(0, 1)), sky_hash(i + vec2(1, 1)), f.x), f.y);
}

void fragment() {
	vec2 c = (floor(wp.xz / cell) + 0.5) * cell;
	float d = length(max(c - shore, vec2(0.0)));
	if (c.x < shore.x) d = c.y - shore.y;
	if (c.y < shore.y) d = c.x - shore.x;
	if (c.y < north_shore) d = north_shore - c.y;
	float fade = smoothstep(0.3, 3.5, d);
	vec2 w = normalize(wind + vec2(1e-4));
	vec2 q = c - wind * TIME;
	vec2 r = vec2(dot(q, w) * 0.45, dot(q, vec2(-w.y, w.x)));     // estirada con el viento
	float n = vn(r * 0.16 + seed) * 0.6 + vn(r * 0.4 + seed * 1.7 + 3.1) * 0.3 + vn(q * 1.3 + seed) * 0.1;
	float a = smoothstep(0.42, 0.78, n) * amount * fade;
	vec3 col = color * (0.9 + 0.2 * vn(q * 0.7 + 9.0));
	if (beam_k > 0.0) {                      // el haz ilumina la niebla por donde pasa
		vec2 rel = c - beam.xy;
		float da = abs(mod(atan(rel.y, rel.x) - beam.z + 3.14159265, 6.2831853) - 3.14159265);
		float k = (1.0 - smoothstep(beam.w * 0.3, beam.w, da)) * beam_k * clamp(1.4 - length(rel) / 80.0, 0.0, 1.0);
		col = mix(col, vec3(0.95, 0.88, 0.72), k * 0.8);
		a = max(a, k * 0.22 * fade * (0.5 + 0.5 * n));
	}
	ALBEDO = col;
	ALPHA = clamp(a, 0.0, 0.85);
}
