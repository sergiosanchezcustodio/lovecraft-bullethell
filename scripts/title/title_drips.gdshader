// Gotas que caen de la bóveda al suelo mojado de la portada (TitleDrips): un hilo claro que cae,
// un brinco al chocar y anillos que se abren aplastados por la perspectiva, deformando el
// reflejo de las velas (se copia la ilustración desplazada) y con un brillo frío en la cresta.
shader_type canvas_item;

const int N = 6;
uniform sampler2D art : filter_linear_mipmap;
uniform vec2 design = vec2(1920.0, 1080.0);
uniform vec4 rect;                  // x, y, ancho, alto (px de 1920×1080)
uniform vec4 drips[N];              // x, y del impacto, edad (s; negativa mientras cae), tamaño
uniform float fall_time = 0.35;
uniform float squash = 0.32;        // el suelo se ve de lado: los anillos, aplastados

void fragment() {
	vec2 p = rect.xy + UV * rect.zw;
	vec2 disp = vec2(0.0);
	float glow = 0.0;
	float a = 0.0;
	for (int i = 0; i < N; i++) {
		vec4 d = drips[i];
		if (d.w <= 0.0) continue;
		float age = d.z;
		vec2 q = p - d.xy;
		if (age < 0.0) {
			// cayendo: hilo fino que baja deprisa hasta el suelo
			float y = mix(-260.0, 0.0, 1.0 - (-age / fall_time));
			float on = step(abs(q.x), 1.0 * d.w) * smoothstep(-22.0 * d.w, 0.0, q.y - y) * step(q.y, y);
			glow += on * 1.1; a = max(a, on);
			continue;
		}
		vec2 e = vec2(q.x, q.y / squash);
		float r = length(e);
		float amp = exp(-age * 1.5) * d.w;
		for (int k = 0; k < 3; k++) {
			float rr = 3.0 + (age - float(k) * 0.22) * 55.0;
			if (rr < 0.0) continue;
			float crest = exp(-pow((r - rr) / 3.2, 2.0)) * amp * (1.0 - float(k) * 0.3);
			float trough = exp(-pow((r - rr + 5.0) / 3.2, 2.0)) * amp * (1.0 - float(k) * 0.3);
			disp += normalize(e + 1e-4) * vec2(1.0, squash) * (crest - trough) * 6.0;
			glow += crest * 0.32 - trough * 0.12;
			a = max(a, clamp((crest + trough) * 2.0, 0.0, 1.0));
		}
		// brinco al chocar
		float splash = exp(-age * 18.0) * smoothstep(3.0 * d.w, 0.0, length(vec2(q.x, (q.y + 4.0 * d.w) * 0.6)));
		glow += splash * 1.2; a = max(a, splash);
	}
	vec3 c = texture(art, (p + disp) / design).rgb + vec3(0.55, 0.7, 1.0) * glow;
	COLOR = vec4(c, a);
}
