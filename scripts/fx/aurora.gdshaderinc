// Aurora austral reflejada (ambiente, 17-10-2026): la cámara isométrica nunca enseña el cielo,
// así que las cortinas verdes y violetas se ven en el agua y en las placas de hielo. Bandas
// largas que ondulan despacio, con estrías verticales (los rayos de la cortina) que corren a lo
// largo; el borde de abajo verde y el de arriba violeta. `aurora` la pone Ambient (0: ninguna).
uniform float aurora = 0.0;

vec3 aurora_at(vec2 p, float t) {
	if (aurora <= 0.0) return vec3(0.0);
	vec2 q = p * 0.1;
	float wave = sin(q.x * 1.7 + t * 0.05 + sin(q.y * 1.3 + t * 0.04) * 1.6) * 0.9
		+ sin(q.x * 0.55 - t * 0.03) * 1.2;
	float d = (q.y + q.x * 0.35) * 2.2 + wave;                 // a través de la cortina
	float s = sin(d * 1.4);
	float band = pow(max(s, 0.0), 7.0);
	float across = fract(d * 1.4 / 6.2831853 + 0.25);          // 0 abajo .. 1 arriba en cada banda
	float rays = 0.2 + 0.8 * pow(0.5 + 0.5 * sin(q.x * 38.0 + t * 0.7 + sin(q.x * 9.0 + t * 0.2) * 3.0), 2.0);
	float breathe = 0.6 + 0.4 * sin(t * 0.21 + q.x * 2.0) * sin(t * 0.13 + q.y * 1.7);
	vec3 col = mix(vec3(0.08, 0.8, 0.38), vec3(0.42, 0.16, 0.62), smoothstep(0.45, 0.8, across));
	return col * band * rays * breathe * aurora;
}
