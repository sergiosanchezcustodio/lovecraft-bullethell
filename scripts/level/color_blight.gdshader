// El color que cayó del cielo (hito 21.13, ColorBlight): una mancha en el suelo, a bloques de 1/8 m,
// de un color que cambia sin parar (nunca se queda en uno con nombre) y con un borde de ceniza gris
// que se come la tierra. INSTANCE_CUSTOM: x, la semilla; y, el radio (m); z, cuánto ha nacido (0..1).
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

// el hash sin senos de night_sky.gdshaderinc (sin sus uniformes)
float sky_hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

const float BLOCK = 0.125;

varying float seed;
varying float radius;
varying float born;

void vertex() {
	seed = INSTANCE_CUSTOM.x;
	radius = max(INSTANCE_CUSTOM.y, 0.05);
	born = INSTANCE_CUSTOM.z;
}

void fragment() {
	vec2 c = (UV - 0.5) * 2.0 * radius;                  // metros desde el centro
	vec2 blk = floor(c / BLOCK);
	float d = length((blk + 0.5) * BLOCK) / radius;      // 0 en el centro, 1 en el borde
	float n = sky_hash(blk + vec2(seed * 17.0, seed * 5.0));
	float edge = 1.0 - n * 0.22;
	if (d > edge) discard;
	float t = TIME * 0.35 + seed;
	// el color: va y viene entre un rosa violáceo, un lila y un verde de cristal, por zonas
	float h = sky_hash(floor(blk * 0.5) + vec2(seed, 1.0));
	float w = 0.5 + 0.5 * sin(t * 2.1 + h * 6.28 + d * 5.0);
	vec3 a = mix(vec3(0.82, 0.16, 0.66), vec3(0.46, 0.2, 0.92), w);
	vec3 col = mix(a, vec3(0.3, 0.85, 0.62), pow(0.5 + 0.5 * sin(t * 1.3 - d * 3.0 + h * 3.0), 3.0) * 0.75);
	float flick = 0.8 + 0.3 * sin(TIME * 7.0 + n * 40.0);
	col *= 0.62 * flick * (1.2 - 0.45 * d) * (0.75 + 0.5 * n);
	float alpha = 0.82;
	// el borde: ceniza gris, a manchas, y algún bloque del color que se escapa
	if (d > 0.72 * edge) {
		bool ash = n > 0.25;
		col = ash ? vec3(0.2, 0.2, 0.19) * (0.8 + 0.4 * n) : col;
		alpha = ash ? 0.9 : 0.75;
	}
	ALBEDO = col;
	ALPHA = alpha * clamp(born * 1.5, 0.0, 1.0);
}
