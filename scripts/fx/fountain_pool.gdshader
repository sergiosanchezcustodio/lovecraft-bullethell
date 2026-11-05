// Agua del pilón de la fuente (hito 17.15): una lámina transparente sobre el agua pintada del
// modelo, con ondas que salen de donde cae el chorro y se apagan hacia el borde, un rizo lento
// por toda la superficie y destellos de luna. Recortada a un octógono (el del pilón); lo que
// asoma por encima (las rocas, la sirena) la tapa solo con la profundidad.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform float radius = 3.2;                 // m, apotema del octógono
uniform vec2 center = vec2(0.0);            // donde cae el chorro (local)
uniform vec3 tint = vec3(0.50, 0.58, 0.50); // color de los brillos
uniform float strength = 1.0;

varying vec2 lp;

void vertex() {
	lp = VERTEX.xz;
}

float hash(vec2 p) {                        // barato y sin sin() de argumentos grandes
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec2 q = (floor(lp * 32.0) + 0.5) / 32.0;   // a voxels, como el resto
	vec2 a = abs(q);
	float oct = max(max(a.x, a.y), (a.x + a.y) * 0.7071);
	if (oct > radius) discard;
	float edge = 1.0 - smoothstep(radius - 0.25, radius, oct);
	// ondas desde el chorro
	float d = length(q - center);
	float w = sin(d * 12.0 - TIME * 3.6);
	float rings = step(0.78, w) * exp(-d * 0.75);
	// rizo lento de toda la lámina (dos ondas cruzadas)
	float rip = sin(q.x * 3.1 + TIME * 0.7) * sin(q.y * 2.7 - TIME * 0.55);
	float ripple = step(0.9, rip) * 0.14;
	// destellos: celdas de 12 cm que se encienden de una en una
	vec2 cell = floor(q * 8.0);
	float h = hash(cell);
	float tw = fract(TIME * (0.15 + 0.25 * h) + h * 7.0);
	float glint = step(0.93, h) * smoothstep(0.0, 0.1, tw) * (1.0 - smoothstep(0.1, 0.35, tw));
	float k = (rings * 0.6 + ripple + glint * 0.6) * edge * strength;
	ALBEDO = tint * (1.0 + glint * 0.6);
	ALPHA = clamp(k, 0.0, 0.7);
}
