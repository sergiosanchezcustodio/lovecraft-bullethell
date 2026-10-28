// Heridas que crecen con la vida perdida (hito 12.6, 28-10-2026): segunda pasada sobre el
// material del enemigo (élites, únicos y grandes). Grietas en celdas de voxel, oscuras con un
// filo del color de su sangre o icor que brilla un poco; con más daño, más grietas y más anchas.
// Lo de cada enemigo va en parámetros de instancia (`hurt` 0..1, `tint`, `vox`). Las caras están
// en coordenadas de su pieza, así que las grietas se mueven con ella.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_back, shadows_disabled;

instance uniform float hurt = 0.0;                // 0 sano, 1 a punto de morir
instance uniform vec4 tint : source_color = vec4(0.55, 0.05, 0.04, 1.0);
instance uniform float vox = 0.03125;             // metros por voxel del modelo

varying vec3 lp;

float hash3(vec3 p) {                             // el de crumble.gdshader (como night_sky)
	p = fract(p * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

float vnoise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = mix(hash3(i), hash3(i + vec3(1, 0, 0)), f.x);
	float b = mix(hash3(i + vec3(0, 1, 0)), hash3(i + vec3(1, 1, 0)), f.x);
	float c = mix(hash3(i + vec3(0, 0, 1)), hash3(i + vec3(1, 0, 1)), f.x);
	float d = mix(hash3(i + vec3(0, 1, 1)), hash3(i + vec3(1, 1, 1)), f.x);
	return mix(mix(a, b, f.y), mix(c, d, f.y), f.z);
}

void vertex() {
	lp = VERTEX - NORMAL * vox * 0.5;
	if (hurt < 0.03) VERTEX = vec3(0.0);           // sano: sin triángulos (no se pinta nada)
}

void fragment() {
	vec3 c = floor(lp / vox);                       // celda del voxel
	float n = vnoise(c * 0.11 + 7.0);               // vetas de unos 9 voxels
	float crack = abs(n - 0.5);
	float w = 0.012 + 0.05 * hurt;                  // más anchas cuanto más herido
	float spread = vnoise(c * 0.045 + 31.0);        // por dónde van apareciendo
	if (crack > w || spread > hurt * 1.15) discard;
	float inner = 1.0 - crack / w;                  // 1 en el centro de la grieta
	vec3 dark = tint.rgb * 0.12;
	ALBEDO = mix(dark, tint.rgb, smoothstep(0.6, 1.0, inner) * (0.3 + 0.5 * hurt));
	ALPHA = 0.92;
}
