// Aviso en el suelo: anillo exterior y relleno que crece hasta el momento del impacto.
// Parpadea en el último 20 %. Sin relleno (fill = false) es un anillo tenue fijo.
// En celdas de 1/16 m del mundo (11-10-2026), a juego con el voxel, con franjas diagonales
// que avanzan dentro del relleno; las manchas suaves (soft) siguen lisas.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec4 color : source_color = vec4(1.0, 0.36, 0.18, 0.7);
uniform float progress = 0.0;
uniform bool fill = true;
uniform float ring_width = 0.08;
uniform bool soft = false;              // disco difuminado sin anillo (manchas de quemado)

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	if (r > 1.0) discard;
	vec2 cell = floor(wpos.xz / 0.0625);
	if (!soft) {                                // celdas: el radio se mide desde el centro de la celda
		vec2 cw = (cell + 0.5) * 0.0625;        // (proporción con el punto real: vale escale la malla o el nodo)
		float dw = length(wpos.xz - NODE_POSITION_WORLD.xz);
		r = r * length(cw - NODE_POSITION_WORLD.xz) / max(dw, 1e-4);
		if (r > 1.0) discard;
	}
	if (soft) {
		ALBEDO = color.rgb;
		ALPHA = smoothstep(1.0, 0.25, r) * color.a;
	} else {
	float ring = smoothstep(1.0 - ring_width * 1.6, 1.0 - ring_width, r) * smoothstep(1.0, 1.0 - ring_width * 0.5, r);
	float stripe = step(0.5, fract((cell.x + cell.y) / 8.0 - TIME * 1.5));
	float inner = fill ? step(r, progress) * (0.3 + 0.16 * stripe) + step(abs(r - progress), 0.03) * 0.6 : 0.12;
	float blink = (fill && progress > 0.8) ? 0.55 + 0.45 * sin(TIME * 40.0) : 1.0;
	float a = max(ring, inner) * color.a * blink;
	if (a < 0.01) discard;
	ALBEDO = color.rgb * 0.85;      // algo por debajo de 1: el tonemapper aclara lo no iluminado
	ALPHA = a;
	}
}
