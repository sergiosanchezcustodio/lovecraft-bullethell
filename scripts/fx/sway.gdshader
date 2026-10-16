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
