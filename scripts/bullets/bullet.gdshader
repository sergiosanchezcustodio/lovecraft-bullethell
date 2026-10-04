// Balas: cuadrado orientado a la cámara, dibujado por encima de todo (legibilidad).
// Lenguaje visual de los daños (GDD 4.4): se distinguen por forma y color.
//   0 jugador: trazadora dorada alargada en la dirección del disparo, translúcida:
//     no se confunde con las balas enemigas, que son redondas.
//   1 físico: núcleo hueso, borde rojo anaranjado, contorno oscuro. Sólido y quieto.
//   2 mental: anillo violeta que ondula y gira, núcleo lila tenue.
//   3 mixto: núcleo físico dentro de un anillo mental.
//   4 fuego fatuo (Báculo del Farolero) y 5 Rayo de Yith: trazadoras del jugador, verde
//     pálido y turquesa.
//   Aspectos de las balas del jugador (04-10-2026, WeaponData.bullet_look): 0 trazadora
//   pesada con halo (pistolas), 6 perdigón incandescente, 7 estela larga de rifle, 8
//   trazadora corta que parpadea, 9 hoja que gira (bisturís), 10 chispa de colores, 11 arpón,
//   12 dardo verde. 13: destello de impacto (y = aspecto de la bala, z = vida de 0 a 1).
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
uniform vec3 wisp_color : source_color = vec3(0.55, 1.0, 0.6);
uniform vec3 yith_color : source_color = vec3(0.3, 0.95, 0.95);
uniform vec3 outline_color : source_color = vec3(0.05, 0.02, 0.04);
uniform float exposure_comp = 0.55;

varying flat float v_style;
varying float v_phase;
varying float v_age;

