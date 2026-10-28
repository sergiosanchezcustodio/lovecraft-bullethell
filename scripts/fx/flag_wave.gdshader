// Bandera que ondea al viento (revisión de arte, 13-10-2026). VoxelBuilder lo pone en la parte
// "flag" de un modelo: la malla está en coordenadas del pivote (el mástil), con la bandera hacia
// +X. Ondas que corren del mástil a la punta, más amplias cuanto más lejos del mástil, con rachas;
// la fase depende de la posición en el mundo para que dos banderas no vayan a la par.
shader_type spatial;

uniform bool colors_srgb = true;
uniform float roughness_v : hint_range(0.0, 1.0) = 0.9;
uniform float specular_v : hint_range(0.0, 1.0) = 0.25;
uniform float length_m = 1.3;        // largo de la bandera (m)
uniform float amplitude = 0.10;      // desplazamiento en la punta (m)
uniform float wavelength = 0.55;     // m
uniform float speed = 2.4;           // rad/s
global uniform vec4 gust_a;                   // ráfagas de explosiones y esquives (Gusts, hito 11.4):
global uniform vec4 gust_b;                   // x, z, fuerza (m) y radio

// Empuje de una ráfaga sobre la pieza que está en `at` (en el mundo): hacia fuera, con un
// temblor que se apaga con su fuerza.
vec3 gust_push(vec4 g, vec2 at, float t) {
	vec2 d = at - g.xy;
	float dist = length(d);
	float f = g.z * (1.0 - smoothstep(g.w * 0.25, g.w, dist));
	if (f <= 0.0) return vec3(0.0);
	vec2 dir = dist > 0.01 ? d / dist : vec2(0.7, 0.7);
	return vec3(dir.x, 0.0, dir.y) * f * (0.75 + 0.45 * sin(t * 17.0 + dist * 2.5));
}

float wave(float x, float t, float ph) {
	float k = 6.2831853 / wavelength;
	float gust = 0.75 + 0.25 * sin(t * 0.37 + ph) + 0.15 * sin(t * 1.13 + ph * 2.0);
	float reach = clamp(x / length_m, 0.0, 1.0);
	return (sin(k * x - t * speed + ph) + 0.35 * sin(k * 2.1 * x - t * speed * 1.7 + ph)) * amplitude * gust * reach;
}

void vertex() {
	float ph = dot(NODE_POSITION_WORLD.xz, vec2(1.7, 2.3));
	float x = max(VERTEX.x, 0.0);
	float dz = wave(x, TIME, ph);
	float dzdx = (wave(x + 0.02, TIME, ph) - dz) / 0.02;
	VERTEX.z += dz;
	vec3 blast = gust_push(gust_a, NODE_POSITION_WORLD.xz, TIME) + gust_push(gust_b, NODE_POSITION_WORLD.xz, TIME);
	VERTEX += transpose(mat3(MODEL_MATRIX)) * blast * clamp(x / length_m, 0.0, 1.0) * 1.5;
	VERTEX.y -= 0.04 * clamp(x / length_m, 0.0, 1.0) * (1.0 - 0.5 * abs(sin(TIME * 0.37 + ph)));   // cae un poco
	NORMAL = normalize(NORMAL + vec3(-dzdx * NORMAL.z, 0.0, dzdx * NORMAL.x));
	if (colors_srgb) {
		COLOR.rgb = mix(pow((COLOR.rgb + vec3(0.055)) * (1.0 / 1.055), vec3(2.4)), COLOR.rgb * (1.0 / 12.92), lessThan(COLOR.rgb, vec3(0.04045)));
	}
}

void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = roughness_v;
	SPECULAR = specular_v;
}
