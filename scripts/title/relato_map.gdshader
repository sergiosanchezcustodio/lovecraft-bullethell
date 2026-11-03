// Mapa del nivel en el relato (hito 16.35): asoma bajo el cielo, fundido por arriba y por los lados.
shader_type canvas_item;

uniform float top0 = 0.16;
uniform float top1 = 0.5;
uniform float side = 0.09;

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float a = smoothstep(top0, top1, UV.y) * smoothstep(0.0, side, UV.x) * smoothstep(1.0, 1.0 - side, UV.x);
	COLOR = vec4(c.rgb, c.a * a);
}
