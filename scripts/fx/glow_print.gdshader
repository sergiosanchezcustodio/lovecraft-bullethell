// Huella de luz en el agua somera del arrecife (ambiente, 17-10-2026): al pisar se enciende el
// plancton; puntos verdes azulados en celdas de 1/32 m, más juntos en el centro, que se abren
// un poco y se apagan de dentro afuera.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform float life = 0.0;                  // 0..1
uniform float radius = 0.4;
uniform float cell = 0.03125;
uniform vec3 tint : source_color = vec3(0.25, 0.95, 0.75);
uniform float seed = 0.0;

varying vec3 wp;

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float h21(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec2 c = floor(wp.xz / cell);
	vec2 cc = (c + 0.5) * cell;
	float d = length(cc - NODE_POSITION_WORLD.xz) / (radius * (0.75 + 0.35 * life));
	float h = h21(c + seed);
	float dens = (1.0 - smoothstep(0.2, 1.0, d)) * 0.75;
	float on = step(1.0 - dens, h);
	float fade = pow(1.0 - life, 1.4) * (1.0 - smoothstep(0.0, 1.0, life * 1.6 - d * 0.6 - h * 0.3 + 0.2));
	float tw = 0.65 + 0.35 * sin(TIME * (3.0 + h * 5.0) + h * 40.0);
	ALBEDO = tint * on * fade * tw * 0.9;
}
