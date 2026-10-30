shader_type spatial;
// Mancha de luz de la linterna en el suelo (fase 14), para la calidad Baja: sin luz de verdad,
// un círculo cálido que se suma a lo que hay debajo, más fuerte en el centro.
render_mode blend_add, unshaded, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec4 tint : source_color = vec4(1.0, 0.86, 0.58, 1.0);
uniform float strength = 0.38;

void fragment() {
	float r = length(UV * 2.0 - 1.0);
	float a = smoothstep(1.0, 0.15, r);
	ALBEDO = tint.rgb * a * a * strength;
}
