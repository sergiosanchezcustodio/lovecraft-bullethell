shader_type canvas_item;
// Retrato del HUD con estado (hito 12.14): encima de la cabeza (el SubViewport del retrato, con
// el fondo transparente), sangre con poca vida, la mirada perdida con poca cordura y escarcha en
// la Antártida. Todo se ciñe a la silueta de la cabeza (el alfa de la textura).
#include "res://scripts/fx/night_sky.gdshaderinc"

uniform float blood : hint_range(0.0, 1.0) = 0.0;     // 0: entero; 1: abatido
uniform float lost : hint_range(0.0, 1.0) = 0.0;      // 0: cuerdo; 1: crisis
uniform float frost : hint_range(0.0, 1.0) = 0.0;     // 0: sin frío; 1: escarcha
uniform float seed = 0.0;                             // cada jugador, sus manchas

float vn(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(sky_hash(i), sky_hash(i + vec2(1.0, 0.0)), f.x),
		mix(sky_hash(i + vec2(0.0, 1.0)), sky_hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

// Cuánto de dentro está un punto de la silueta: 0 en el borde, 1 a 4 px o más.
float inside(sampler2D tex, vec2 uv, vec2 px) {
	float m = 1.0;
	for (int i = 0; i < 8; i++) {
		float a = float(i) * 0.785398;
		m = min(m, texture(tex, uv + vec2(cos(a), sin(a)) * px * 4.0).a);
	}
	return m;
}

void fragment() {
	vec2 uv = UV;
	float t = TIME;
	// mirada perdida: la cara se mece despacio y se desdobla, sin color y algo violeta
	if (lost > 0.0) uv += lost * 0.012 * vec2(sin(UV.y * 9.0 + t * 1.3), cos(UV.x * 7.0 + t * 1.1));
	vec4 c = texture(TEXTURE, uv);
	if (lost > 0.0) {
		vec2 off = vec2(0.04 * sin(t * 0.7), 0.012 * cos(t * 0.53)) * lost;
		vec4 g = texture(TEXTURE, uv + off);
		float lum = dot(c.rgb, vec3(0.3, 0.59, 0.11));
		c.rgb = mix(c.rgb, vec3(lum) * vec3(0.86, 0.82, 1.0), lost * 0.7);
		c.rgb = mix(c.rgb, g.rgb * vec3(0.65, 0.55, 1.0), 0.32 * lost * g.a);
		c.a = max(c.a, g.a * 0.35 * lost);
	}
	float edge = 1.0 - inside(TEXTURE, UV, TEXTURE_PIXEL_SIZE);
	// escarcha: entra desde el borde de la silueta y desde arriba, con cristales que brillan
	if (frost > 0.0 && c.a > 0.0) {
		float n = vn(UV * 22.0 + seed) * 0.6 + vn(UV * 55.0 - seed) * 0.4;
		float ice = smoothstep(0.42, 0.8, edge * 0.9 + n * 0.55 + (0.45 - UV.y) * 0.5);
		float spark = step(0.8, vn(UV * 80.0 + seed * 2.0)) * (0.6 + 0.4 * sin(t * 2.3 + UV.x * 40.0));
		c.rgb = mix(c.rgb, c.rgb * vec3(0.8, 0.9, 1.1), frost * 0.5);          // todo, algo más frío
		c.rgb = mix(c.rgb, vec3(0.82, 0.92, 1.0), ice * frost * 0.8) + vec3(0.6, 0.8, 1.0) * spark * ice * frost * 0.6;
	}
	// sangre: manchas que crecen al bajar la vida, con chorretones hacia abajo
	if (blood > 0.0 && c.a > 0.0) {
		float b = vn(UV * 8.0 + seed * 3.1) * 0.65 + vn(UV * 21.0 + seed) * 0.35;
		float col = vn(vec2(UV.x * 26.0, seed * 7.0));
		float drip = smoothstep(0.62, 0.8, col) * smoothstep(0.2, 0.75, UV.y) * blood;
		float th = 1.0 - blood * 0.5;
		float m = smoothstep(th, th + 0.04, b + drip * 0.35 + edge * 0.08);
		vec3 red = vec3(0.45, 0.03, 0.02) * (0.65 + 0.35 * vn(UV * 60.0 + seed));
		c.rgb = mix(c.rgb, red, m * 0.88);
	}
	COLOR = c;
}
