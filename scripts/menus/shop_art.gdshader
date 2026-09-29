// Ilustración de la tienda animada (hito 2.13d), como la portada: no se pinta nada encima,
// se modula la imagen con un mapa de máscaras (tools/gen_mascaras_tienda.py):
//   R llamas (quinqué y velas): titilan, cada una con su fase;
//   G brillos mágicos (bola de cristal, frascos): laten despacio;
//   B luz que proyectan las llamas: oscila con ellas, más suave;
//   A fase propia de cada llama o brillo.
shader_type canvas_item;

uniform sampler2D masks : filter_linear;
uniform float flame_amount = 0.24;       // cuánto varía el brillo de una llama
uniform float light_amount = 0.14;       // y el de la luz que proyecta
uniform float magic_amount = 0.30;       // cuánto late un brillo mágico

float flicker(float t, float ph) {
	// suma de senos a frecuencias sin relación sencilla: parece irregular, pero es suave
	return 0.55 * sin(t * 9.1 + ph * 40.0) + 0.3 * sin(t * 15.7 + ph * 17.0) + 0.15 * sin(t * 27.3 + ph * 5.0);
}

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	vec4 m = texture(masks, UV);
	float ph = m.a;
	float f = flicker(TIME, ph);
	float k = 1.0 + m.r * flame_amount * f + m.b * light_amount * f;
	k += m.g * magic_amount * sin(TIME * 1.6 + ph * 6.2831);
	COLOR = vec4(col.rgb * k, col.a);
}
