// Distorsiones de cordura baja (GDD 4.4): solo ambientación, nunca ocultan ni falsean las
// balas. Un borde violeta que palpita y, en solitario, algo de desaturación. En cooperativo,
// el borde sale de la esquina de cada jugador (la de su panel del HUD), según su cordura.
// `levels`: intensidad de cada jugador (0..1); `solo`: todo el borde y la desaturación.
// Hito 11.3 (28-10-2026): además, los bordes se oscurecen y los colores se separan (aberración
// cromática) hacia fuera, más cuanto más baja la cordura. El centro, donde se juega, no se toca.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform vec4 levels = vec4(0.0);
uniform bool solo = true;
uniform float strength = 1.0;           // la opción de la configuración (0..1)
uniform vec3 tint : source_color = vec3(0.35, 0.08, 0.45);

void fragment() {
	vec2 uv = SCREEN_UV;
	float pulse = 0.75 + 0.25 * sin(TIME * 3.1);
	float edge = 0.0;
	if (solo) {
		vec2 c = uv - 0.5;
		edge = smoothstep(0.32, 0.75, length(c * vec2(1.0, 0.8))) * levels.x;
	} else {
		vec2 corners[4] = vec2[](vec2(0.0, 0.0), vec2(1.0, 0.0), vec2(0.0, 1.0), vec2(1.0, 1.0));
		for (int i = 0; i < 4; i++) {
			float d = length((uv - corners[i]) * vec2(1.6, 1.0));
			edge = max(edge, smoothstep(0.55, 0.0, d) * levels[i]);
		}
	}
	// aberración: rojo hacia fuera y azul hacia dentro, solo donde hay borde (hasta 0,9 % de pantalla)
	vec2 out_dir = uv - 0.5;
	vec2 shift = out_dir * edge * strength * 0.018 * (0.85 + 0.15 * pulse);
	vec3 col = vec3(texture(screen_tex, uv + shift).r, texture(screen_tex, uv).g, texture(screen_tex, uv - shift).b);
	if (solo) {
		float grey = dot(col, vec3(0.299, 0.587, 0.114));
		col = mix(col, vec3(grey), levels.x * 0.4 * strength);   // hasta un 40 %: las balas se siguen viendo
	}
	col *= 1.0 - clamp(edge * 0.65 * strength, 0.0, 0.6);    // viñeta oscura
	col = mix(col, tint, clamp(edge * pulse * 0.55 * strength, 0.0, 0.55));
	COLOR = vec4(col, 1.0);
}
