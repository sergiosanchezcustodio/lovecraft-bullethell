shader_type spatial;
// Burbuja del Escudo de Nodens (D-38): solo el borde brilla (fresnel), el centro deja ver al personaje.
render_mode unshaded, blend_add, cull_back, depth_draw_never, shadows_disabled;

uniform vec4 color : source_color = vec4(0.2, 0.45, 1.0, 1.0);
uniform float strength = 0.55;

void fragment() {
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	float pulse = 0.85 + 0.15 * sin(TIME * 3.0);
	ALBEDO = color.rgb * rim * strength * pulse;
}
