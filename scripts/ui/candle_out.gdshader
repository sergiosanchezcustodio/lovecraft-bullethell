// La vela se apaga (hito 20.3): la pantalla se oscurece hacia una llama en `flame` (en UV) hasta
// que solo queda su luz cálida; la llama tiembla, se encoge y se apaga, y sube un hilo de humo
// que se deshace. `t` 0: nada; 1: todo negro.
shader_type canvas_item;

uniform float t : hint_range(0.0, 1.0) = 0.0;
uniform vec2 flame = vec2(0.5, 0.62);
uniform vec2 aspect = vec2(1.7778, 1.0);
uniform float time_s = 0.0;
uniform vec3 black : source_color = vec3(0.01, 0.01, 0.015);
uniform vec3 warm : source_color = vec3(1.0, 0.62, 0.25);

float c_hash(vec2 p) {                                        // el hash de night_sky.gdshaderinc
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float c_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(c_hash(i), c_hash(i + vec2(1, 0)), f.x), mix(c_hash(i + vec2(0, 1)), c_hash(i + vec2(1, 1)), f.x), f.y);
}

void fragment() {
	vec2 p = (UV - flame) * aspect;
	float d = length(p);
	float close = smoothstep(0.0, 0.7, t);                     // la oscuridad que se cierra
	float lit = smoothstep(0.62, 0.9, t);                      // la llama se va
	float flick = 0.85 + 0.15 * c_noise(vec2(time_s * 9.0, 0.0));
	float radius = mix(1.3, 0.16, close) * flick * (1.0 - lit);
	float dark = smoothstep(radius * 0.35, radius, d);
	vec3 col = black;
	float a = mix(0.0, 1.0, max(dark * close, lit));
	// el halo cálido de la llama, mientras quede
	float halo = exp(-d * d / max(radius * radius * 0.25, 1e-4)) * close * (1.0 - lit);
	col = mix(col, warm * 0.35, halo * 0.6);
	a = max(a, halo * 0.6 * close);
	// la llama: una gota que tiembla y se encoge
	float h = mix(0.05, 0.0, lit) * flick;
	vec2 q = p - vec2(0.0, -h * 0.55);
	q.x += sin(time_s * 13.0 + q.y * 40.0) * 0.004 * (1.0 - lit);
	float drop = length(vec2(q.x / max(h * 0.32, 1e-4), q.y / max(h * 0.6, 1e-4) + (q.y < 0.0 ? 0.0 : 0.0)));
	float fl = (1.0 - smoothstep(0.6, 1.0, drop)) * step(0.001, h) * smoothstep(0.1, 0.45, t);   // entra poco a poco
	vec3 flame_col = mix(vec3(1.0, 0.95, 0.75), warm, smoothstep(0.0, 1.0, drop));
	col = mix(col, flame_col, fl);
	a = max(a, fl);
	// el humo: un hilo que sube con un vaivén y se deshace
	float smoke_t = smoothstep(0.66, 0.85, t) * (1.0 - smoothstep(0.9, 1.0, t));
	float up = -p.y;
	float sway = sin(up * 18.0 - time_s * 3.0) * 0.012 * up * 4.0 + (c_noise(vec2(up * 6.0, time_s)) - 0.5) * 0.02 * up * 4.0;
	float line = exp(-pow((p.x - sway) / (0.005 + up * 0.06), 2.0)) * step(0.0, up) * exp(-up * 4.0);
	col = mix(col, vec3(0.3, 0.3, 0.32), line * smoke_t);
	if (t >= 0.999) { col = black; a = 1.0; }
	if (t <= 0.001) a = 0.0;
	COLOR = vec4(col, a);
}
