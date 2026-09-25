// Silueta del jugador cuando lo tapa el decorado (pilar de legibilidad).
// Se aplica como material_overlay: dibuja la misma malla sin test de profundidad y
// descarta los fragmentos que no están tapados por el decorado, de modo que solo queda
// la parte oculta, teñida con el color del jugador.
//
// La oclusión se mide contra el CENTRO del personaje, no contra cada fragmento: en la
// vista isométrica el brazo del lado lejano queda más de medio metro por detrás del
// torso, y compararlo fragmento a fragmento hacía que el propio cuerpo contase como
// obstáculo (se veían los brazos a través del torso). Solo cuenta como obstáculo lo que
// está claramente por delante de todo el cuerpo.
shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_back, shadows_disabled;

uniform vec4 color : source_color = vec4(1.0, 0.82, 0.3, 0.55);
uniform vec3 center_world = vec3(0.0);       // centro del personaje (lo actualiza Player)
uniform float body_depth = 1.05;             // cuánto puede adelantarse el cuerpo respecto al centro (en el esquive se inclina hasta ~0,8 m)
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;

void fragment() {
	float depth = texture(depth_tex, SCREEN_UV).r;
	vec4 view = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	float scene_dist = -view.z / view.w;                          // lo ya dibujado en este píxel
	float center_dist = -(VIEW_MATRIX * vec4(center_world, 1.0)).z;
	float frag_dist = -VERTEX.z;
	// Tapado solo si lo que hay delante está por delante de todo el cuerpo
	// y además por delante de este fragmento.
	if (scene_dist > center_dist - body_depth || scene_dist > frag_dist - 0.05) {
		discard;
	}
	ALBEDO = color.rgb;
	ALPHA = color.a;
}
