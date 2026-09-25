// Niebla del suelo (se suma sobre el fondo): jirones que derivan muy despacio, solo donde
// la ilustración ya tiene niebla (mascara_zonas.G).
shader_type canvas_item;
render_mode blend_add;

uniform sampler2D zonas : filter_linear;
uniform float aspect = 1.7778;
uniform float fog_strength = 0.55;
uniform float fog_speed = 0.012;
uniform vec3 fog_color : source_color = vec3(0.30, 0.45, 1.0);

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) {
	float v = 0.0; float a = 0.5;
	for (int i = 0; i < 5; i++) { v += a * noise(p); p *= 2.03; a *= 0.5; }
	return v;
}

void fragment() {
	float density = texture(zonas, UV).g;
	vec2 p = UV * vec2(aspect, 1.0) * vec2(3.2, 9.0);           // jirones alargados en horizontal
	float t = TIME * fog_speed;
	float n = fbm(p + vec2(t * 30.0, sin(t * 11.0) * 0.4)) * 0.6 + fbm(p * 1.7 - vec2(t * 18.0, 0.0) + 7.1) * 0.4;
	float wisps = smoothstep(0.42, 0.78, n);
	COLOR = vec4(fog_color * wisps * density * fog_strength * 0.35, 1.0);
}
