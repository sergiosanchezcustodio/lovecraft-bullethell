// Ondas que deja una gota al caer en el agua (ambiente de los túneles, 16-10-2026): dos aros
// que se abren y se apagan, dibujados en celdas de 1/32 m como el resto del voxel.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform float life = 0.0;                  // 0..1
uniform float radius = 0.5;                // m al final
uniform float cell = 0.03125;
uniform vec4 tint : source_color = vec4(0.42, 0.5, 0.58, 0.8);

varying vec3 wp;

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float ring(float d, float r, float w) {
	return 1.0 - smoothstep(0.0, w, abs(d - r));
}

void fragment() {
	vec2 c = (floor(wp.xz / cell) + 0.5) * cell;
	float d = length(c - NODE_POSITION_WORLD.xz) / radius;
	float a = ring(d, life, 0.07) + 0.7 * ring(d, life * 0.62 - 0.06, 0.06) * step(0.1, life);
	a *= pow(1.0 - life, 1.5) * step(d, 1.0);
	ALBEDO = tint.rgb;
	ALPHA = clamp(a, 0.0, 1.0) * tint.a;
}
