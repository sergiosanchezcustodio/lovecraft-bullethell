// Velo detrás de las ventanas de los menús (27-10-2026): oscurece más hacia los bordes, como si la
// única luz fuera la de la ventana.
shader_type canvas_item;

uniform float strength = 1.0;

void fragment() {
	vec2 q = (UV - 0.5) * vec2(1.6, 1.0);
	float v = smoothstep(0.15, 0.95, length(q));
	COLOR = vec4(0.004, 0.003, 0.006, mix(0.5, 0.88, v) * strength);
}
