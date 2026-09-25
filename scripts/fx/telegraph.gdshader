// Aviso en el suelo: anillo exterior y relleno que crece hasta el momento del impacto.
// Parpadea en el último 20 %. Sin relleno (fill = false) es un anillo tenue fijo.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec4 color : source_color = vec4(1.0, 0.36, 0.18, 0.7);
uniform float progress = 0.0;
uniform bool fill = true;
uniform float ring_width = 0.08;
uniform bool soft = false;              // disco difuminado sin anillo (manchas de quemado)

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	if (r > 1.0) discard;
	if (soft) {
		ALBEDO = color.rgb;
		ALPHA = smoothstep(1.0, 0.25, r) * color.a;
	} else {
	float ring = smoothstep(1.0 - ring_width * 1.6, 1.0 - ring_width, r) * smoothstep(1.0, 1.0 - ring_width * 0.5, r);
	float inner = fill ? step(r, progress) * 0.38 + step(abs(r - progress), 0.025) * 0.6 : 0.12;
	float blink = (fill && progress > 0.8) ? 0.55 + 0.45 * sin(TIME * 40.0) : 1.0;
	float a = max(ring, inner) * color.a * blink;
	if (a < 0.01) discard;
	ALBEDO = color.rgb * 0.85;      // algo por debajo de 1: el tonemapper aclara lo no iluminado
	ALPHA = a;
	}
}
