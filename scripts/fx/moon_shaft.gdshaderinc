// Haces de luna (hito 16.32, MoonShafts): el haz es el conjunto de puntos p = W0 + a·U + b·V + t·D,
// con (a, b) en la abertura (0..1) y t >= 0 hasta el suelo (y = 0). shaft_to_local pasa del mundo a
// (a, b, t); shaft_floor = (W0.y, U.y, V.y, -D.y): el punto está sobre el suelo si
// x + y·a + z·b - w·t >= 0. La forma de la abertura (shaft_mask) es la misma que dibuja el foco en
// el suelo (MoonShafts.mask, en GDScript): si cambias una, cambia la otra.
uniform mat4 shaft_to_local;
uniform vec4 shaft_floor = vec4(1.0, 0.0, 0.0, 1.0);
uniform int shaft_shape = 0;                     // 0: ventanal con arco; 1: grieta
uniform bool shaft_frame = true;                 // ventanal con parteluz y travesaños
uniform float shaft_seed = 0.0;

float shaft_hash(vec2 p) {                       // el de night_sky, sin senos
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float shaft_mask(vec2 ab) {
	if (shaft_shape == 0) {                      // el ventanal del estudio, en voxels (32 de ancho)
		float u = ab.x * 32.0;
		float y = 22.0 + ab.y * 82.0;
		bool inside = y < 88.0 || (u - 16.0) * (u - 16.0) + (y - 88.0) * (y - 88.0) <= 256.0;
		if (!inside) return 0.0;
		if (shaft_frame && (u < 2.0 || (u >= 15.0 && u < 17.0) || u >= 30.0 || mod(y - 22.0, 20.0) < 2.0)) return 0.0;
		return 1.0;
	}
	vec2 p = ab * 2.0 - 1.0;                     // grieta: borde irregular y blando
	float ang = atan(p.y, p.x);
	float s = shaft_seed;
	float rr = 0.78 + 0.10 * sin(3.0 * ang + s) + 0.07 * sin(5.0 * ang + 2.0 * s) + 0.04 * sin(9.0 * ang + 3.0 * s);
	return 1.0 - smoothstep(rr - 0.16, rr, length(p));
}

// coordenadas (a, b, t) de un punto del mundo y si está dentro del haz
vec3 shaft_local(vec3 w) { return (shaft_to_local * vec4(w, 1.0)).xyz; }
float shaft_inside(vec3 l) {
	if (l.x < 0.0 || l.x > 1.0 || l.y < 0.0 || l.y > 1.0 || l.z < 0.0) return 0.0;
	if (shaft_floor.x + shaft_floor.y * l.x + shaft_floor.z * l.y - shaft_floor.w * l.z < 0.0) return 0.0;
	return shaft_mask(l.xy);
}
