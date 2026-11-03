// Motas de polvo de los haces de luna (hito 16.32): partículas en la caja del haz que solo se ven
// dentro de él (shaft_inside), de cara a la cámara.
shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

#include "res://scripts/fx/moon_shaft.gdshaderinc"

uniform vec3 color : source_color = vec3(0.7, 0.8, 1.0);
uniform float energy = 1.0;
varying float vis;

void vertex() {
	vis = shaft_inside(shaft_local(MODEL_MATRIX[3].xyz)) * COLOR.a;
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}

void fragment() {
	if (vis <= 0.001) discard;
	float r = length(UV - 0.5) * 2.0;
	ALBEDO = color * energy * vis * (1.0 - smoothstep(0.3, 1.0, r)) * 1.6;
	ALPHA = 1.0;
}
