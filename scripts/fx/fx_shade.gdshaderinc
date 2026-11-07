// Sombreador de los efectos de las armas en el aire (FxShade, hito 18.2, D-50). Sobre una caja o un
// plano de 1×1×1 escalado: la forma sale de las coordenadas locales, partidas en celdas de voxel
// del mundo (`cell` m), así que todo va a cubitos aunque se estire. Cada celda calcula su «calor»
// (0..1), se escalona en `steps` tramos y toma el color y la opacidad de la rampa de su receta.
// mode 0 haz: brillante en el eje y cerca del origen (x = 0), con ondas que corren hacia la punta
// (`scroll` m/s) y chispas sueltas. Por instancia: `fade` (0..1) y `tint` (multiplica).
#include "res://scripts/fx/fx_common.gdshaderinc"

uniform sampler2D ramp : source_color, filter_nearest, repeat_disable;
uniform int mode = 0;
uniform float cell = 0.0625;
uniform float steps = 5.0;
uniform float scroll = 4.0;
uniform float energy = 1.0;
uniform float sparkle = 0.985;
instance uniform float fade = 1.0;
instance uniform vec4 tint : source_color = vec4(1.0);
instance uniform float seed = 0.0;

varying vec3 lp;
varying vec3 sz;

void vertex() {
	lp = VERTEX;
	sz = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
}

void fragment() {
	vec3 m = (lp + 0.5) * sz;                       // en metros, desde la esquina
	vec3 c = floor(m / cell);
	vec3 cm = (c + 0.5) * cell;
	float u = clamp(cm.x / sz.x, 0.0, 1.0);          // a lo largo
	float v = clamp(abs(cm.z / sz.z * 2.0 - 1.0), 0.0, 1.0);   // del eje (0) al borde (1)
	float heat = 0.0;
	if (mode == 0) {
		float core = 1.0 - v * v;
		float along = 1.0 - u * 0.6;
		float flow = fx_noise(vec2(cm.x * 1.8 - TIME * scroll, cm.z * 4.0 + seed * 13.0));
		heat = core * along * (0.55 + 0.6 * flow);
		heat += step(sparkle, fx_hash(c.xz + vec2(floor(TIME * 14.0), seed * 7.0))) * 0.5 * core;
	}
	heat = floor(clamp(heat, 0.0, 0.999) * steps + 0.5) / steps;
	vec4 col = texture(ramp, vec2(heat, 0.5));
	ALBEDO = col.rgb * tint.rgb * energy;
	ALPHA = clamp(col.a * tint.a * fade, 0.0, 1.0);
}
