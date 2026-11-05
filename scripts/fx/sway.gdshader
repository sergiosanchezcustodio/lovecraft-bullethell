// Balanceo con el viento (ambiente de los escenarios, 16-10-2026): árboles, juncos, cañas.
// La pieza se dobla más cuanto más alta (la base no se mueve), con rachas lentas y un temblor
// más rápido arriba; la fase depende de dónde está, así que dos árboles no van a la par. Con
// `hang`, al revés: cuelga del pivote (ropa tendida, redes) y se mece más cuanto más abajo.
// El viento va en coordenadas del mundo; las sombras se mueven con la pieza.
shader_type spatial;

uniform bool colors_srgb = true;
uniform float roughness_v : hint_range(0.0, 1.0) = 0.9;
uniform float specular_v : hint_range(0.0, 1.0) = 0.25;
uniform float amplitude = 0.12;               // desplazamiento arriba del todo (m)
uniform float height = 4.0;                   // m hasta donde llega el balanceo completo
uniform float speed = 1.1;                    // rad/s
uniform vec2 wind = vec2(0.8, 0.6);           // dirección del viento (mundo)
uniform bool hang = false;
uniform float flutter = 0.0;                  // lona (hito 17.13): ondas rápidas que recorren la pieza (m)
uniform bool unshaded_glow = false;           // capa de luz de la misma pieza
global uniform vec4 gust_a;                   // ráfagas de explosiones y esquives (Gusts, hito 11.4):
global uniform vec4 gust_b;                   // x, z, fuerza (m) y radio
global uniform vec4 walk_a;                   // dónde están los jugadores (Ambient, hito 17.17): xz del 1 y el 2
global uniform vec4 walk_b;                   // y del 3 y el 4 (lejísimos si no hay)
uniform float part_r = 0.0;                   // juncos: se apartan a menos de esto (m) de un jugador
uniform float part_push = 0.32;               // lo que se aparta lo más alto (m)

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

void vertex() {
	if (colors_srgb) {
		COLOR.rgb = mix(pow((COLOR.rgb + vec3(0.055)) * (1.0 / 1.055), vec3(2.4)), COLOR.rgb * (1.0 / 12.92), lessThan(COLOR.rgb, vec3(0.04045)));
	}
	float ph = dot(NODE_POSITION_WORLD.xz, vec2(1.31, 0.73));
	vec2 rest_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;     // antes de moverse: no tiembla
	float k = hang ? clamp(-VERTEX.y / height, 0.0, 1.0) : pow(clamp(VERTEX.y / height, 0.0, 1.0), 1.7);
	float gust = 0.55 + 0.45 * sin(TIME * 0.29 + ph * 0.5) * sin(TIME * 0.17 + ph);
	float s = sin(TIME * speed + ph) * 0.65 + sin(TIME * speed * 2.7 + ph * 1.9 + VERTEX.y * 1.7) * 0.25 * k;
	mat3 to_local = transpose(mat3(MODEL_MATRIX));          // giro (y escala uniforme) inverso
	vec3 w = normalize(to_local * vec3(wind.x, 0.0, wind.y));
	vec3 side = normalize(to_local * vec3(-wind.y, 0.0, wind.x));
	VERTEX += (w * (0.35 + s) * gust + side * 0.25 * sin(TIME * speed * 1.6 + ph * 2.3)) * amplitude * k;
	if (flutter > 0.0) {                      // de la posición (no de la cara): los voxels no se separan
		vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		float f = sin(TIME * speed * 4.3 - dot(wp.xz, wind) * 5.0 + wp.y * 3.0) * (0.6 + 0.4 * gust);
		VERTEX += side * f * flutter * k;
	}
	vec3 blast = gust_push(gust_a, NODE_POSITION_WORLD.xz, TIME) + gust_push(gust_b, NODE_POSITION_WORLD.xz, TIME);
	VERTEX += to_local * blast * k;
	vec2 who[4] = vec2[4](walk_a.xy, walk_a.zw, walk_b.xy, walk_b.zw);
	float near = 1e9;                         // la mata entera, de una vez: casi todas están lejos
	if (part_r > 0.0) for (int i = 0; i < 4; i++) near = min(near, distance(NODE_POSITION_WORLD.xz, who[i]));
	if (near < part_r + 3.0) {                // los juncos se apartan al pasar
		vec2 push = vec2(0.0);
		for (int i = 0; i < 4; i++) {
			vec2 d = rest_xz - who[i];
			float dist = length(d);
			if (dist < part_r) push += (dist > 0.01 ? d / dist : vec2(0.7, 0.7)) * (1.0 - smoothstep(part_r * 0.3, part_r, dist));
		}
		VERTEX += to_local * vec3(push.x, -0.25 * length(push), push.y) * part_push * k;
	}
}

void fragment() {
	ALBEDO = COLOR.rgb;
	if (!unshaded_glow) {
		ROUGHNESS = roughness_v;
		SPECULAR = specular_v;
	} else {
		EMISSION = COLOR.rgb;
		ALBEDO = vec3(0.0);
	}
}
