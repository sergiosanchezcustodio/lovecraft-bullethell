// Texto del título con un halo fino de niebla alrededor de su silueta. El rectángulo es
// mayor que la imagen (margen `pad` a cada lado) para que el halo no se corte.
// `reveal` (0..1) hace la entrada: primero se forma la niebla y después emergen las letras.
shader_type canvas_item;

uniform float pad = 0.06;
uniform bool halo_enabled = true;
uniform float halo_radius = 16.0;             // px de la imagen original
uniform float halo_strength = 0.8;
uniform vec4 halo_color : source_color = vec4(0.62, 0.72, 0.92, 0.75);
uniform float reveal = 1.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
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
	float halo_in = smoothstep(0.0, 0.55, reveal);
	float text_in = smoothstep(0.3, 1.0, reveal);
	// Composición "encima": el texto sobre el halo, con los colores ponderados por su alfa
	// (una mezcla simple teñía de gris el texto mientras aparecía).
	float ta = base.a * text_in;
	float ha = halo_color.a * halo * halo_in;
	float out_a = ta + ha * (1.0 - ta);
	vec3 out_rgb = (base.rgb * ta + halo_color.rgb * ha * (1.0 - ta)) / max(out_a, 0.0001);
	COLOR = vec4(out_rgb, out_a);
}
