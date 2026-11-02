// Hordas con instancias (hito 16.3): todos los enemigos de un tipo en MultiMesh (HordeMesh).
// La malla es el modelo entero; cada vértice lleva en UV2.x el número de su parte. Las poses
// están grabadas en `anim_tex` con las mismas funciones de Anims que mueven los nodos: una fila
// por fotograma de animación y, por parte, tres texeles con las tres filas de su transformación
// (relativa a la raíz del modelo). Por instancia (INSTANCE_CUSTOM): x, la fila; y, el color del
// destello o del tinte de estado (sRGB empaquetado en 24 bits); z, su alfa.
// El tinte imita la pasada `material_overlay` sin sombreado de los enemigos con nodos:
// lo iluminado × (1 − a) + color × a.
shader_type spatial;

uniform sampler2D anim_tex : filter_nearest, repeat_disable;
uniform bool colors_srgb = true;
uniform bool glow = false;                    // la capa de luces (ojos): sin sombreado
uniform float roughness_v : hint_range(0.0, 1.0) = 0.9;
uniform float specular_v : hint_range(0.0, 1.0) = 0.25;

varying vec4 v_tint;

vec3 to_linear(vec3 c) {
	return mix(pow((c + vec3(0.055)) * (1.0 / 1.055), vec3(2.4)), c * (1.0 / 12.92), lessThan(c, vec3(0.04045)));
}

void vertex() {
	if (colors_srgb) COLOR.rgb = to_linear(COLOR.rgb);
	int part = int(UV2.x + 0.5);
	int row = int(INSTANCE_CUSTOM.x + 0.5);
	vec4 r0 = texelFetch(anim_tex, ivec2(part * 3, row), 0);
	vec4 r1 = texelFetch(anim_tex, ivec2(part * 3 + 1, row), 0);
	vec4 r2 = texelFetch(anim_tex, ivec2(part * 3 + 2, row), 0);
	vec4 v = vec4(VERTEX, 1.0);
	VERTEX = vec3(dot(r0, v), dot(r1, v), dot(r2, v));
	vec4 n = vec4(NORMAL, 0.0);
	NORMAL = normalize(vec3(dot(r0, n), dot(r1, n), dot(r2, n)));
	int packed = int(INSTANCE_CUSTOM.y + 0.5);
	vec3 c = vec3(float((packed >> 16) & 255), float((packed >> 8) & 255), float(packed & 255)) / 255.0;
	v_tint = vec4(to_linear(c), INSTANCE_CUSTOM.z);
}

void fragment() {
	float a = v_tint.a;
	if (glow) {
		ALBEDO = vec3(0.0);
		ROUGHNESS = 1.0;
		SPECULAR = 0.0;
		EMISSION = COLOR.rgb * (1.0 - a) + v_tint.rgb * a;
	} else {
		ALBEDO = COLOR.rgb * (1.0 - a);
		ROUGHNESS = roughness_v;
		SPECULAR = specular_v * (1.0 - a);
		EMISSION = v_tint.rgb * a;
	}
}
