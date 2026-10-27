// Fondo de las ventanas de los menús (biblioteca gótica, 27-10-2026): madera oscura con veta,
// viñeta hacia los bordes, un resplandor cálido de vela arriba y doble filete de latón con bisel
// (la banda ancha con luz arriba y a la izquierda). Las esquinas de filigrana van encima, como
// imágenes (MenuKit.window).
shader_type canvas_item;

uniform vec2 size = vec2(800.0, 600.0);         // px del panel (lo pone MenuKit al cambiar de tamaño)
uniform vec3 brass : source_color = vec3(0.74, 0.56, 0.3);
uniform float alpha = 0.97;
uniform float glow = 1.0;                       // parpadeo de la vela (MenuKit, con los botones marcados)

// el hash de night_sky.gdshaderinc (sin senos; ver CLAUDE.md)
float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * vnoise(p);
		p = p * 2.03 + 11.7;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 px = UV * size;
	// madera: veta alargada en horizontal, torcida por un ruido lento
	float warp = fbm(px * vec2(0.0025, 0.006)) * 6.0;
	float grain = fbm(px * vec2(0.0035, 0.05) + vec2(warp, 0.0));
	float lines = 0.5 + 0.5 * sin(px.y * 0.11 + warp * 5.0 + grain * 8.0);
	vec3 col = mix(vec3(0.026, 0.019, 0.016), vec3(0.07, 0.047, 0.034), grain * 0.75 + lines * 0.2);
	// resplandor de vela, arriba en el centro
	vec2 c = (px - vec2(size.x * 0.5, size.y * 0.12)) / max(size.x, 1.0);
	col += vec3(0.09, 0.048, 0.016) * glow * exp(-dot(c, c) * 5.0);
	// viñeta
	vec2 e = min(px, size - px);
	float d = min(e.x, e.y);
	col *= mix(0.5, 1.0, smoothstep(0.0, 110.0, d));
	// filete ancho de latón (4 a 9 px del borde), con bisel: luz arriba y a la izquierda
	float band = smoothstep(3.5, 4.5, d) * (1.0 - smoothstep(8.5, 9.5, d));
	float t = clamp((d - 4.0) / 5.0, 0.0, 1.0);
	float lit = (e.y < e.x) ? (px.y < size.y * 0.5 ? 1.0 : 0.45) : (px.x < size.x * 0.5 ? 0.85 : 0.5);
	float ridge = 1.0 - abs(t - 0.35) * 1.4;
	vec3 metal = brass * (0.35 + 0.75 * ridge * lit) * (0.85 + 0.3 * vnoise(px * 0.35));
	col = mix(col, metal, band);
	// filete fino por dentro
	float thin = smoothstep(15.0, 15.7, d) * (1.0 - smoothstep(16.6, 17.3, d));
	col = mix(col, brass * 0.6, thin * 0.75);
	// canto oscuro por fuera
	col = mix(col, vec3(0.008, 0.006, 0.005), 1.0 - smoothstep(2.5, 3.5, d));
	COLOR = vec4(col, alpha);
}
