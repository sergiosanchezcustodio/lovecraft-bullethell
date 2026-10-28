// Ropa que se ensucia (hito 12.4, 28-10-2026): segunda pasada sobre el material de los jugadores.
// Desde los pies sube una mancha (nieve, barro, verdín) hasta `reach` m por `dirt` (0..1, crece
// durante el nivel), con el borde roto en celdas de voxel; y, si `top` > 0, se posa en las caras
// que miran arriba (nieve en hombros y sombrero). `wet` la hace brillar como mojada. Color y
// alcance son de la parte (data/dirt.json, los pone la partida); `dirt` y la altura de los pies,
// de cada jugador (parámetros de instancia).
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back;

uniform vec4 tint : source_color = vec4(0.9, 0.93, 1.0, 1.0);
uniform float reach = 0.35;                       // m desde los pies con dirt = 1
uniform float top = 0.0;                          // cuánto se posa en lo que mira arriba
uniform float wet = 0.0;
instance uniform float dirt = 0.0;
instance uniform float feet_y = 0.0;              // altura de los pies del jugador (mundo)
instance uniform float vox = 0.03125;

varying vec3 lp;
varying float wy;
varying vec3 wn;

float hash3(vec3 p) {                             // el de wounds.gdshader
	p = fract(p * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

float vnoise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = mix(hash3(i), hash3(i + vec3(1, 0, 0)), f.x);
	float b = mix(hash3(i + vec3(0, 1, 0)), hash3(i + vec3(1, 1, 0)), f.x);
	float c = mix(hash3(i + vec3(0, 0, 1)), hash3(i + vec3(1, 0, 1)), f.x);
	float d = mix(hash3(i + vec3(0, 1, 1)), hash3(i + vec3(1, 1, 1)), f.x);
	return mix(mix(a, b, f.y), mix(c, d, f.y), f.z);
}

void vertex() {
	lp = VERTEX - NORMAL * vox * 0.5;
	wy = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
	wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	if (dirt < 0.02) VERTEX = vec3(0.0);           // limpio: sin triángulos
}

void fragment() {
	vec3 c = floor(lp / vox);
	float n = vnoise(c * 0.22 + 3.0) * 0.65 + hash3(c + 11.0) * 0.35;
	float line = reach * dirt - (wy - feet_y);      // > 0 por debajo de la línea
	float low = smoothstep(0.0, 0.5, line / 0.06 + (n - 0.5) * 1.6);
	float up = top * dirt * smoothstep(0.65, 0.9, wn.y) * smoothstep(0.45, 0.6, n);
	float a = max(low * (0.72 + 0.28 * n), up);
	if (a < 0.05) discard;
	ALBEDO = tint.rgb * (0.85 + 0.3 * n);
	ROUGHNESS = mix(0.95, 0.25, wet);
	SPECULAR = mix(0.2, 0.6, wet);
	ALPHA = clamp(a, 0.0, 0.92);
}
