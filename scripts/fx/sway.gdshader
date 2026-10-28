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
uniform bool unshaded_glow = false;           // capa de luz de la misma pieza
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

void vertex() {
	if (colors_srgb) {
		COLOR.rgb = mix(pow((COLOR.rgb + vec3(0.055)) * (1.0 / 1.055), vec3(2.4)), COLOR.rgb * (1.0 / 12.92), lessThan(COLOR.rgb, vec3(0.04045)));
	}
	float ph = dot(NODE_POSITION_WORLD.xz, vec2(1.31, 0.73));
	float k = hang ? clamp(-VERTEX.y / height, 0.0, 1.0) : pow(clamp(VERTEX.y / height, 0.0, 1.0), 1.7);
	float gust = 0.55 + 0.45 * sin(TIME * 0.29 + ph * 0.5) * sin(TIME * 0.17 + ph);
	float s = sin(TIME * speed + ph) * 0.65 + sin(TIME * speed * 2.7 + ph * 1.9 + VERTEX.y * 1.7) * 0.25 * k;
	mat3 to_local = transpose(mat3(MODEL_MATRIX));          // giro (y escala uniforme) inverso
	vec3 w = normalize(to_local * vec3(wind.x, 0.0, wind.y));
	vec3 side = normalize(to_local * vec3(-wind.y, 0.0, wind.x));
	VERTEX += (w * (0.35 + s) * gust + side * 0.25 * sin(TIME * speed * 1.6 + ph * 2.3)) * amplitude * k;
	vec3 blast = gust_push(gust_a, NODE_POSITION_WORLD.xz, TIME) + gust_push(gust_b, NODE_POSITION_WORLD.xz, TIME);
	VERTEX += to_local * blast * k;
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
