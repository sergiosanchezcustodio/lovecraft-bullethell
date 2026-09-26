// Niebla del suelo: la niebla pintada se espesa y se aclara en bancos grandes y suaves que
// derivan despacio, solo donde la ilustración ya tiene niebla (mascara_zonas.G).
// Sin umbrales ni detalle fino (el grano era lo que la hacía artificial): pocas octavas,
// formas alargadas con perspectiva (más pequeñas y lentas al fondo) y deformación del dominio
// para que cambien de forma al avanzar.
// Mezcla premultiplicada: rgb suma bruma y alfa oscurece un poco donde se aclara.
shader_type canvas_item;
render_mode blend_premul_alpha;

uniform sampler2D zonas : filter_linear;
uniform float aspect = 1.7778;
uniform float fog_strength = 1.0;
uniform float fog_speed = 1.0;
uniform vec3 fog_color : source_color = vec3(0.30, 0.45, 1.0);
uniform float horizon = 0.64;                 // altura del fondo de la sala (fracción)

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
float fbm3(vec2 p) {
	float v = gnoise(p) * 0.57; p = ROT * p * 2.03 + 3.1;
	v += gnoise(p) * 0.29; p = ROT * p * 2.07 + 7.7;
	return v + gnoise(p) * 0.14;
}

void fragment() {
	float density = texture(zonas, UV).g;
	if (density < 0.004) discard;
	// perspectiva: cerca del horizonte las formas se comprimen y van más despacio
	float depth = clamp((UV.y - horizon) / (1.0 - horizon), 0.0, 1.0);
	float near = mix(0.35, 1.0, depth);
	vec2 p = vec2((UV.x - 0.5) * aspect / near, (UV.y - horizon) / (near * near)) * vec2(1.3, 6.0);
	float t = TIME * fog_speed;
	// deformación del dominio: los bancos cambian de forma mientras derivan
	vec2 w = vec2(fbm3(p * 0.6 + vec2(t * 0.05, 0.0)), fbm3(p * 0.6 + vec2(5.2, t * 0.04)));
	float a = fbm3(p + w * 1.6 + vec2(t * 0.14, 0.0));
	float b = fbm3(p * 1.7 - w * 1.0 + vec2(t * 0.09, 0.0) + 11.3);
	float n = a * 0.6 + b * 0.4;                           // ~0.5 de media
	// el ruido de gradiente varía poco: se estira para que los bancos se lean
	float s = clamp((n - 0.5) * 5.0, -1.0, 1.0);
	float k = density * fog_strength;
	float lighten = smoothstep(0.0, 1.0, max(s, 0.0)) * 0.55 * k;   // jirones más claros
	float darken = smoothstep(0.0, 1.0, max(-s, 0.0)) * 0.35 * k;   // claros entre ellos
	COLOR = vec4(fog_color * lighten, darken);
}
