// Cristal que refleja el cielo de noche (ventanales del estudio, claraboyas; ambiente de los
// escenarios, 16-10-2026). Capa de los voxels con glow 3: su color (azul de noche) más estrellas
// que titilan en celdas de un voxel, más claro arriba, y alguna fugaz que cruza el cristal.
shader_type spatial;
render_mode unshaded;

#include "res://scripts/fx/night_sky.gdshaderinc"

uniform bool colors_srgb = true;
uniform float density = 0.035;

varying vec3 wpos;

void vertex() {
	if (colors_srgb) {
		COLOR.rgb = mix(pow((COLOR.rgb + vec3(0.055)) * (1.0 / 1.055), vec3(2.4)), COLOR.rgb * (1.0 / 12.92), lessThan(COLOR.rgb, vec3(0.04045)));
	}
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 q = vec2(wpos.x + wpos.z, wpos.y);      // en el plano del cristal (paredes en X o en Z)
	vec2 cid = floor(q * 32.0);
	vec3 col = COLOR.rgb * (0.85 + 0.3 * clamp(fract(wpos.y * 0.25), 0.0, 1.0));
	col += star_at(cid, TIME, density) * 0.9;
	float t = TIME / 23.0;                        // una fugaz por cristal de vez en cuando
	float slot = floor(t);
	float u = (t - slot) * 23.0;
	vec2 cell = floor(q / 3.0);
	if (sky_hash(cell + slot * 3.1) > 0.93 && u < 1.0) {
		vec2 o = (cell + vec2(sky_hash(cell + 1.0 + slot), 0.8)) * 3.0;
		vec2 d = q - (o + vec2(-1.6, -0.9) * u);
		float s = abs(d.y - d.x * 0.56);
		float along = dot(d, normalize(vec2(1.6, 0.9)));
		col += vec3(1.0, 0.96, 0.85) * step(s, 0.035) * step(0.0, along) * step(along, 0.9) * (1.0 - along / 0.9) * (1.0 - u) * 2.0;
	}
	ALBEDO = col;
}
