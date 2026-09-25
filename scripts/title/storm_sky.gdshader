// Cielo de tormenta de la portada: degradado frío, capas de nubes que se desplazan
// despacio y se iluminan desde dentro con cada relámpago (flash, flash_dir).
shader_type sky;

uniform vec3 top_color : source_color = vec3(0.015, 0.025, 0.04);
uniform vec3 horizon_color : source_color = vec3(0.16, 0.20, 0.26);   // claro: las crestas se recortan
uniform vec3 cloud_dark : source_color = vec3(0.02, 0.03, 0.045);
uniform vec3 cloud_light : source_color = vec3(0.17, 0.20, 0.25);
uniform vec3 moon_dir = vec3(-0.35, 0.45, -0.82);
uniform float flash = 0.0;                      // 0..1, lo anima el script de la portada
uniform vec3 flash_dir = vec3(0.2, 0.25, -1.0); // hacia dónde cae el rayo
uniform vec3 flash_color : source_color = vec3(0.62, 0.72, 1.0);

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) {
	float v = 0.0; float a = 0.5;
	for (int i = 0; i < 5; i++) { v += a * noise(p); p *= 2.03; a *= 0.5; }
	return v;
}

void sky() {
	vec3 d = normalize(EYEDIR);
	float h = d.y;
	vec3 col = mix(horizon_color, top_color, smoothstep(-0.02, 0.55, h));
	// Nubes proyectadas sobre un plano alto; más densas hacia el horizonte del fondo
	vec2 uv = d.xz / max(h + 0.12, 0.04);
	float t = TIME;
	float n = fbm(uv * 0.55 + vec2(t * 0.006, t * 0.0025));
	float n2 = fbm(uv * 1.3 - vec2(t * 0.010, -t * 0.004));
	float cover = smoothstep(0.38, 0.72, n * 0.7 + n2 * 0.4);
	vec3 cloud = mix(cloud_dark, cloud_light, smoothstep(0.3, 0.9, n2));
	float above = smoothstep(-0.04, 0.10, h);
	col = mix(col, cloud, cover * above);
	// Luna velada tras las nubes
	float m = max(dot(d, normalize(moon_dir)), 0.0);
	col += vec3(0.55, 0.62, 0.72) * (pow(m, 900.0) * 1.2 + pow(m, 40.0) * 0.06) * (1.0 - cover * 0.8);
	// Relámpago: ilumina las nubes cercanas a la dirección del rayo desde dentro
	float fd = max(dot(d, normalize(flash_dir)), 0.0);
	float lit = flash * (pow(fd, 7.0) * (0.5 + cover * 1.6) + 0.08 * cover);
	col += flash_color * lit * above;
	COLOR = col;
}
