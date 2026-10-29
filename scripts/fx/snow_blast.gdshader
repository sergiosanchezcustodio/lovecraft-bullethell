shader_type spatial;
render_mode cull_disabled, depth_draw_never, shadows_disabled;
// Nieve apartada por una explosión (hito 12.11, 29-10-2026): en el centro, la nieve barrida
// (más oscura y azulada) y alrededor un reborde de nieve amontonada en terrones, en celdas de
// voxel. Con luz, como el suelo: de noche y en la sombra no brilla. Plano 2×2 escalado por el
// radio (VoxelFx.ground lo coloca igual); `fade` lo desvanece (GroundMarks).

uniform float fade = 1.0;
uniform float seed = 0.0;
uniform float cell = 0.0625;
uniform vec3 tint : source_color = vec3(0.82, 0.86, 0.94);

varying vec3 wpos;

// hash sin senos (el de night_sky.gdshaderinc)
float h21(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}
float vnoise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1, 0)), u.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), u.x), u.y);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 c = floor(wpos.xz / cell);
	vec2 cw = (c + 0.5) * cell;
	vec2 q = (cw - NODE_POSITION_WORLD.xz) / length(MODEL_MATRIX[0].xyz);
	float ang = atan(q.y, q.x);
	// borde roto: el radio cambia con el ángulo
	float wob = (vnoise(vec2(ang * 2.2, seed)) - 0.5) * 0.22 + (h21(c + seed) - 0.5) * 0.06;
	float r = length(q) - wob;
	if (r > 1.0) discard;
	float clump = h21(c * 1.7 + seed * 3.1);
	float inner = 1.0 - smoothstep(0.5, 0.66, r);
	float rim = smoothstep(0.6, 0.76, r) * (1.0 - smoothstep(0.86, 1.0, r));
	vec3 col = mix(tint * vec3(0.62, 0.68, 0.8), tint * (1.04 + 0.08 * clump), step(0.5, rim));
	ALBEDO = col;
	ROUGHNESS = 0.9;
	SPECULAR = 0.2;
	ALPHA = clamp(inner * 0.5 + rim * mix(0.45, 0.95, step(0.4, clump)), 0.0, 1.0) * fade;
}
