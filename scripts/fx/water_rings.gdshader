// Ondas en el agua somera (hito 11.4, 28-10-2026): las de ripple.gdshader, pero todas en un
// MultiMesh (Ripples): cada instancia lleva en INSTANCE_CUSTOM su vida (0..1), su radio final
// (m) y su opacidad. Dos aros que se abren y se apagan, en celdas de 1/32 m como el voxel.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform float cell = 0.03125;
uniform vec3 tint : source_color = vec3(0.62, 0.7, 0.66);

varying vec3 wp;
varying flat vec3 center;
varying flat vec3 data;

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	center = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	data = INSTANCE_CUSTOM.xyz;
}

float ring(float d, float r, float w) {
	return 1.0 - smoothstep(0.0, w, abs(d - r));
}

void fragment() {
	float life = data.x;
	vec2 c = (floor(wp.xz / cell) + 0.5) * cell;
	float d = length(c - center.xz) / max(data.y, 0.05);
	float a = ring(d, life, 0.07) + 0.7 * ring(d, life * 0.62 - 0.06, 0.06) * step(0.1, life);
	a *= pow(1.0 - life, 1.5) * step(d, 1.0);
	ALBEDO = tint;
	ALPHA = clamp(a, 0.0, 1.0) * data.z;
}
