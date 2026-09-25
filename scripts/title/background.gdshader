// Fondo de la portada: la ilustración con las velas vivas.
// Cada llama parpadea con su propia fase (mascara_luces.G) y su luz proyectada
// (mascara_luces.B) oscila con ella. La forma de la llama baila un poco (desplazamiento
// del muestreo solo donde hay llama, mascara_luces.R).
shader_type canvas_item;

uniform sampler2D luces : filter_linear;
uniform bool candles_enabled = true;
uniform float flicker_strength = 0.22;
uniform float flicker_speed = 1.0;
uniform float flame_wobble = 0.0009;
uniform float spill_strength = 0.045;

// Parpadeo de vela en [-1, 1]: casi estable, con oscilaciones rápidas pequeñas y, de vez
// en cuando, una bajada breve.
float flicker(float ph, float t) {
	float f = (sin(t * 7.3 + ph * 6.28) * 0.5 + sin(t * 13.9 + ph * 21.0) * 0.3 + sin(t * 29.1 + ph * 47.0) * 0.2) * 0.7;
	float dip = smoothstep(0.94, 1.0, sin(t * 1.7 + ph * 13.0)) * -0.6;
	return clamp(f + dip, -1.0, 1.0);
}

void fragment() {
	vec4 m = texture(luces, UV);
	vec2 uv = UV;
	float t = TIME * flicker_speed;
	if (candles_enabled) {
		float near_flame = smoothstep(0.02, 0.35, m.r);
		vec2 off = vec2(sin(t * 9.0 + m.g * 50.0), 0.6 + 0.4 * sin(t * 6.3 + m.g * 31.0)) * flame_wobble * near_flame;
		uv -= off * vec2(1.0, 1.8);                                         // la llama se estira hacia arriba
	}
	vec4 c = texture(TEXTURE, uv);
	if (candles_enabled) {
		float f = flicker(m.g, t);
		c.rgb *= 1.0 + f * (flicker_strength * m.r + spill_strength * m.b);
	}
	COLOR = c;
}
