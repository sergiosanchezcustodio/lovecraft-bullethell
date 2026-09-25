// Balas: cuadrado orientado a la cámara, dibujado por encima de todo (legibilidad).
// Lenguaje visual de los daños (GDD 4.4): se distinguen por forma y color.
//   0 jugador: trazadora dorada alargada en la dirección del disparo, translúcida:
//     no se confunde con las balas enemigas, que son redondas.
//   1 físico: núcleo hueso, borde rojo anaranjado, contorno oscuro. Sólido y quieto.
//   2 mental: anillo violeta que ondula y gira, núcleo lila tenue.
//   3 mixto: núcleo físico dentro de un anillo mental.
// INSTANCE_CUSTOM: x = estilo, y = fase (en las del jugador, el rumbo en radianes),
// z = edad (s), w = radio visual (m).
// Los colores se multiplican por `exposure_comp`: el tonemapper (ACES, exposición 1,6)
// también procesa lo que no se ilumina y quemaría el violeta hasta el blanco.
shader_type spatial;
render_mode unshaded, blend_mix, depth_test_disabled, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec3 core_color : source_color = vec3(1.0, 0.95, 0.85);
uniform vec3 physical_color : source_color = vec3(1.0, 0.36, 0.18);
uniform vec3 mental_color : source_color = vec3(0.72, 0.36, 1.0);
uniform vec3 player_color : source_color = vec3(1.0, 0.8, 0.35);
uniform vec3 outline_color : source_color = vec3(0.05, 0.02, 0.04);
uniform float exposure_comp = 0.55;

varying flat float v_style;
varying float v_phase;

void vertex() {
	float s = length(MODEL_MATRIX[0].xyz);
	s *= mix(0.45, 1.0, smoothstep(0.0, 0.09, INSTANCE_CUSTOM.z));   // aparecen creciendo
	v_style = INSTANCE_CUSTOM.x;
	v_phase = INSTANCE_CUSTOM.y;
	// Cuadrado en el plano de la vista, centrado en la bala. Se calcula POSITION en todos
	// los casos: si una rama lo escribe y otra no, Godot deja la otra sin posición.
	vec3 center = (VIEW_MATRIX * vec4(MODEL_MATRIX[3].xyz, 1.0)).xyz;
	vec2 off = VERTEX.xy * s;
	if (int(v_style + 0.5) == 0) {
		// Trazadora: se alarga en pantalla a lo largo de su rumbo
		vec2 dir = normalize((VIEW_MATRIX * vec4(sin(v_phase), 0.0, cos(v_phase), 0.0)).xy + vec2(1e-5));
		vec2 perp = vec2(-dir.y, dir.x);
		off = dir * VERTEX.x * s * 2.6 + perp * VERTEX.y * s * 0.7;
	}
	POSITION = PROJECTION_MATRIX * vec4(center + vec3(off, 0.0), 1.0);
}

// Anillo que ondula alrededor de un radio base.
float wavy_ring(vec2 p, float base, float amp, float width) {
	float a = atan(p.y, p.x);
	float rw = base + amp * sin(a * 5.0 + TIME * 7.0 + v_phase * 6.0);
	return smoothstep(width, width * 0.35, abs(length(p) - rw));
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	vec3 col = vec3(0.0);
	float alpha = 0.0;
	int style = int(v_style + 0.5);
	if (style == 0) {
		// cabeza brillante delante (UV.x alto) y estela que se desvanece detrás
		float along = UV.x;
		float across = abs(UV.y * 2.0 - 1.0);
		alpha = smoothstep(1.0, 0.35, across) * smoothstep(0.0, 0.75, along) * 0.8;
		col = mix(player_color * exposure_comp * 1.3, vec3(1.0, 0.95, 0.8) * 0.9, smoothstep(0.7, 0.95, along) * (1.0 - across));
	} else if (style == 1) {
		alpha = smoothstep(0.97, 0.9, r);
		col = r < 0.48 ? core_color * 0.85 : (r < 0.8 ? physical_color * exposure_comp : outline_color);
	} else if (style == 2) {
		float ring = wavy_ring(p, 0.62, 0.1, 0.16);
		float edge = wavy_ring(p, 0.62, 0.1, 0.27);                  // contorno oscuro del anillo
		float core = smoothstep(0.3, 0.12, r);
		alpha = max(max(ring, edge * 0.9), core * 0.8);
		col = mix(outline_color, mental_color * exposure_comp, ring);
		col = mix(col, mental_color * exposure_comp * 0.6, core * (1.0 - ring));
	} else {
		float ring = wavy_ring(p, 0.74, 0.08, 0.12);
		float edge = wavy_ring(p, 0.74, 0.08, 0.2);
		float solid = smoothstep(0.58, 0.52, r);
		alpha = max(max(ring, edge * 0.9), solid);
		col = r < 0.3 ? core_color * 0.85 : (r < 0.52 ? physical_color * exposure_comp : outline_color);
		col = mix(col, mental_color * exposure_comp, ring * (1.0 - solid));
	}
	if (alpha < 0.01) discard;
	ALBEDO = col;
	ALPHA = alpha;
}
