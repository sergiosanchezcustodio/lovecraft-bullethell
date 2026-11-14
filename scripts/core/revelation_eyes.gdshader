// Ojos en la oscuridad (hito 21.7, Revelations): dos ojos por enemigo cercano, de cara a la cámara y
// por encima de todo (también del decorado que lo tape). INSTANCE_CUSTOM: x, la fase de su latido; y, el
// brillo (de espaldas, apagados).
shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, shadows_disabled, blend_add;

uniform vec4 color : source_color = vec4(1.0, 0.32, 0.25, 1.0);

varying float phase;
varying float bright;

void vertex() {
	phase = INSTANCE_CUSTOM.x;
	bright = INSTANCE_CUSTOM.y;
}

void fragment() {
	// a bloques: un núcleo de 2×1 casi blanco y el resto del color, que late despacio
	vec2 c = floor(UV * vec2(4.0, 3.0));
	bool core = (c.x == 1.0 || c.x == 2.0) && c.y == 1.0;
	float pulse = 0.75 + 0.25 * sin(TIME * 3.0 + phase);
	float blink = step(0.04, fract(TIME * 0.23 + phase * 0.11));   // parpadeo de vez en cuando
	ALBEDO = (core ? mix(color.rgb, vec3(1.0), 0.6) * 1.6 : color.rgb * 1.2) * pulse * blink * bright;
}
