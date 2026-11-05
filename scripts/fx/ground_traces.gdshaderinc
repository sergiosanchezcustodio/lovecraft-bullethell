// Rastros que se quedan (hito 17.20, GroundTraces): una textura que cubre la arena, a 1/8 m por
// píxel, con el icor, la ceniza y lo quemado de todo el nivel. La leen los suelos.
uniform sampler2D trace_tex : filter_nearest, repeat_disable;
uniform vec2 trace_origin = vec2(0.0);
uniform float trace_extent = 0.0;              // m que cubre (0: sin rastros)
const float TRACE_MAX = 0.62;                  // lo más que tapa el suelo (GroundTraces.MAX_A)

vec4 trace_at(vec2 xz) {
	if (trace_extent <= 0.0) return vec4(0.0);
	vec2 uv = (xz - trace_origin) / trace_extent;
	if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) return vec4(0.0);
	vec4 t = texture(trace_tex, uv);
	return vec4(t.rgb, min(t.a, TRACE_MAX));
}
