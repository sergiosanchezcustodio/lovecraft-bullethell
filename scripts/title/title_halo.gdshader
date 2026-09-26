// Texto del título con un halo fino de niebla alrededor de su silueta. El rectángulo es
// mayor que la imagen (margen `pad` a cada lado) para que la niebla no se corte.
// `reveal` (0..1) hace la entrada: se forma una niebla densa con la silueta del título
// (fog_tex: su alfa muy difuminado), las letras se condensan dentro de ella y la niebla se
// deshace a jirones hasta dejar solo el halo fino.
shader_type canvas_item;

uniform sampler2D fog_tex : filter_linear;    // Texto_titulo_niebla.png (ya con el margen)
uniform float pad = 0.14;
uniform bool halo_enabled = true;
uniform float halo_radius = 16.0;             // px de la imagen original
uniform float halo_strength = 0.8;
uniform vec4 halo_color : source_color = vec4(0.62, 0.72, 0.92, 0.75);
uniform bool fog_enabled = true;
uniform vec4 fog_color : source_color = vec4(0.66, 0.74, 0.90, 0.6);
uniform float reveal = 1.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
// Ruido de gradiente (sin las aristas en cuadrícula del ruido de valores).
vec2 grad(vec2 i) {
	float a = fract(sin(dot(i, vec2(127.1, 311.7))) * 43758.5453) * 6.2832;
	return vec2(cos(a), sin(a));
}
float gnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	float a = dot(grad(i), f);
	float b = dot(grad(i + vec2(1, 0)), f - vec2(1, 0));
	float c = dot(grad(i + vec2(0, 1)), f - vec2(0, 1));
	float d = dot(grad(i + vec2(1, 1)), f - vec2(1, 1));
	return 0.5 + 0.7 * mix(mix(a, b, u.x), mix(c, d, u.x), u.y);   // ~0..1
}
const mat2 ROT = mat2(vec2(0.80, 0.60), vec2(-0.60, 0.80));       // cada octava, girada
float fbm(vec2 p) {
	float v = gnoise(p) * 0.55; p = ROT * p * 2.03 + 4.2;
	v += gnoise(p) * 0.3; p = ROT * p * 2.07 + 9.1;
	return v + gnoise(p) * 0.15;
}

// TEXTURE solo existe dentro de fragment(): se pasa como parámetro
float alpha_at(sampler2D tex, vec2 uv) {
	if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) return 0.0;
	return texture(tex, uv).a;
}

void fragment() {
	vec2 uv = (UV - pad) / (1.0 - 2.0 * pad);
	vec4 base = vec4(0.0);
	if (uv.x >= 0.0 && uv.y >= 0.0 && uv.x <= 1.0 && uv.y <= 1.0) base = texture(TEXTURE, uv);
	float halo = 0.0;
	if (halo_enabled) {
		// alfa difuminado alrededor (dos anillos de muestras) menos el propio texto
		vec2 px = TEXTURE_PIXEL_SIZE * halo_radius;
		float sum = 0.0;
		for (int i = 0; i < 16; i++) {
			float a = 6.2832 * float(i) / 16.0;
			vec2 d = vec2(cos(a), sin(a));
			sum += alpha_at(TEXTURE, uv + d * px) + alpha_at(TEXTURE, uv + d * px * 0.5);
		}
		float blur = sum / 32.0;
		halo = clamp(blur * 1.8, 0.0, 1.0) * (1.0 - base.a);     // solo por fuera del contorno
		// deshilachado que se mueve despacio
		float n = noise(uv * vec2(22.0, 15.0) + vec2(TIME * 0.12, -TIME * 0.07)) * 0.6
			+ noise(uv * vec2(55.0, 40.0) - vec2(TIME * 0.2, 0.0)) * 0.4;
		halo *= mix(0.35, 1.0, n) * halo_strength;
	}
	// Niebla de la entrada: crece hasta cubrir la silueta, se mantiene y se deshace a jirones.
	float fog = 0.0;
	float dissolve = smoothstep(0.38, 1.0, reveal);           // 0 densa .. 1 desaparecida
	if (fog_enabled && reveal < 1.0) {
		vec2 c = UV - 0.5;
		vec2 fuv = 0.5 + c * (1.0 - 0.07 * dissolve) + vec2(0.0, 0.03 * dissolve);   // se expande y sube
		float shape = texture(fog_tex, fuv).r;
		vec2 q = UV * vec2(9.0, 6.0);
		float n = fbm(q + vec2(TIME * 0.12, TIME * -0.05) + fbm(q * 0.7 - TIME * 0.06) * 1.2);
		float wisps = smoothstep(0.25, 0.8, n);                // jirones, no una masa uniforme
		float build = smoothstep(0.0, 0.3, reveal);
		// cada punto se despeja cuando el avance supera su valor de ruido: se deshace a jirones
		float keep = 1.0 - smoothstep(n - 0.22, n + 0.06, dissolve * 1.3 - 0.12);
		fog = shape * mix(0.25, 1.0, wisps) * build * keep;
	}
	// Las letras se condensan dentro de la niebla, primero tenues y con el mismo ruido.
	float tn = noise(uv * vec2(18.0, 12.0) + 2.0);
	float text_in = smoothstep(tn * 0.35 + 0.22, tn * 0.35 + 0.62, reveal) * smoothstep(0.18, 0.5, reveal);
	float halo_in = smoothstep(0.45, 0.95, reveal);
	// Composición "encima": niebla sobre texto sobre halo, con los colores ponderados por su
	// alfa (una mezcla simple teñía de gris el texto mientras aparecía).
	float ta = base.a * text_in;
	float ha = halo_color.a * halo * halo_in;
	float out_a = ta + ha * (1.0 - ta);
	vec3 out_rgb = (base.rgb * ta + halo_color.rgb * ha * (1.0 - ta)) / max(out_a, 0.0001);
	float fa = fog_color.a * fog;
	vec3 rgb = (fog_color.rgb * fa + out_rgb * out_a * (1.0 - fa));
	float a = fa + out_a * (1.0 - fa);
	COLOR = vec4(rgb / max(a, 0.0001), a);
}
