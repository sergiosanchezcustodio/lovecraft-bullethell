// Sombreador de los efectos de las armas en el aire (FxShade, hito 18.2, D-50). Sobre una caja o un
// plano de 1×1×1 escalado: la forma sale de las coordenadas locales, partidas en celdas de voxel
// del mundo (`cell` m), así que todo va a cubitos aunque se estire. Cada celda calcula su «calor»
// (0..1), se escalona en `steps` tramos y toma el color y la opacidad de la rampa de su receta.
// mode 0 haz: brillante en el eje y cerca del origen (x = 0), con ondas que corren hacia la punta
// (`scroll` m/s) y chispas sueltas.
// mode 1 arco: sobre el anillo de `VoxelFx.arc_ring()` (UV.x, la vuelta; UV.y, de dentro afuera),
// una hoja que barre la vuelta (`age` 0..1, la cabeza casi blanca) con estela que se apaga y vetas.
// mode 2 fogonazo: sobre un cuadro (`VoxelFx.quad1()`) que mira a la cámara; calor radial en
// anillos a escalones, borde roto por ruido, y el centro que se encoge con `age` (0..1).
// mode 3 cortina: sobre el cilindro de `VoxelFx.ring_wall()`, luz que sube desde el suelo y se
// deshace hacia arriba en celdas que parpadean (ondas y signos, hito 18.11).
// Por instancia: `fade` (0..1), `tint` (multiplica), `seed` y `age`.
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
instance uniform float age = 0.0;
uniform float tail = 2.6;                        // arco: largo de la estela (rad)
uniform bool axis_z = false;                     // haz: a lo largo de -Z (barras con look_at; el origen en +Z)
uniform float falloff = 0.6;                     // haz: cuánto se apaga hacia la punta
uniform bool across = false;                        // haz: del eje al borde solo a lo ancho (se ve desde arriba; trapezoedro, 10-11-2026)

varying vec3 lp;
varying vec3 sz;

void vertex() {
	lp = VERTEX;
	sz = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	if (mode == 2) {                               // de cara a la cámara, con su escala
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * sz.x, INV_VIEW_MATRIX[1] * sz.y,
			INV_VIEW_MATRIX[2] * sz.z, MODEL_MATRIX[3]);
		MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	}
}

void fragment() {
	if (mode == 3) {
		float n = max(floor(6.2831853 * sz.x / cell), 24.0);
		float hn = max(floor(sz.y / cell), 2.0);
		float ua = floor(UV.x * n);
		float hy = floor(UV.y * hn);
		float yv = (hy + 0.5) / hn;                       // 0 abajo, 1 arriba
		float flick = fx_noise(vec2(ua * 0.45 + seed * 5.0, yv * 3.0 - TIME * scroll));
		float h = pow(1.0 - yv, 1.5) * (0.5 + 0.65 * flick)
			+ step(sparkle, fx_hash(vec2(ua, hy) + vec2(floor(TIME * 14.0), seed * 7.0))) * 0.5 * (1.0 - yv);
		h = floor(clamp(h, 0.0, 0.999) * steps + 0.5) / steps;
		vec4 cw = texture(ramp, vec2(h, 0.5));
		if (cw.a < 0.004) discard;
		ALBEDO = cw.rgb * tint.rgb * energy;
		ALPHA = clamp(cw.a * tint.a * fade, 0.0, 1.0);
	} else if (mode == 2) {
		float n = max(floor(sz.x / cell), 8.0);         // celdas de voxel en el cuadro
		vec2 c2 = (floor(UV * n) + 0.5) / n;
		vec2 q = c2 * 2.0 - 1.0;
		float r = length(q);
		float ang = atan(q.y, q.x);
		float edge = 0.78 + 0.22 * fx_noise(vec2(ang * 2.2 + seed, seed * 3.1));
		float rr = r / edge;
		if (rr > 1.0) discard;
		float core = 1.0 - age * 0.65;
		float h = pow(clamp(1.0 - rr, 0.0, 1.0), 1.3) * (0.75 + 0.45 * fx_noise(floor(UV * n) * 0.5 + seed)) * core
			+ step(rr, 0.28 * core) * 0.35;
		h = floor(clamp(h, 0.0, 0.999) * steps + 0.5) / steps;
		vec4 cf = texture(ramp, vec2(h, 0.5));
		ALBEDO = cf.rgb * tint.rgb * energy;
		ALPHA = clamp(cf.a * tint.a * fade, 0.0, 1.0);
	} else if (mode == 1) {
		// celdas: a lo largo de la vuelta, de `cell` m en el borde de fuera; a lo ancho, 5
		float n = max(floor(6.2831853 * sz.x / cell), 24.0);
		float ua = (floor(UV.x * n) + 0.5) / n;
		float ur = (floor(UV.y * 5.0) + 0.5) / 5.0;
		float ang = ua * 6.2831853;
		float head = age * 6.2831853 * 1.15;
		float behind = head - ang;
		if (behind < 0.0) behind += 6.2831853 * step(6.2831853, head);
		float tr = 1.0 - behind / tail;
		if (behind < 0.0 || tr <= 0.0) discard;
		float band = 1.0 - abs(ur - 0.7) / 0.5;           // el filo, hacia fuera
		float vein = fx_noise(vec2(floor(UV.x * n) * 0.35, ur * 3.0 + seed));
		float h = tr * tr * band * (0.6 + 0.55 * vein) + step(behind, 0.22) * band * 0.6;
		h = floor(clamp(h, 0.0, 0.999) * steps + 0.5) / steps;
		vec4 ca = texture(ramp, vec2(h, 0.5));
		ALBEDO = ca.rgb * tint.rgb * energy;
		ALPHA = clamp(ca.a * tint.a * fade, 0.0, 1.0);
	} else {
	vec3 m = (lp + 0.5) * sz;                       // en metros, desde la esquina
	vec3 c = floor(m / cell);
	vec3 cm = (c + 0.5) * cell;
	float al = axis_z ? (sz.z - cm.z) : cm.x;        // metros desde el origen
	float u = clamp(al / (axis_z ? sz.z : sz.x), 0.0, 1.0);   // a lo largo
	float v = across ? abs((axis_z ? cm.x / sz.x : cm.z / sz.z) * 2.0 - 1.0)
		: axis_z ? max(abs(cm.x / sz.x * 2.0 - 1.0), abs(cm.y / sz.y * 2.0 - 1.0))
		: abs(cm.z / sz.z * 2.0 - 1.0);
	v = clamp(v, 0.0, 1.0);                          // del eje (0) al borde (1)
	float cr = axis_z ? cm.x + cm.y : cm.z;
	float heat = 0.0;
	if (mode == 0) {
		float core = 1.0 - v * v;
		float along = 1.0 - u * falloff;
		float flow = fx_noise(vec2(al * 1.8 - TIME * scroll, cr * 4.0 + seed * 13.0));
		heat = core * along * (0.55 + 0.6 * flow);
		heat += step(sparkle, fx_hash(vec2(floor(al / cell), floor(cr / cell)) + vec2(floor(TIME * 14.0), seed * 7.0))) * 0.5 * core;
	}
	heat = floor(clamp(heat, 0.0, 0.999) * steps + 0.5) / steps;
	vec4 col = texture(ramp, vec2(heat, 0.5));
	ALBEDO = col.rgb * tint.rgb * energy;
	ALPHA = clamp(col.a * tint.a * fade, 0.0, 1.0);
	}
}
