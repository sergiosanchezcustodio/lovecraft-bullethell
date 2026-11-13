// Mancha de tinta (hito 20.1): al salir de la partida la tinta se extiende desde `origin` con el
// borde deshilachado del papel, unos goterones que se le unen y un velo azulado por delante; al
// entrar (`reveal`) se abre un claro desde el centro y la tinta se retira hacia los bordes.
// `amount` 0: nada de tinta; 1: todo cubierto del negro de LevelCard.BLACK.
shader_type canvas_item;

uniform float amount : hint_range(0.0, 1.0) = 0.0;
uniform bool reveal = false;
uniform float seed = 0.0;
uniform vec2 origin = vec2(0.5, 0.5);
uniform vec2 aspect = vec2(1.7778, 1.0);
uniform vec3 ink : source_color = vec3(0.01, 0.01, 0.015);
uniform vec3 rim : source_color = vec3(0.05, 0.06, 0.13);   // la tinta recién corrida, algo azul

// hash sin senos (el de night_sky.gdshaderinc)
float ink_hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = ink_hash(i);
	float b = ink_hash(i + vec2(1.0, 0.0));
	float c = ink_hash(i + vec2(0.0, 1.0));
	float d = ink_hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float s = 0.0;
	float w = 0.5;
	for (int i = 0; i < 4; i++) {
		s += vnoise(p) * w;
		p = p * 2.03 + vec2(17.1, 9.3);
		w *= 0.5;
	}
	return s;
}

float smin(float a, float b, float k) {
	float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
	return mix(b, a, h) - k * h * (1.0 - h);
}

// «Distancia» de cada punto a la mancha: 0 en el centro; la tinta llega donde es menor que el radio.
float field(vec2 uv) {
	vec2 p = (uv - origin) * aspect;
	float d = length(p);
	vec2 dir = p / max(d, 1e-4);
	vec2 o = vec2(seed * 7.13, seed * 3.71);
	float bulge = fbm(dir * 1.6 + o);                          // la forma grande, irregular
	float tendril = pow(vnoise(dir * 11.0 + o * 2.0), 5.0);   // hilos que se adelantan por las fibras
	float fiber = fbm(p * 11.0 + o);                           // el borde fino, deshilachado
	float f = d * (1.15 - 0.45 * bulge - 0.35 * tendril - 0.12 * fiber);
	for (int k = 0; k < 4; k++) {                              // goterones que caen y se unen
		vec2 c = (vec2(ink_hash(o + vec2(float(k), 1.0)), ink_hash(o + vec2(2.0, float(k)))) - 0.5) * aspect * 0.8;
		float r = length(p - c) * 2.4 * (1.0 - 0.2 * fiber) + 0.25 + 0.15 * float(k);
		f = smin(f, r, 0.08);
	}
	return f;
}

void fragment() {
	float f = field(UV);
	float a;
	float depth;                                               // cuánto se adentra en la tinta
	if (reveal) {
		float r = mix(-0.05, 0.98, 1.0 - amount);
		a = smoothstep(r - 0.01, r + 0.01, f);
		depth = f - r;
	} else {
		float r = mix(-0.05, 0.98, amount);
		a = 1.0 - smoothstep(r - 0.01, r + 0.01, f);
		depth = r - f;
		a = max(a, (1.0 - smoothstep(r, r + 0.05, f)) * 0.3);   // el velo que corre por delante
	}
	vec3 col = mix(rim, ink, smoothstep(0.0, 0.09, depth));
	if (amount >= 0.999) { col = ink; a = 1.0; }
	if (amount <= 0.001) a = 0.0;
	COLOR = vec4(col, a);
}
