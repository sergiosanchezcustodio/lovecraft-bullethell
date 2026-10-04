shader_type spatial;
// Gemas de experiencia: facetas en tonos neutros (color de vértice) teñidas con el color de su
// escalón (color de instancia del MultiMesh: en spatial, COLOR ya es vértice × instancia).
// Algo metálicas y con un brillo propio suave, para verse de noche sin quemarse con ACES.
render_mode cull_disabled;
uniform bool srgb = true;

void fragment() {
	vec3 c = COLOR.rgb;
	if (srgb) c = mix(pow((c + vec3(0.055)) * (1.0 / 1.055), vec3(2.4)), c * (1.0 / 12.92), lessThan(c, vec3(0.04045)));
	ALBEDO = c;
	METALLIC = 0.4;
	ROUGHNESS = 0.5;
	EMISSION = c * 0.35;
}
