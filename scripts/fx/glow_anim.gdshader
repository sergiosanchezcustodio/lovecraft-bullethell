// Brillo animado de las capas de luz (ambiente de los escenarios, 16-10-2026): 1 late despacio
// (cristales, corales, la puerta de R'lyeh), 2 tiembla como una llama (faroles, antorchas,
// hogueras), 3 es una bombilla que falla de vez en cuando (estudio) y 4 late como un corazón, todas
// a la vez (R'lyeh, hito 12.12: `beat` lo pone Ambient). La luz real de la pieza
// sigue la misma cuenta (Ambient.anim_k), con la semilla de su posición.
shader_type spatial;
render_mode unshaded;

uniform bool colors_srgb = true;
uniform int mode = 1;
uniform float amount = 0.2;
uniform float speed = 1.0;
uniform float beat = 0.0;                     // modo 4: el latido ahora (0..1)

varying float k;

global uniform vec4 gust_a;                   // ráfagas (Gusts, hito 11.4): las llamas se agitan y casi se apagan
global uniform vec4 gust_b;

float gutter(vec4 g, vec2 at) {
	if (g.z <= 0.0) return 0.0;
	return g.z * (1.0 - smoothstep(g.w * 0.25, g.w, length(at - g.xy)));
}

float h1(float x) { return fract(sin(x * 12.9898) * 43758.5453); }

float anim_k(float t, float s) {
	if (mode == 1) return 1.0 + amount * sin(t * speed * 1.3 + s);
	if (mode == 4) return 1.0 + amount * (beat * 2.0 - 0.35);
	if (mode == 2) return 1.0 + amount * (0.55 * sin(t * 7.3 * speed + s) * sin(t * 3.1 * speed + s * 1.7) + 0.45 * sin(t * 13.7 * speed + s * 2.3));
	float u = t / 6.5 + s * 0.13;
	float slot = floor(u);
	if (h1(slot + s) > 0.8) {
		float w = (u - slot) * 6.5;
		if (w < 0.7) return mix(0.12, 1.0, step(0.45, h1(floor(w * 18.0) + slot * 3.0 + s)));
	}
	return 1.0 - amount * 0.1 * sin(t * 50.0);
}

void vertex() {
	if (colors_srgb) {
		COLOR.rgb = mix(pow((COLOR.rgb + vec3(0.055)) * (1.0 / 1.055), vec3(2.4)), COLOR.rgb * (1.0 / 12.92), lessThan(COLOR.rgb, vec3(0.04045)));
	}
	float s = fract(dot(NODE_POSITION_WORLD.xz, vec2(0.173, 0.311))) * 100.0;
	k = anim_k(TIME, s);
	if (mode == 2) {                              // llama: la misma cuenta que Gusts.gutter_k
		float gu = clamp((gutter(gust_a, NODE_POSITION_WORLD.xz) + gutter(gust_b, NODE_POSITION_WORLD.xz)) / 0.15, 0.0, 1.0);
		k *= 1.0 - gu * (0.45 + 0.25 * sin(TIME * 41.0 + s));
	}
}

void fragment() {
	ALBEDO = COLOR.rgb * k;
}
