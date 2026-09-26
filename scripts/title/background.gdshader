// Fondo de la portada: la ilustración con las velas vivas y los farolillos que respiran.
// - Velas (mascara_velas): cada llama parpadea con su propia fase (G) y su luz proyectada
//   (mascara_luces.B) oscila con ella. Solo la llama baila (B): nada en la base, más en la
//   punta, así que la mecha y la cera no se mueven.
// - Farolillos (mascara_luces R y G): no se mueven; su cristal y su halo respiran despacio.
shader_type canvas_item;

uniform sampler2D velas : filter_linear;
uniform sampler2D luces : filter_linear;
uniform vec2 design = vec2(1920.0, 1080.0);
uniform bool candles_enabled = true;
uniform float flicker_strength = 0.22;
uniform float flicker_speed = 1.0;
uniform float flame_sway = 2.5;              // px (a 1080p) que se desplaza la punta de la llama mayor
uniform float spill_strength = 0.045;
uniform bool lanterns_enabled = true;
uniform float lantern_breath = 0.06;         // variación de brillo del cristal (±)
uniform float lantern_halo = 0.10;           // intensidad del halo
uniform float lantern_period = 5.0;          // s de una respiración
uniform vec3 lantern_color : source_color = vec3(1.0, 0.62, 0.28);

// Parpadeo de vela en [-1, 1]: casi estable, con oscilaciones rápidas pequeñas y, de vez
// en cuando, una bajada breve.
float flicker(float ph, float t) {
	float f = (sin(t * 7.3 + ph * 6.28) * 0.5 + sin(t * 13.9 + ph * 21.0) * 0.3 + sin(t * 29.1 + ph * 47.0) * 0.2) * 0.7;
	float dip = smoothstep(0.94, 1.0, sin(t * 1.7 + ph * 13.0)) * -0.6;
	return clamp(f + dip, -1.0, 1.0);
}

void fragment() {
	vec4 v = texture(velas, UV);
	vec4 l = texture(luces, UV);
	vec2 uv = UV;
	float t = TIME * flicker_speed;
	float ph = v.g * 255.0 / 7.0;
	if (candles_enabled && v.b > 0.001) {
		// vaivén lento de la punta y estirones hacia arriba
		float sx = sin(t * 2.1 + ph) * 0.55 + sin(t * 5.3 + ph * 2.7) * 0.3 + sin(t * 11.7 + ph * 5.1) * 0.15;
		float sy = 0.5 + 0.5 * (sin(t * 3.7 + ph * 1.9) * 0.6 + sin(t * 8.9 + ph * 3.3) * 0.4);
		uv += vec2(-sx, sy * 0.8) * v.b * flame_sway / design;
	}
	vec4 c = texture(TEXTURE, uv);
	if (candles_enabled) {
		float f = flicker(v.g, t);
		c.rgb *= 1.0 + f * (flicker_strength * v.r + spill_strength * l.b);
	}
	if (lanterns_enabled) {
		// fase suave según la posición: cada farolillo respira a su ritmo, sin saltos en el halo
		float lp = sin(TIME * 6.2832 / lantern_period + UV.x * 23.0 + UV.y * 11.0);
		float slow = 0.5 + 0.5 * lp;
		c.rgb *= 1.0 + lantern_breath * lp * l.r;
		c.rgb += lantern_color * l.g * l.g * lantern_halo * mix(0.55, 1.0, slow);
	}
	COLOR = c;
}
