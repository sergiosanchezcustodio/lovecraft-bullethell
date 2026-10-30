shader_type canvas_item;
// Viñeta del modo foto (hito 13.12): oscurece los bordes, más en las esquinas.

uniform float strength = 0.45;
uniform float aspect = 1.7778;

void fragment() {
	vec2 p = (UV - 0.5) * vec2(aspect, 1.0);
	float d = length(p) / length(vec2(aspect, 1.0) * 0.5);
	float v = smoothstep(0.45, 1.05, d);
	COLOR = vec4(0.0, 0.0, 0.0, v * strength);
}
