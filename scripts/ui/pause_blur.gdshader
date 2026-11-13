// Desenfoque de la partida detrás de la pausa (hito 20.10): la pantalla de debajo, leída de sus
// mipmaps (barato: un nivel borroso mezclado con el siguiente) y un poco oscurecida y fría.
// `amount` 0..1 entra con la ventana.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float amount : hint_range(0.0, 1.0) = 0.0;
uniform float lod = 1.9;

void fragment() {
	float l = lod * amount;
	vec3 a = textureLod(screen_tex, SCREEN_UV, l).rgb;
	vec3 b = textureLod(screen_tex, SCREEN_UV + vec2(0.0015, 0.001) * amount, l + 0.6).rgb;
	vec3 c = mix(a, b, 0.5);
	c = mix(c, c * vec3(0.85, 0.88, 0.95), amount * 0.6);
	COLOR = vec4(c, amount);
}
