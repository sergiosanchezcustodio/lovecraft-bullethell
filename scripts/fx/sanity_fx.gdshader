// Distorsiones de cordura baja (GDD 4.4): solo ambientación, nunca ocultan ni falsean las
// balas. Un borde violeta que palpita y, en solitario, algo de desaturación. En cooperativo,
// el borde sale de la esquina de cada jugador (la de su panel del HUD), según su cordura.
// `levels`: intensidad de cada jugador (0..1); `solo`: todo el borde y la desaturación.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform vec4 levels = vec4(0.0);
uniform bool solo = true;
uniform float strength = 1.0;           // la opción de la configuración (0..1)
uniform vec3 tint : source_color = vec3(0.35, 0.08, 0.45);

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 col = texture(screen_tex, uv).rgb;
	float pulse = 0.75 + 0.25 * sin(TIME * 3.1);
	float edge = 0.0;
	if (solo) {
		vec2 c = uv - 0.5;
		float v = smoothstep(0.32, 0.75, length(c * vec2(1.0, 0.8)));
		edge = v * levels.x;
		float grey = dot(col, vec3(0.299, 0.587, 0.114));
		col = mix(col, vec3(grey), levels.x * 0.4 * strength);   // hasta un 40 %: las balas se siguen viendo
	} else {
		vec2 corners[4] = vec2[](vec2(0.0, 0.0), vec2(1.0, 0.0), vec2(0.0, 1.0), vec2(1.0, 1.0));
		for (int i = 0; i < 4; i++) {
			float d = length((uv - corners[i]) * vec2(1.6, 1.0));
			edge = max(edge, smoothstep(0.55, 0.0, d) * levels[i]);
		}
	}
	col = mix(col, tint, clamp(edge * pulse * 0.55 * strength, 0.0, 0.55));
	COLOR = vec4(col, 1.0);
}