void vertex() {
	float s = length(MODEL_MATRIX[0].xyz);
	s *= mix(0.45, 1.0, smoothstep(0.0, 0.09, INSTANCE_CUSTOM.z));   // aparecen creciendo
	v_style = INSTANCE_CUSTOM.x;
	v_phase = INSTANCE_CUSTOM.y;
	v_age = INSTANCE_CUSTOM.z;
	// Cuadrado en el plano de la vista, centrado en la bala. Se calcula POSITION en todos
	// los casos: si una rama lo escribe y otra no, Godot deja la otra sin posición.
	vec3 center = (VIEW_MATRIX * vec4(MODEL_MATRIX[3].xyz, 1.0)).xyz;
	vec2 off = VERTEX.xy * s;
	int st = int(v_style + 0.5);
	if (st == 13) {
		s = length(MODEL_MATRIX[0].xyz) * (0.6 + 0.9 * INSTANCE_CUSTOM.z);      // el destello crece
		off = VERTEX.xy * s;
	} else if (st == 9 || st == 10) {
		// hoja y chispa: cuadrado que gira (la hoja, rápido)
		float a = TIME * (st == 9 ? 22.0 : 6.0) + v_phase * 3.0;
		vec2 dir = vec2(cos(a), sin(a));
		off = dir * VERTEX.x * s * 1.3 + vec2(-dir.y, dir.x) * VERTEX.y * s * 1.3;
	} else if (st == 0 || st >= 4) {
		// Trazadora: se alarga en pantalla a lo largo de su rumbo, más o menos según el arma
		vec2 dir = normalize((VIEW_MATRIX * vec4(sin(v_phase), 0.0, cos(v_phase), 0.0)).xy + vec2(1e-5));
		vec2 perp = vec2(-dir.y, dir.x);
		float L = st == 7 ? 5.5 : (st == 11 ? 3.0 : (st == 6 ? 1.5 : (st == 8 ? 2.2 : (st == 12 ? 2.6 : (st == 0 ? 3.2 : 2.6)))));
		float W = st == 7 ? 0.45 : (st == 11 ? 0.4 : (st == 6 ? 0.85 : (st == 8 ? 0.6 : (st == 12 ? 0.5 : (st == 0 ? 0.95 : 0.7)))));
		off = dir * VERTEX.x * s * L + perp * VERTEX.y * s * W;
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
	float along = UV.x;                                   // 0 cola, 1 cabeza
	float across = abs(UV.y * 2.0 - 1.0);
	if (style == 13) {
		// impacto: estrella de cuatro puntas y anillo que se abre y se apaga
		float life = clamp(v_age, 0.0, 1.0);
		int look = int(v_phase + 0.5);
		vec3 tint = look == 6 ? vec3(1.0, 0.55, 0.2) : (look == 12 ? vec3(0.5, 1.0, 0.45) : (look == 9 ? vec3(0.85, 0.9, 1.0) : (look == 4 ? wisp_color : (look == 5 ? yith_color : player_color))));
		float star = max(smoothstep(0.16, 0.0, abs(p.x)) * smoothstep(1.0, 0.0, abs(p.y)), smoothstep(0.16, 0.0, abs(p.y)) * smoothstep(1.0, 0.0, abs(p.x)));
		float ring = smoothstep(0.12, 0.0, abs(r - (0.35 + 0.55 * life)));
		float fade = 1.0 - life;
		alpha = max(star * fade * 1.2, ring * fade * 0.8) * step(r, 1.0);
		col = mix(tint * exposure_comp * 1.6, vec3(1.0, 0.97, 0.9), star * 0.6);
	} else if (style == 6) {
		// perdigón: brasa con núcleo blanco y cola corta naranja
		float body = smoothstep(1.0, 0.4, across) * smoothstep(0.0, 0.6, along);
		alpha = body * 0.95;
		col = mix(vec3(1.0, 0.35, 0.08) * exposure_comp * 1.6, vec3(1.0, 0.95, 0.8), smoothstep(0.55, 0.95, along) * (1.0 - across));
	} else if (style == 7) {
		// rifle: estela larga y muy fina, blanca azulada, que se desvanece lejos
		alpha = smoothstep(1.0, 0.2, across) * pow(along, 1.6) * 0.95;
		col = mix(vec3(0.6, 0.8, 1.0) * exposure_comp * 1.4, vec3(1.0), smoothstep(0.8, 1.0, along));
	} else if (style == 8) {
		// subfusil: trazadora corta amarilla que parpadea
		float flick = 0.75 + 0.25 * sin(TIME * 60.0 + v_phase * 17.0);
		alpha = smoothstep(1.0, 0.35, across) * smoothstep(0.1, 0.7, along) * flick;
		col = mix(vec3(1.0, 0.85, 0.2) * exposure_comp * 1.5, vec3(1.0, 0.98, 0.85), smoothstep(0.75, 1.0, along));
	} else if (style == 9) {
		// bisturí: rombo plateado fino con filo brillante
		float d = abs(p.x) * 0.35 + abs(p.y) * 1.6;
		alpha = smoothstep(1.0, 0.85, d);
		col = mix(vec3(0.55, 0.6, 0.68), vec3(1.0), smoothstep(0.3, 0.0, abs(p.y)));
	} else if (style == 10) {
		// chispa: estrella de colores que cambia de tono
		vec3 hue = 0.55 + 0.45 * cos(6.2831 * (vec3(0.0, 0.33, 0.67) + v_phase * 0.3 + TIME * 1.5));
		float star = max(smoothstep(0.22, 0.0, abs(p.x)) * smoothstep(1.0, 0.1, abs(p.y)), smoothstep(0.22, 0.0, abs(p.y)) * smoothstep(1.0, 0.1, abs(p.x)));
		float core = smoothstep(0.45, 0.0, r);
		alpha = max(star, core);
		col = mix(hue * exposure_comp * 1.6, vec3(1.0), core * 0.7);
	} else if (style == 11) {
		// arpón: asta de madera y punta de metal en la cabeza, sin estela
		float shaft = smoothstep(0.45, 0.25, across) * step(along, 0.82);
		float head = smoothstep(1.0, 0.0, across - (1.0 - (along - 0.8) / 0.2)) * step(0.78, along);
		alpha = max(shaft, head);
		col = head > shaft ? vec3(0.75, 0.78, 0.8) : vec3(0.42, 0.28, 0.16);
	} else if (style == 12) {
		// dardo de West: cuerpo de cristal verde con aguja clara delante
		float body = smoothstep(0.7, 0.4, across) * smoothstep(0.1, 0.25, along) * step(along, 0.78);
		float needle = smoothstep(0.25, 0.0, across) * step(0.75, along);
		alpha = max(body * 0.95, needle);
		col = needle > body ? vec3(0.9, 0.95, 0.9) : vec3(0.35, 1.0, 0.4) * exposure_comp * 1.5;
	} else if (style == 0) {
		// trazadora pesada: cabeza blanca, cuerpo dorado y halo suave alrededor
		float core = smoothstep(0.55, 0.15, across) * smoothstep(0.0, 0.8, along);
		float halo = smoothstep(1.0, 0.3, across) * smoothstep(0.2, 0.9, along) * 0.45;
		alpha = max(core, halo);
		col = mix(player_color * exposure_comp * 1.3, vec3(1.0, 0.97, 0.88), smoothstep(0.7, 0.98, along) * (1.0 - across));
		col = mix(player_color * exposure_comp * 0.9, col, core);
	} else if (style >= 4) {
		// cabeza brillante delante (UV.x alto) y estela que se desvanece detrás
		alpha = smoothstep(1.0, 0.35, across) * smoothstep(0.0, 0.75, along) * 0.8;
		vec3 pc = style == 4 ? wisp_color : (style == 5 ? yith_color : player_color);
		col = mix(pc * exposure_comp * 1.3, vec3(1.0, 0.95, 0.8) * 0.9, smoothstep(0.7, 0.95, along) * (1.0 - across));
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
