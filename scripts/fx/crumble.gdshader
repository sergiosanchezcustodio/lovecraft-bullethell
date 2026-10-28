// Enemigo que se desmorona al morir (hito 11.1, 27-10-2026): el modelo se deshace voxel a voxel,
// antes los de arriba, con un borde de brasa en lo que está a punto de caer. Un solo material
// para todos (Crumble): lo de cada enemigo va en parámetros de instancia. Las caras están en
// coordenadas de su pieza; la celda del voxel se saca en el fragmento, metiendo el punto medio
// vóxel hacia dentro de la cara.
shader_type spatial;

uniform bool colors_srgb = true;
instance uniform float cut = 0.0;                 // 0 entero, 1 deshecho
instance uniform float vox = 0.03125;             // metros por voxel del modelo
instance uniform float height = 1.5;              // altura del modelo (m), para ir de arriba abajo
instance uniform float base_y = 0.0;              // pies, en el mundo
instance uniform float glow = 0.0;                // capa que brillaba (ojos, bioluminiscencia)
instance uniform vec4 ember : source_color = vec4(1.0, 0.5, 0.18, 1.0);
instance uniform float roughness_v = 0.6;

varying vec3 lp;
varying float wy;

float hash(vec3 p) {                              // el de night_sky.gdshaderinc, en 3D
	p = fract(p * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

void vertex() {
	lp = VERTEX - NORMAL * vox * 0.5;
	wy = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
	if (colors_srgb) {
		COLOR.rgb = mix(pow((COLOR.rgb + vec3(0.055)) * (1.0 / 1.055), vec3(2.4)), COLOR.rgb * (1.0 / 12.92), lessThan(COLOR.rgb, vec3(0.04045)));
	}
}

void fragment() {
	float h = hash(floor(lp / vox) + 17.0);
	float up = clamp((wy - base_y) / max(height, 0.1), 0.0, 1.0);
	float key = h * 0.6 + (1.0 - up) * 0.4;       // arriba, antes
	if (key < cut) discard;
	float edge = 1.0 - smoothstep(0.0, 0.09, key - cut);
	ALBEDO = mix(COLOR.rgb, ember.rgb, edge * 0.6);
	EMISSION = ember.rgb * edge * step(0.001, cut) * 2.5 + COLOR.rgb * glow;
	ROUGHNESS = roughness_v;
	SPECULAR = 0.3;
}
