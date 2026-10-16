// Cielo de noche reflejado (ambiente de los escenarios, 16-10-2026). La cámara isométrica nunca
// enseña el cielo: las estrellas titilan en el agua, los charcos y los cristales, y de vez en
// cuando cruza una estrella fugaz (la lanza Ambient: punto de salida, recorrido y tiempo).
uniform float night = 0.0;                      // 0: de día; 1: noche despejada
uniform vec4 shoot = vec4(0.0);                 // xy: de dónde sale (m); zw: recorrido (m)
uniform float shoot_t = -1.0;                   // s desde que salió (<0: ninguna)

// hash sin senos (el de sin() dejaba las estrellas en hileras sobre la rejilla)
float sky_hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

// Estrella en la celda `cid` (si le toca): brillo que titila, de 0 a ~1,3
vec3 star_at(vec2 cid, float t, float density) {
	float h = sky_hash(cid + 17.3);
	if (h < 1.0 - density) return vec3(0.0);
	float r = fract(h * 97.13);
	float tw = 0.55 + 0.45 * sin(t * (1.3 + 3.5 * fract(h * 31.7)) + h * 50.0);
	tw *= tw * (0.7 + 0.3 * sin(t * 0.37 + r * 9.0));
	vec3 tint = mix(vec3(0.80, 0.86, 1.0), vec3(1.0, 0.92, 0.78), step(0.75, r));
	return tint * tw * (0.45 + 0.85 * r);
}

// Estrella fugaz en el punto p (m): cabeza brillante y estela que se apaga hacia atrás
vec3 shooting_star(vec2 p) {
	if (shoot_t < 0.0 || night <= 0.0) return vec3(0.0);
	float life = 1.1;
	float a = shoot_t / life;
	if (a > 1.0) return vec3(0.0);
	vec2 dir = normalize(shoot.zw);
	vec2 head = shoot.xy + shoot.zw * min(a * 1.15, 1.0);
	float tail = 3.4;
	vec2 d = p - head;
	float along = -dot(d, dir);                  // metros por detrás de la cabeza
	float side = abs(dot(d, vec2(-dir.y, dir.x)));
	if (along < -0.06 || along > tail) return vec3(0.0);
	float w = mix(0.035, 0.01, clamp(along / tail, 0.0, 1.0));
	float k = (1.0 - smoothstep(w * 0.5, w, side)) * pow(1.0 - clamp(along / tail, 0.0, 1.0), 1.6);
	k *= smoothstep(0.0, 0.1, a) * (1.0 - smoothstep(0.7, 1.0, a));
	return vec3(0.82, 0.9, 1.0) * k * 1.8;
}
