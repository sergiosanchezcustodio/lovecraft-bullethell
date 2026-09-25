// Bancos de niebla que derivan despacio por el valle (FogVolume de la portada).
// Más densa abajo y deshilachada por un ruido 3D que se desplaza con el tiempo.
shader_type fog;

uniform float density = 0.12;
uniform vec3 albedo : source_color = vec3(0.72, 0.78, 0.86);
uniform vec3 drift = vec3(0.35, 0.0, 0.12);   // m/s
uniform float scale = 0.045;

float hash(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float noise(vec3 p) {
	vec3 i = floor(p); vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1, 0, 0)), f.x), mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x), mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

void fog() {
	vec3 p = (WORLD_POSITION - drift * TIME) * scale;
	float n = noise(p) * 0.6 + noise(p * 2.1 + 3.7) * 0.3 + noise(p * 4.3) * 0.1;
	float banks = smoothstep(0.42, 0.78, n);
	float low = 1.0 - smoothstep(0.0, 1.0, UVW.y);          // se aclara hacia arriba
	DENSITY = density * banks * low * low;
	ALBEDO = albedo;
}
