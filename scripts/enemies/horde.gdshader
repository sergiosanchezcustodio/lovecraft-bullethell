// Hordas con instancias (hito 16.3, prototipo): todos los enemigos de un tipo en un MultiMesh.
// La malla es el modelo entero; cada vértice lleva en UV2.x el número de su parte. Las poses
// están grabadas en `anim_tex` (HordeMesh.bake, con las mismas funciones de Anims que mueven los
// nodos): una fila por fotograma de animación y, por parte, tres texeles con las tres filas de su
// transformación (relativa a la raíz del modelo). INSTANCE_CUSTOM.x dice qué fila toca.
shader_type spatial;

uniform sampler2D anim_tex : filter_nearest, repeat_disable;
uniform bool colors_srgb = true;
uniform float roughness_v : hint_range(0.0, 1.0) = 0.9;
uniform float specular_v : hint_range(0.0, 1.0) = 0.25;

varying float v_flash;

void vertex() {
	if (colors_srgb) {
		COLOR.rgb = mix(pow((COLOR.rgb + vec3(0.055)) * (1.0 / 1.055), vec3(2.4)), COLOR.rgb * (1.0 / 12.92), lessThan(COLOR.rgb, vec3(0.04045)));
	}
	int part = int(UV2.x + 0.5);
	int row = int(INSTANCE_CUSTOM.x + 0.5);
	vec4 r0 = texelFetch(anim_tex, ivec2(part * 3, row), 0);
	vec4 r1 = texelFetch(anim_tex, ivec2(part * 3 + 1, row), 0);
	vec4 r2 = texelFetch(anim_tex, ivec2(part * 3 + 2, row), 0);
	vec4 v = vec4(VERTEX, 1.0);
	VERTEX = vec3(dot(r0, v), dot(r1, v), dot(r2, v));
	vec4 n = vec4(NORMAL, 0.0);
	NORMAL = normalize(vec3(dot(r0, n), dot(r1, n), dot(r2, n)));
	v_flash = INSTANCE_CUSTOM.y;
}

void fragment() {
	ALBEDO = mix(COLOR.rgb, vec3(1.0), v_flash * 0.75);
	ROUGHNESS = roughness_v;
	SPECULAR = specular_v;
}
