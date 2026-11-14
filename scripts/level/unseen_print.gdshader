// Huella de lo que no se ve (hito 21.14, Unseen): un hoyo redondo, como el fondo de un tonel, a bloques
// de 1/8 m, oscuro en medio y con un reborde roto de tierra y hierba aplastada alrededor.
// INSTANCE_CUSTOM: x, la semilla; y, el radio (m); z, lo que queda de ella (1 recién hecha, 0 se fue).
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, shadows_disabled;   // con luz, como el suelo

// el hash sin senos de night_sky.gdshaderinc (sin sus uniformes)
float sky_hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

const float BLOCK = 0.125;

varying float seed;
varying float radius;
varying float left;

void vertex() {
	seed = INSTANCE_CUSTOM.x;
	radius = max(INSTANCE_CUSTOM.y, 0.05);
	left = INSTANCE_CUSTOM.z;
}

void fragment() {
	vec2 c = (UV - 0.5) * 2.0 * radius * 1.35;                // metros desde el centro (con sitio para el reborde)
	vec2 blk = floor(c / BLOCK);
	float d = length((blk + 0.5) * BLOCK) / radius;           // 1: el borde del hoyo
	float n = sky_hash(blk + vec2(seed * 17.0, seed * 5.0));
	float edge = 1.0 + (n - 0.5) * 0.25;
	vec3 col;
	float a;
	if (d < edge * 0.92) {                                    // el hoyo
		col = mix(vec3(0.012, 0.012, 0.01), vec3(0.03, 0.028, 0.022), n);
		a = 0.9;
	} else if (d < edge * 1.3 && n > 0.25) {                  // el reborde, roto
		col = mix(vec3(0.1, 0.09, 0.06), vec3(0.17, 0.15, 0.1), n);
		a = 0.75;
	} else {
		discard;
	}
	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	ALPHA = a * clamp(left * 1.5, 0.0, 1.0);
}
