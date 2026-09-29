// Anillo del jugador derribado (hito 2.10), en el suelo: el borde rojo es el tiempo que le
// queda antes de quedar eliminado (se va comiendo en el sentido de las agujas del reloj) y
// el relleno verde crece desde el centro con la reanimación de un compañero.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform float bleed = 1.0;              // tiempo que queda (1 lleno, 0 agotado)
uniform float revive = 0.0;             // avance de la reanimación (0..1)
uniform vec3 bleed_color : source_color = vec3(0.95, 0.25, 0.2);
uniform vec3 revive_color : source_color = vec3(0.45, 1.0, 0.45);
uniform float exposure_comp = 0.6;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float a = fract(atan(p.x, -p.y) / 6.2831853 + 1.0);             // 0 arriba, en sentido horario
	float ring = smoothstep(0.8, 0.84, r) * smoothstep(1.0, 0.96, r);
	float lit = step(a, bleed);
	float fill = smoothstep(revive * 0.78 + 0.02, revive * 0.78 - 0.02, r) * step(0.001, revive);
	vec3 col = mix(vec3(0.15), bleed_color, lit) * ring + revive_color * fill;
	ALBEDO = col * exposure_comp;
	ALPHA = max(ring * (0.35 + 0.55 * lit), fill * 0.55);
}
