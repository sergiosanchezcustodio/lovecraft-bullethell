shader_type spatial;
// Escudo de icor de los grados de locura (hito 16.14): una burbuja que se ve en el borde y deja
// ver la criatura en el centro, con un brillo que corre de abajo arriba.
render_mode unshaded, blend_add, cull_back, depth_draw_never, shadows_disabled;

uniform vec3 color : source_color = vec3(0.45, 0.95, 0.55);

void fragment() {
	float rim = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float band = 0.5 + 0.5 * sin(UV.y * 18.0 - TIME * 3.0);
	ALBEDO = color;
	ALPHA = pow(rim, 2.2) * 0.75 + 0.03 + band * rim * 0.12;
}
