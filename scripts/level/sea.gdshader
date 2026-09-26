// Mar helado de la costa (arena del campamento), a juego con el suelo en losas: el agua
// se reparte en baldosas de 0,5 m, cada una con su altura de ola animada, que decide su
// tono (de azul verdoso profundo a algo más claro) y, de vez en cuando, un destello de la
// luna. Junto a la orilla, una franja de espuma que va y viene.
// Más oscuro que la nieve a propósito: es fondo y no debe competir con las balas, pero
// con la luz de luna tiene que leerse como agua (más oscuro aún, se veía negro).
shader_type spatial;
render_mode cull_disabled, shadows_disabled;

uniform vec3 deep : source_color = vec3(0.13, 0.24, 0.30);
uniform vec3 shallow : source_color = vec3(0.24, 0.39, 0.45);
uniform vec3 glint : source_color = vec3(0.55, 0.68, 0.80);
uniform vec3 foam : source_color = vec3(0.62, 0.72, 0.80);
uniform float tile = 0.5;
uniform vec2 shore = vec2(32.0, 32.0);       // la orilla: x = shore.x (este) y z = shore.y (sur)

varying vec3 wpos;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 cell = floor(wpos.xz / tile);
	vec2 c = (cell + 0.5) * tile;
	float t = TIME;
	// oleaje: dos trenes de ondas largas y ruido lento, muestreados en el centro de la baldosa
	float h = 0.5 + 0.25 * sin(c.x * 0.35 + c.y * 0.22 - t * 0.9) + 0.18 * sin(c.x * -0.18 + c.y * 0.41 - t * 0.7)
		+ 0.3 * (vnoise(c * 0.25 + vec2(t * 0.08, -t * 0.05)) - 0.5);
	h = clamp(h, 0.0, 1.0);
	vec3 col = mix(deep, shallow, smoothstep(0.35, 0.95, h));
	// destellos de luna: pocas baldosas, en la cresta, parpadeando
	float g = step(0.965, hash(cell + floor(t * 1.5))) * smoothstep(0.7, 0.9, h);
	col = mix(col, glint, g * 0.55);
	// espuma junto a la orilla
	float dist = min(c.x - shore.x, c.y - shore.y);
	if (c.x < shore.x) dist = c.y - shore.y;
	if (c.y < shore.y) dist = c.x - shore.x;
	float band = 1.1 + 0.5 * sin(t * 0.8 + c.x * 0.3 + c.y * 0.3);
	float f = step(dist, band) * step(0.35, vnoise(c * 1.3 + t * 0.3));
	col = mix(col, foam, f * 0.5);
	ALBEDO = col;
	ROUGHNESS = 0.25;
	SPECULAR = 0.6;
}
