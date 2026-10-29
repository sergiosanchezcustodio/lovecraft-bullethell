shader_type canvas_item;
// Ventisca que se cierra (hito 12.13): un velo de nieve sobre la pantalla, despejado alrededor de
// cada jugador y cada vez más espeso lejos de ellos. Corre con el viento en jirones. Lo pone
// Ambient (arena "changes": "blizzard"), por debajo del HUD.

#include "res://scripts/fx/night_sky.gdshaderinc"

uniform vec4 players[4];                       // xy: posición en la pantalla (0..1); z: 1 si cuenta
uniform float clear = 0.3;                     // radio despejado, en altos de pantalla
uniform float strength = 0.0;                  // 0..1: cuánto tapa en lo más espeso
uniform vec2 wind = vec2(0.06, 0.02);          // pantallas por segundo
uniform vec4 tint : source_color = vec4(0.78, 0.84, 0.92, 1.0);
uniform float aspect = 1.7778;

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(sky_hash(i), sky_hash(i + vec2(1, 0)), f.x), mix(sky_hash(i + vec2(0, 1)), sky_hash(i + vec2(1, 1)), f.x), f.y);
}

float fbm2(vec2 p) {
	return vnoise(p) * 0.55 + vnoise(p * 2.1 + 7.0) * 0.3 + vnoise(p * 4.3 + 3.0) * 0.15;
}

void fragment() {
	if (strength <= 0.0) discard;
	vec2 uv = SCREEN_UV;
	float d = 10.0;
	for (int i = 0; i < 4; i++) {
		if (players[i].z > 0.5) d = min(d, length((uv - players[i].xy) * vec2(aspect, 1.0)));
	}
	vec2 q = vec2(uv.x * aspect, uv.y);
	float gust = fbm2(q * 3.0 - wind * TIME * vec2(aspect, 1.0) * 3.0);            // jirones que corren
	float fine = fbm2(q * 9.0 - wind * TIME * vec2(aspect, 1.0) * 7.0);
	float edge = clear * (0.85 + gust * 0.35);
	float k = smoothstep(edge, edge + 0.35, d);
	float a = strength * k * (0.6 + 0.4 * gust) * (0.85 + 0.15 * fine);
	COLOR = vec4(tint.rgb * (0.9 + 0.15 * fine), a);
}
