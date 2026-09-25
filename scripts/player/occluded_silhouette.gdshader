// Silueta del jugador cuando lo tapa el decorado (pilar de legibilidad).
// Se aplica como material_overlay: dibuja la misma malla sin test de profundidad y
// descarta los fragmentos que no están tapados, de modo que solo queda la parte oculta,
// teñida con el color del jugador.
// Para que el propio cuerpo (un brazo delante del torso) no cuente como obstáculo, lo
// que tapa tiene que estar al menos `margin` metros por delante.
shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_back, shadows_disabled;

uniform vec4 color : source_color = vec4(1.0, 0.82, 0.3, 0.55);
uniform float margin = 0.5;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;

void fragment() {
	float depth = texture(depth_tex, SCREEN_UV).r;
	vec4 view = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	float scene_dist = -view.z / view.w;     // distancia a la cámara de lo ya dibujado
	float frag_dist = -VERTEX.z;              // distancia de este fragmento del jugador
	if (scene_dist > frag_dist - margin) {
		discard;
	}
	ALBEDO = color.rgb;
	ALPHA = color.a;
}
