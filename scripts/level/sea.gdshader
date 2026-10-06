// Mar helado de la costa, en voxel fino a juego con el suelo (30-09-2026): celdas de `cell`
// m con la altura del agua en escalones que se mueven con tres trenes de olas y ruido lento.
// La altura decide el tono (de azul profundo a verde azulado) y la normal (relieve falso),
// así los reflejos del sol bajo corren por las crestas. Encima: rizos finos, placas de
// hielo menudo (brash) que derivan despacio, más oscuro lejos de la orilla y espuma que
// va y viene contra la plataforma.
shader_type spatial;
render_mode cull_disabled, shadows_disabled;

uniform vec3 deep : source_color = vec3(0.07, 0.17, 0.27);
uniform vec3 mid : source_color = vec3(0.14, 0.32, 0.44);
uniform vec3 shallow : source_color = vec3(0.26, 0.50, 0.60);
uniform vec3 crest : source_color = vec3(0.50, 0.68, 0.78);
uniform vec3 brash : source_color = vec3(0.78, 0.86, 0.92);
uniform float brash_amount = 1.0;            // hielo menudo (0: puerto sin hielo, hito 6.2)
uniform vec3 foam : source_color = vec3(0.80, 0.87, 0.93);
uniform float cell = 0.125;
uniform vec2 shore = vec2(32.0, 32.0);       // la orilla: x = shore.x (este) y z = shore.y (sur)
uniform vec2 drift = vec2(0.05, 0.03);       // deriva del hielo menudo (m/s)

varying vec3 wpos;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

// Altura del agua (0..1) en el punto p (m) y el instante t
float wave(vec2 p, float t) {
	float h = 0.5;
	h += 0.16 * sin(dot(p, vec2(0.55, 0.32)) - t * 1.1);          // mar de fondo
	h += 0.10 * sin(dot(p, vec2(-0.28, 0.71)) - t * 0.8);
	h += 0.07 * sin(dot(p, vec2(1.35, -0.9)) - t * 1.9);          // olas cortas
	h += 0.22 * (vnoise(p * 0.35 + vec2(t * 0.10, -t * 0.07)) - 0.5);
	h += 0.10 * (vnoise(p * 1.6 + vec2(-t * 0.35, t * 0.25)) - 0.5); // rizos
	return clamp(h, 0.0, 1.0);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float t = TIME;
	vec2 c = floor(wpos.xz / cell);
	vec2 p = (c + 0.5) * cell;
	// escalones de altura (como el suelo): 6 niveles
	float h = floor(wave(p, t) * 6.0) / 6.0;
	float hx = (floor(wave(p + vec2(cell, 0), t) * 6.0) / 6.0 - h) * 2.0;
	float hz = (floor(wave(p + vec2(0, cell), t) * 6.0) / 6.0 - h) * 2.0;
	vec3 n = normalize(vec3(-hx * 1.2, 1.0, -hz * 1.2));
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);

	// distancia a la orilla (en la esquina, a la esquina)
	float dist = length(max(p - shore, vec2(0.0)));
	if (p.x < shore.x) dist = p.y - shore.y;
	if (p.y < shore.y) dist = p.x - shore.x;
	float depth = smoothstep(1.0, 26.0, dist);

	// valles oscuros y crestas claras: el tono sigue a la ola
	vec3 lo = mix(mid * 0.8, deep, depth);
	vec3 hi = mix(shallow, mid * 1.5, depth);
	vec3 col = mix(lo, hi, smoothstep(0.3, 0.7, h));
	col = mix(col, crest, step(0.82, h) * 0.8);                     // crestas: una fila clara
	// rizos: textura fina que corre con el viento, en tres tonos
	float r = vnoise(vec2(p.x * 2.4 + p.y * 0.8, p.y * 2.4 - p.x * 0.8) + vec2(t * 0.6, t * 0.35));
	col *= r > 0.66 ? 1.16 : (r < 0.3 ? 0.86 : 1.0);
	col *= 0.96 + 0.06 * hash(c);                                  // grano por celda

	// hielo menudo: placas de 1-3 celdas que derivan
	vec2 q = (wpos.xz - drift * t) / (cell * 2.0);
	vec2 qc = floor(q);
	float b = step(0.97, hash(qc + 71.0));
	b *= step(0.72, vnoise(qc * 0.06 + 3.0)) * (1.0 - 0.6 * depth);   // a manchas, más junto a la costa
	b = step(0.5, b) * brash_amount;
	col = mix(col, brash * (0.92 + 0.1 * hash(qc)), b);

	// espuma contra la plataforma (asoma en los entrantes del frente)
	float band = 2.3 + 0.35 * sin(t * 0.9 + p.x * 0.4 + p.y * 0.4);
	float fo = step(dist, band) * step(0.62, vnoise(p * 3.0 + vec2(t * 0.4, -t * 0.3))) * step(0.5, hash(c + floor(t * 2.0)));
	col = mix(col, foam, fo * 0.6);

	float ice = max(b, fo);
	ALBEDO = col;
	ROUGHNESS = mix(0.3, 0.8, ice);
	SPECULAR = mix(0.35, 0.3, ice);
}
