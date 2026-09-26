// Balas enemigas en voxel 3D (lenguaje de daños, GDD 4.4): cúmulos de cubos iluminados
// como el resto del mundo, con un brillo propio suave para que se lean de noche.
//   físico (1): bola maciza de cubos en rojos, naranjas y un núcleo amarillo.
//   mental (2): anillo de cubos morados y lilas que gira y ondula alrededor de un núcleo
//               violeta oscuro.
//   mixto (3):  el núcleo físico dentro del anillo mental.
// Colores apagados a propósito: con muchas balas, los tonos vivos marean.
// Lo que tapa el decorado lo dibuja la segunda pasada (bullet_voxel_hidden.gdshader).
shader_type spatial;
render_mode cull_back, shadows_disabled, fog_disabled;

#include "res://scripts/bullets/bullet_voxel.gdshaderinc"

uniform vec3 phys_core : source_color = vec3(0.78, 0.54, 0.22);   // amarillo anaranjado
uniform vec3 phys_mid : source_color = vec3(0.60, 0.25, 0.10);    // naranja
uniform vec3 phys_edge : source_color = vec3(0.36, 0.08, 0.05);   // rojo oscuro
uniform vec3 ment_light : source_color = vec3(0.52, 0.40, 0.70);  // lila
uniform vec3 ment_mid : source_color = vec3(0.34, 0.17, 0.52);    // morado
uniform vec3 ment_dark : source_color = vec3(0.19, 0.07, 0.29);   // violeta oscuro
uniform float glow = 0.22;                                        // brillo propio (fracción del color)

void vertex() {
	v_style = INSTANCE_CUSTOM.x;
	v_group = group_of(COLOR);
	v_shade = COLOR.r;
	VERTEX = bullet_vertex(VERTEX, COLOR, INSTANCE_CUSTOM, TIME);
}

void fragment() {
	int style = int(v_style + 0.5);
	vec3 c;
	if (v_group > 1.5) {
		c = mix(ment_mid, ment_light, v_shade);                    // anillo
	} else if (style == 2) {
		c = ment_dark;                                            // núcleo del mental
	} else if (v_group < 0.5) {
		c = mix(phys_mid, phys_core, v_shade);                     // núcleo interior
	} else {
		c = mix(phys_edge, phys_mid, v_shade);                     // capa exterior
	}
	ALBEDO = c;
	ROUGHNESS = 0.7;
	SPECULAR = 0.3;
	EMISSION = c * glow;
}
