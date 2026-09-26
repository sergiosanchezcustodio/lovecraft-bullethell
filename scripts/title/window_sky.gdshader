// Capa del ventanal (se suma sobre el fondo): halo de la luna que respira, resplandor tenue
// del relámpago y el brillo de los ojos. Cada efecto se activa por separado.
shader_type canvas_item;
render_mode blend_add;

uniform sampler2D zonas : filter_linear;      // R cielo claro, G niebla, B cristal
uniform float aspect = 1.7778;

uniform bool moon_enabled = true;
uniform vec2 moon_pos = vec2(0.6242, 0.1528);
uniform float moon_radius = 0.0275;
uniform float moon_halo_strength = 0.3;
uniform float moon_halo_period = 7.0;
uniform vec3 moon_color : source_color = vec3(0.55, 0.75, 1.0);

uniform bool lightning_enabled = true;
uniform float flash = 0.0;                    // lo anima el script

uniform bool eyes_enabled = true;
uniform vec2 eye_left = vec2(0.6151, 0.1898);
uniform vec2 eye_right = vec2(0.6294, 0.1898);
uniform float eyes_glow = 0.0;                // lo anima el script
uniform vec3 eyes_color : source_color = vec3(0.85, 1.0, 0.75);

void fragment() {
	vec4 z = texture(zonas, UV);
	vec3 add = vec3(0.0);
	if (moon_enabled) {
		float d = length((UV - moon_pos) * vec2(aspect, 1.0));
		float r = moon_radius * aspect;          // el radio viene en fracción del ancho
		// respira entre el 70 % y el 100 %; solo por fuera del disco (la luna no parpadea)
		float breath = 0.85 + 0.15 * sin(TIME * 6.2832 / moon_halo_period);
		float outside = smoothstep(r * 0.92, r * 1.05, d);
		float ring = exp(-pow((d - r * 1.12) / (r * 0.28), 2.0));
		float glow = exp(-max(d - r, 0.0) / (r * 1.3)) * outside;
		add += moon_color * (ring * 0.6 + glow * 0.5) * moon_halo_strength * breath * mix(0.35, 1.0, z.b);
	}
	if (lightning_enabled && flash > 0.0) {
		// el cielo se aclara y la silueta de Cthulhu (fuera de la máscara R) se recorta oscura
		add += vec3(0.62, 0.72, 1.0) * flash * (z.r * 0.9 + z.b * 0.25);
	}
	if (eyes_enabled && eyes_glow > 0.0) {
		float s = 0.0045;
		float e = exp(-pow(length((UV - eye_left) * vec2(aspect, 1.0)) / s, 2.0))
			+ exp(-pow(length((UV - eye_right) * vec2(aspect, 1.0)) / s, 2.0));
		add += eyes_color * e * eyes_glow;
	}
	COLOR = vec4(add, 1.0);
}
