// Páginas del pergamino del escritorio que se levantan con la ráfaga (TitleGust): el rectángulo
// copia la ilustración desplazando hacia arriba solo los píxeles de papel (claros y cálidos),
// más cuanto más cerca del borde de arriba, con un temblor que recorre la hoja; el papel alzado
// coge algo más de luz de la vela.
shader_type canvas_item;

uniform sampler2D art : filter_linear_mipmap;
uniform vec2 design = vec2(1920.0, 1080.0);
uniform vec4 rect;                 // x, y, ancho, alto del rectángulo (px de 1920×1080)
uniform float top_y = 860.0;       // borde de arriba del papel (lo que más se levanta)
uniform float bottom_y = 905.0;    // borde que queda sujeto
uniform float lift = 0.0;          // px que sube el borde de arriba
uniform float time = 0.0;

float paper(vec3 c) {
	float l = dot(c, vec3(0.3, 0.55, 0.15));
	return smoothstep(0.22, 0.36, l) * step(c.b, c.r);
}

void fragment() {
	vec2 p = rect.xy + UV * rect.zw;
	float w = 1.0 - smoothstep(top_y, bottom_y, p.y);
	float flutter = 0.65 + 0.35 * sin(p.x * 0.045 - time * 14.0) + 0.15 * sin(p.x * 0.11 + time * 23.0);
	float dy = lift * w * flutter;
	vec3 src = texture(art, (p + vec2(0.0, dy)) / design).rgb;
	vec3 orig = texture(art, p / design).rgb;
	float m = paper(src) * step(0.5, lift);
	vec3 c = src * (1.0 + 0.3 * w * clamp(lift / 8.0, 0.0, 1.0));
	// sombra bajo el borde alzado: donde ya no hay papel encima pero sí lo había
	float under = paper(orig) * (1.0 - m) * clamp(lift / 6.0, 0.0, 1.0);
	COLOR = vec4(mix(orig * 0.55, c, m), max(m, under * 0.8));
}
