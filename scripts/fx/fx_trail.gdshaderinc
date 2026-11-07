// Estelas de las armas (FxTrails, hito 18.1): el color de cada punto llega en COLOR (su tramo,
// ya escalonado); a lo ancho, tres franjas: los bordes más tenues que el centro (UV.y de 0 a 1).
uniform float core = 0.4;
uniform float edge_alpha = 0.35;

void fragment() {
	float x = abs(UV.y * 2.0 - 1.0);
	ALBEDO = COLOR.rgb;
	ALPHA = COLOR.a * (x > core ? edge_alpha : 1.0);
}
