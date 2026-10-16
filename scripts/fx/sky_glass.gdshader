// Cristal que refleja el cielo de noche (ventanales del estudio, claraboyas; ambiente de los
// escenarios, 16-10-2026). Capa de los voxels con glow 3: su color (azul de noche) más estrellas
// que titilan en celdas de un voxel, más claro arriba, y alguna fugaz que cruza el cristal.
shader_type spatial;
render_mode unshaded;

#include "res://scripts/fx/night_sky.gdshaderinc"

uniform bool colors_srgb = true;
uniform float density = 0.035;
uniform float rain = 0.0;                       // gotas que resbalan por el cristal (y menos estrellas: nubes)

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
	col += star_at(cid, TIME, density) * 0.9 * (1.0 - 0.85 * rain);
	if (rain > 0.0) {                             // gotas: una por columna de celdas, a su ritmo, con estela
		col *= 1.0 - 0.12 * rain;
		float hc = sky_hash(vec2(cid.x, 7.0));
		if (hc < 0.2 * rain) {
			float speed = 0.22 + 0.35 * sky_hash(vec2(cid.x, 3.0));      // m/s
			float period = 1.5 + 3.0 * sky_hash(vec2(cid.x, 5.0));       // m entre gota y gota
			float s = mod(q.y + TIME * speed + sky_hash(vec2(cid.x, 9.0)) * period, period);
			float head = step(s, 2.0 / 32.0);
			float trail = step(s, 0.5) * (1.0 - s / 0.5);
			col += vec3(0.42, 0.48, 0.58) * (head * 0.9 + trail * 0.25) * rain;
		}
		col += vec3(0.35, 0.4, 0.5) * step(0.988, sky_hash(cid + 13.0)) * 0.6 * rain;   // gotitas quietas
	}
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
