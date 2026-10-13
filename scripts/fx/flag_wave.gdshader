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
