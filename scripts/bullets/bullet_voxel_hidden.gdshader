// Segunda pasada de las balas voxel: donde el decorado tapa una bala, su silueta en un
// tono plano de su tipo (las balas se leen siempre, GDD 4.4). Misma técnica que la
// silueta del jugador: sin test de profundidad y descartando lo que no está tapado.
shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_back, shadows_disabled, fog_disabled;

#include "res://scripts/bullets/bullet_voxel.gdshaderinc"

uniform vec3 phys_color : source_color = vec3(0.62, 0.26, 0.12);
uniform vec3 ment_color : source_color = vec3(0.44, 0.28, 0.62);
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;

void vertex() {
	v_style = INSTANCE_CUSTOM.x;
	v_group = group_of(COLOR);
	v_shade = COLOR.r;
	VERTEX = bullet_vertex(VERTEX, COLOR, INSTANCE_CUSTOM, TIME);
}

void fragment() {
	float depth = texture(depth_tex, SCREEN_UV).r;
	vec4 view = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	float scene_dist = -view.z / view.w;
	if (scene_dist > -VERTEX.z - 0.3) discard;               // no está tapada
	ALBEDO = (v_group > 1.5 || int(v_style + 0.5) == 2) ? ment_color : phys_color;
	ALPHA = 0.8;
}
