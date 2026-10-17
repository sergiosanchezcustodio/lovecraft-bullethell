// Agua que corre por la cubierta del Emma tras cada ola (ambiente, 17-10-2026): una lámina
// fina que cruza las tablas hacia los imbornales de la borda (`flow`), con regueros que se
// separan y espuma en el frente, en celdas de 1/16 m. `k` (0..1) lo sube Ambient cuando rompe
// una ola y baja solo; `front` es por dónde va el frente del agua (m a lo largo de `flow`).
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform float k = 0.0;
uniform vec2 flow = vec2(0.45, 0.89);
uniform float front = 0.0;
uniform float cell = 0.0625;
uniform vec3 water : source_color = vec3(0.45, 0.55, 0.62);
uniform vec3 foam : source_color = vec3(0.85, 0.9, 0.92);

varying vec3 wp;

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float h21(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float vn(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1, 0)), f.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), f.x), f.y);
}

void fragment() {
	if (k <= 0.001) discard;
	vec2 c = (floor(wp.xz / cell) + 0.5) * cell;
	vec2 fl = normalize(flow);
	vec2 side = vec2(-fl.y, fl.x);
	float along = dot(c, fl);
	float across = dot(c, side);
	// regueros finos a lo largo del flujo que serpentean y corren hacia la borda
	float wig = (vn(vec2(along * 0.25, across * 0.2)) - 0.5) * 3.0;
	float lane = fract(across * 1.3 + wig);                          // carriles de ~0,8 m
	float thread = 1.0 - smoothstep(0.0, 0.06, abs(lane - 0.5));      // un hilo en medio de cada uno
	float pulse = vn(vec2(floor(across * 1.3 + wig) * 3.1, along * 0.5 - TIME * 3.0));
	float stream = thread * step(0.45, pulse);
	float sheet = 0.5 + 0.5 * vn(c * 2.5 - fl * TIME * 2.0);          // la lámina: brillo fino que corre
	// detrás del frente hay agua; el frente lleva espuma
	float behind = smoothstep(front + 0.6, front - 1.5, along) * smoothstep(front - 14.0, front - 6.0, along);
	float edge = (1.0 - smoothstep(0.0, 0.6, abs(along - front))) * step(0.55, h21(floor(c * 8.0) + floor(TIME * 6.0)));
	float a = (sheet * 0.14 + stream * 0.55) * behind + edge * 0.45;
	ALBEDO = mix(water, foam, clamp(stream * 0.6 + edge, 0.0, 1.0)) * 0.55;
	ALPHA = clamp(a * k, 0.0, 0.75);
}
