// Ventanas que se encienden y se apagan solas (ambiente de los escenarios, 16-10-2026). Capa de
// los voxels con glow 2: VoxelBuilder numera cada ventana en UV.x. Cada una, en cada casa (la
// posición de la pieza cambia la suerte), pasa por turnos de 20-40 s encendida o apagada; al
// encenderse titubea como una lámpara que prende y, encendida, oscila un poco.
shader_type spatial;
render_mode unshaded;

uniform bool colors_srgb = true;
uniform float on_share = 0.35;                 // parte de las ventanas encendidas a la vez
uniform float period_min = 20.0;
uniform float period_max = 40.0;
uniform vec3 off_color : source_color = vec3(0.045, 0.05, 0.06);

varying float lit;

// hash sin senos: con sin() de argumentos de miles, en la GPU casi todas salían encendidas
float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float state(vec2 seed, float slot) { return step(hash(seed + vec2(slot * 1.37, 0.5)), on_share); }

void vertex() {
	if (colors_srgb) {
		COLOR.rgb = mix(pow((COLOR.rgb + vec3(0.055)) * (1.0 / 1.055), vec3(2.4)), COLOR.rgb * (1.0 / 12.92), lessThan(COLOR.rgb, vec3(0.04045)));
	}
	vec2 seed = vec2(UV.x * 7.13, dot(NODE_POSITION_WORLD.xz, vec2(0.37, 0.71)));
	float h0 = hash(seed);
	float period = mix(period_min, period_max, hash(seed + 3.1));
	float tt = TIME + h0 * period * 7.0;
	float slot = floor(tt / period);
	float u = tt - slot * period;                 // s desde el último cambio
	float now = state(seed, slot);
	float before = state(seed, slot - 1.0);
	lit = now;
	if (now != before && u < 1.1) {
		if (now > before) {                       // prende: dos o tres titubeos y se asienta
			float f = step(0.5, hash(vec2(floor(u * 14.0), h0)));
			lit = u < 0.7 ? f * smoothstep(0.0, 0.7, u) + 0.15 : 1.0;
		} else {
			lit = 1.0 - smoothstep(0.0, 0.5, u);  // se apaga en medio segundo
		}
	}
	lit *= 0.93 + 0.07 * sin(TIME * 5.3 + h0 * 40.0) * sin(TIME * 2.1 + h0 * 13.0);
}

void fragment() {
	ALBEDO = mix(off_color, COLOR.rgb * 1.25, clamp(lit, 0.0, 1.0));
}
