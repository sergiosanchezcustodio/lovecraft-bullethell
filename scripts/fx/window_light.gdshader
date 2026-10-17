// La luz de un relámpago que entra por un ventanal del estudio (ambiente, 17-10-2026): en el
// suelo, el dibujo de la tracería (cristales en arco con parteluces y travesaños) alargado por la
// luz rasante, en celdas de 1/16 m. UV.x a lo ancho del ventanal, UV.y desde la pared hacia dentro.
// `k` es el destello (0..1).
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform float k = 0.0;
uniform vec3 tint : source_color = vec3(0.55, 0.62, 0.8);
uniform float cells = 16.0;                   // celdas por metro
uniform vec2 size = vec2(3.0, 7.0);           // m

void fragment() {
	vec2 uv = (floor(UV * size * cells) + 0.5) / (size * cells);
	float x = uv.x * 2.0 - 1.0;
	float y = uv.y;
	// arco al fondo (lejos de la pared, porque la luz baja)
	float arch = 1.0 - smoothstep(0.0, 0.02, length(vec2(x, max(y - 0.72, 0.0) * 2.4)) - 0.92);
	float inside = step(abs(x), 0.92) * step(0.04, y) * arch;
	float mull = step(abs(x), 0.06) + step(abs(abs(x) - 0.46), 0.04);   // parteluces
	float bar = step(abs(fract(y * 4.0) - 0.5), 0.05);                 // travesaños
	float pane = inside * (1.0 - clamp(mull + bar, 0.0, 1.0));
	float fade = smoothstep(0.0, 0.15, y) * (1.0 - smoothstep(0.85, 1.0, y));
	ALBEDO = tint * pane * fade * k * 0.9;
}
