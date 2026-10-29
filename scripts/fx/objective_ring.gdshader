// Círculo de los objetivos a mitad de nivel (hito 13.5), en el suelo: un aro que late con
// runas que giran y, dentro, el avance (se llena en el sentido de las agujas del reloj, desde
// arriba). Sirve para el ritual que hay que cortar, la meta del rescate y la de la reliquia.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec3 color : source_color = vec3(0.65, 0.3, 1.0);
uniform float progress = 0.0;           // 0..1: el arco de avance
uniform float pulse = 1.0;              // brillo (late desde el script)
uniform float exposure_comp = 0.7;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float a = fract(atan(p.x, -p.y) / 6.2831853 + 1.0);              // 0 arriba, en sentido horario
	float ring = smoothstep(0.86, 0.9, r) * smoothstep(1.0, 0.96, r);
	// runas: marcas cortas entre dos aros, que giran despacio
	float ra = fract(a * 24.0 + TIME * 0.15);
	float runes = step(0.72, r) * step(r, 0.8) * step(0.3, ra) * step(ra, 0.62);
	float inner = smoothstep(0.66, 0.68, r) * smoothstep(0.72, 0.7, r);
	float arc = step(a, progress) * smoothstep(0.82, 0.84, r) * smoothstep(0.88, 0.86, r) * step(0.001, progress);
	float glow = (1.0 - smoothstep(0.0, 0.9, r)) * 0.08;
	float k = ring * 0.9 + runes * 0.55 + inner * 0.4 + glow;
	vec3 col = color * k * pulse + vec3(1.0, 0.92, 0.6) * arc * 1.4;
	ALBEDO = col * exposure_comp;
	ALPHA = 1.0;
}
