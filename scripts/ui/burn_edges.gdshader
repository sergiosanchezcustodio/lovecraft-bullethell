// Página quemada (hito 20.4): al caer, los bordes de la pantalla se queman hacia dentro: carbón
// en el borde, un frente de brasa irregular que avanza y se para, y el papel tostado por delante.
// `t` 0..1: avance del fuego (a 1 se queda quieto); `pulse`: cuánto respiran las brasas (0 con
// «Destellos reducidos»).
shader_type canvas_item;

uniform float t : hint_range(0.0, 1.0) = 0.0;
uniform float time_s = 0.0;
uniform float pulse = 1.0;
uniform float seed = 0.0;
uniform vec2 aspect = vec2(1.7778, 1.0);
uniform float reach = 0.085;                                 // hasta dónde llega el fuego (alto = 1)

float b_hash(vec2 p) {                                       // el hash de night_sky.gdshaderinc
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float b_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(b_hash(i), b_hash(i + vec2(1, 0)), f.x), mix(b_hash(i + vec2(0, 1)), b_hash(i + vec2(1, 1)), f.x), f.y);
}

float b_fbm(vec2 p) {
	float s = 0.0;
	float w = 0.5;
	for (int i = 0; i < 4; i++) { s += b_noise(p) * w; p = p * 2.1 + 13.7; w *= 0.5; }
	return s;
}

void fragment() {
	vec2 p = UV * aspect;
	float e = min(min(p.x, aspect.x - p.x), min(p.y, aspect.y - p.y));   // distancia al borde
	float n = b_fbm(p * 5.0 + seed);
	float front = reach * t * (0.35 + 1.3 * n);                 // el borde quemado, irregular
	float x = e - front;                                        // <0: ya quemado
	float glow_k = (1.0 + pulse * 0.35 * (b_noise(p * 14.0 + vec2(time_s * 1.5, seed)) - 0.5))
		* mix(1.0, 0.3, smoothstep(0.8, 3.0, time_s));            // al pararse, las brasas se apagan
	vec3 col;
	float a;
	if (x < 0.0) {                                              // carbón: casi negro, con vetas
		col = mix(vec3(0.02, 0.012, 0.008), vec3(0.08, 0.04, 0.02), b_noise(p * 40.0 + seed) * smoothstep(-0.03, 0.0, x));
		a = 1.0;
		float cinder = smoothstep(-0.012, 0.0, x);              // brasa justo detrás del frente
		col += vec3(1.0, 0.35, 0.06) * cinder * 0.9 * glow_k;
	} else {
		float ember = exp(-x / 0.004) * step(0.001, t);         // el frente que arde
		float scorch = exp(-x / 0.035) * step(0.001, t);         // el papel tostado
		col = mix(vec3(0.25, 0.12, 0.04), vec3(1.0, 0.55, 0.15), ember * glow_k);
		a = max(scorch * 0.55, ember);
	}
	if (t <= 0.001) a = 0.0;
	COLOR = vec4(col, a);
}
