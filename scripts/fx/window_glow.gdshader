// Ventanas que se encienden y se apagan solas (ambiente de los escenarios, 16-10-2026). Capa de
// los voxels con glow 2: VoxelBuilder numera cada ventana en UV.x. Cada una, en cada casa (la
// posición de la pieza cambia la suerte), pasa por turnos de 20-40 s encendida o apagada; al
// encenderse titubea como una lámpara que prende y, encendida, oscila un poco.
// Siluetas (hito 17.16): de vez en cuando, en una encendida, alguien a contraluz se asoma desde
// un lado, se queda mirando y se va, o se corre la cortina y vuelve. VoxelBuilder da en UV.y el
// ancho de la ventana y en UV2 dónde cae cada vértice dentro de ella, en voxels.
shader_type spatial;
render_mode unshaded;

uniform bool colors_srgb = true;
uniform float on_share = 0.35;                 // parte de las ventanas encendidas a la vez
uniform float period_min = 20.0;
uniform float period_max = 40.0;
uniform vec3 off_color : source_color = vec3(0.045, 0.05, 0.06);
// alguien vigila (16-10-2026, Ambient): si un jugador pasa cerca de una ventana encendida, casi
// todas se apagan de golpe y vuelven a encenderse cuando se ha ido
uniform int watch_n = 0;
uniform vec4 watch_pos[4];                   // xz del jugador
uniform float watch_r = 8.0;
uniform float figure_share = 0.16;           // de cada turno de `figure_period` s, en cuántos pasa algo
uniform float figure_period = 9.0;

varying float lit;
varying float fig_x;                          // voxels: centro de quien se asoma, o borde de la cortina
varying float fig_mode;                       // 0 nada, 1 alguien, 2 cortina

// hash sin senos: con sin() de argumentos de miles, en la GPU casi todas salían encendidas
float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float state(vec2 seed, float slot) { return step(hash(seed + vec2(slot * 1.37, 0.5)), on_share); }

void vertex() {
	if (colors_srgb) {
		COLOR.rgb = mix(pow((COLOR.rgb + vec3(0.055)) * (1.0 / 1.055), vec3(2.4)), COLOR.rgb * (1.0 / 12.92), lessThan(COLOR.rgb, vec3(0.04045)));
	}
	vec2 seed = vec2(UV.x * 7.13, dot(NODE_POSITION_WORLD.xz, vec2(0.37, 0.71)));
	vec2 wxz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;            // la propia ventana (el origen de la casa queda lejos)
	float h0 = hash(seed);
	float period = mix(period_min, period_max, hash(seed + 3.1));
	float tt = TIME + h0 * period * 7.0;
	float slot = floor(tt / period);
	float u = tt - slot * period;                 // s desde el último cambio
	float now = state(seed, slot);
	float before = state(seed, slot - 1.0);
	lit = now;
	if (now != before && u < 1.1) {
		if (now > before) {                       // prende: dos o tres titubeos y se asienta
			float f = step(0.5, hash(vec2(floor(u * 14.0), h0)));
			lit = u < 0.7 ? f * smoothstep(0.0, 0.7, u) + 0.15 : 1.0;
		} else {
			lit = 1.0 - smoothstep(0.0, 0.5, u);  // se apaga en medio segundo
		}
	}
	lit *= 0.93 + 0.07 * sin(TIME * 5.3 + h0 * 40.0) * sin(TIME * 2.1 + h0 * 13.0);
	fig_mode = 0.0;
	fig_x = 0.0;
	float ft = TIME + h0 * 53.0;
	float fslot = floor(ft / figure_period);
	float fu = ft - fslot * figure_period;
	float width = UV.y;
	if (lit > 0.8 && width >= 6.0 && hash(seed + vec2(fslot * 2.31, 4.7)) < figure_share) {
		float kind = hash(seed + vec2(fslot * 1.7, 8.1));
		float side = step(0.5, hash(seed + vec2(fslot, 2.9)));             // por dónde entra
		if (kind < 0.65 && fu < 5.0) {                                     // alguien se asoma
			float off = mix(-8.0, width + 8.0, side);
			float stop = width * mix(0.3, 0.7, hash(seed + vec2(fslot, 5.3)));
			float out_to = kind < 0.35 ? off : mix(width + 8.0, -8.0, side);   // vuelve o sigue
			float a = smoothstep(0.0, 1.3, fu);
			float b = smoothstep(3.4, 5.0, fu);
			fig_x = mix(mix(off, stop, a), out_to, b);
			fig_mode = 1.0;
		} else if (kind >= 0.65 && fu < 4.0) {                             // la cortina
			float k = sin(clamp(fu / 4.0, 0.0, 1.0) * 3.14159);
			fig_x = mix(-1.0, width * 0.55, k) + sin(fu * 6.0) * 0.8 * k;
			fig_mode = 2.0 + side;                                         // 2 desde la izquierda, 3 desde la derecha
		}
	}
	if (hash(seed + 9.7) < 0.8) {                  // casi todas: que se note
		for (int i = 0; i < 4; i++) {
			if (i >= watch_n) break;
			if (length(wxz - watch_pos[i].xy) < watch_r) lit = 0.0;
		}
	}
}

void fragment() {
	vec3 c = COLOR.rgb * 1.25;
	if (fig_mode > 0.5) {
		vec2 q = floor(UV2) + 0.5;                                         // el voxel
		float shade = 0.0;
		if (fig_mode < 1.5) {                                              // hombros y cabeza, a contraluz
			float dx = q.x - fig_x;
			float body = step(q.y, 8.5) * step(abs(dx), 7.0 - max(q.y - 5.5, 0.0) * 1.2);
			float neck = step(q.y, 10.5) * step(abs(dx), 1.6);
			float head = step(length(vec2(dx, (q.y - 12.5) * 0.9)), 3.4);
			shade = max(max(body, neck), head) * 0.88;
		} else {                                                           // cortina con pliegues
			float u = fig_mode < 2.5 ? q.x : UV.y - q.x;
			shade = step(u, fig_x) * (0.45 + 0.2 * step(1.0, mod(q.x + floor(q.y * 0.25), 3.0)));
		}
		c *= 1.0 - shade;
	}
	ALBEDO = mix(off_color, c, clamp(lit, 0.0, 1.0));
}
