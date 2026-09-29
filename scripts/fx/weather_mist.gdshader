// Bancos de niebla bajos del clima (D-33): un plano a poca altura que sigue a la cámara.
// La forma sale de ruido de gradiente con octavas giradas en coordenadas del mundo, alargado
// y empujado por el viento (`offset`); el ruido de valores con umbrales daba grano y
// cuadrícula. Donde el plano corta a los personajes o al decorado se funde con la
// profundidad (sin línea dura). `flash` lo aclara durante un rayo.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec3 tint : source_color = vec3(0.62, 0.7, 0.8);
uniform float opacity = 0.3;
uniform float scale = 9.0;              // m por unidad de ruido
uniform vec2 offset = vec2(0.0);        // desplazamiento del viento (m)
uniform float flash = 0.0;
uniform float exposure_comp = 0.6;      // el tonemapper aclara lo que no se ilumina
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;

varying vec3 world_pos;

vec2 hash2(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float gnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(dot(hash2(i), f), dot(hash2(i + vec2(1, 0)), f - vec2(1, 0)), u.x),
		mix(dot(hash2(i + vec2(0, 1)), f - vec2(0, 1)), dot(hash2(i + vec2(1, 1)), f - vec2(1, 1)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.6;
	mat2 r = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
	for (int i = 0; i < 3; i++) {
		v += a * gnoise(p);
		p = r * p * 2.03;
		a *= 0.45;
	}
	return v;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = (world_pos.xz - offset) / scale;
	p.x *= 0.55;                                              // bancos alargados
	float n = fbm(p + vec2(TIME * 0.015, 0.0)) * 0.5 + 0.5;
	float shape = smoothstep(0.42, 0.78, n);
	// fundido con lo que atraviesa (profundidad lineal, vale para la cámara ortográfica)
	float d = texture(depth_tex, SCREEN_UV).r;
	vec4 v = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, d, 1.0);
	float scene = -v.z / v.w;
	float soft = clamp((scene - (-VERTEX.z)) / 0.6, 0.0, 1.0);
	// borde del plano: se desvanece para que no se vea su contorno
	vec2 c = UV * 2.0 - 1.0;
	float edge = 1.0 - smoothstep(0.7, 1.0, max(abs(c.x), abs(c.y)));
	ALBEDO = mix(tint, vec3(0.9, 0.93, 1.0), flash * 0.6) * exposure_comp;
	ALPHA = shape * opacity * soft * edge;
}
