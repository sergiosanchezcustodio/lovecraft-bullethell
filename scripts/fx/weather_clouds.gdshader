// Sombras de las nubes del clima (D-33): un plano a ras de suelo que multiplica lo que hay
// debajo por un tono algo más oscuro y frío donde pasa una nube. La forma es ruido de
// gradiente en coordenadas del mundo, empujado por el viento (`offset`). Solo el suelo y el
// agua quedan debajo: personajes y decorado lo tapan.
shader_type spatial;
render_mode unshaded, blend_mul, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform float strength = 0.25;          // cuánto oscurece la sombra (0..1)
uniform float scale = 18.0;             // m por unidad de ruido
uniform vec2 offset = vec2(0.0);

varying vec3 world_pos;

vec2 hash2(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float gnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(dot(hash2(i), f), dot(hash2(i + vec2(1, 0)), f - vec2(1, 0)), u.x),
		mix(dot(hash2(i + vec2(0, 1)), f - vec2(0, 1)), dot(hash2(i + vec2(1, 1)), f - vec2(1, 1)), u.x), u.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = (world_pos.xz - offset) / scale;
	float n = gnoise(p) * 0.65 + gnoise(p * 2.1 + 3.7) * 0.35;
	float shade = smoothstep(0.0, 0.35, n) * strength;
	vec2 c = UV * 2.0 - 1.0;
	shade *= 1.0 - smoothstep(0.75, 1.0, max(abs(c.x), abs(c.y)));   // sin borde visible
	ALBEDO = mix(vec3(1.0), vec3(0.6, 0.66, 0.78), shade);          // sombra algo fría
}
