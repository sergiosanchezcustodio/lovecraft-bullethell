shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
// Manchas animadas del suelo en celdas de voxel (11-10-2026): fuego del Molotov, charco del
// lanzaquímicos y quemado de las explosiones. Antes eran discos lisos de un color.
// Plano 2×2 escalado por el radio: la forma sale del UV; el ruido, del mundo (no se desliza).
// mode 0 fuego: brasas que laten y lenguas que corren; 1 ácido: líquido con brillos que se
// mueven, borde más oscuro y burbujas que se hinchan y revientan; 2 quemado: mancha negra
// irregular con brasas que se enfrían con `age` (0..1); 3 onda: anillo de celdas con runas
// que se abre (`wave_r`, 0..1, color `tint`); 4 gas: nubes turbias que derivan; 5 polvo: tierra
// dorada con motas que destellan; 6 salpicadura: mancha del color `tint` con gotas
// alrededor, que se seca y aclara con `age`; 7 signo: anillos con runas que giran y estrella
// de cinco puntas (color `tint`, aparece con `age`); 8 tajo: barrido circular con estela
// (`age` = avance del giro, 0..1).

uniform int mode = 0;
uniform float fade = 1.0;
uniform float age = 0.0;
uniform float seed = 0.0;
uniform float cell = 0.0625;
uniform float wave_r = 0.0;
uniform vec3 tint : source_color = vec3(1.0, 0.84, 0.46);

varying vec3 wpos;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
vec2 grad(vec2 i) { float a = hash(i) * 6.2831853; return vec2(cos(a), sin(a)); }
float gnoise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = dot(grad(i), f), b = dot(grad(i + vec2(1, 0)), f - vec2(1, 0));
	float c = dot(grad(i + vec2(0, 1)), f - vec2(0, 1)), d = dot(grad(i + vec2(1, 1)), f - vec2(1, 1));
	return 0.5 + 0.75 * mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}
float fbm(vec2 p) {
	return gnoise(p) * 0.6 + gnoise(p * 2.1 + 7.3) * 0.3 + gnoise(p * 4.3 + 1.7) * 0.1;
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// celda de voxel en el mundo y su centro en coordenadas del plano (-1..1)
	vec2 c = floor(wpos.xz / cell);
	vec2 cw = (c + 0.5) * cell;
	vec2 q = (cw - NODE_POSITION_WORLD.xz) / length(MODEL_MATRIX[0].xyz);
	float r = length(q);
	vec2 n = cw + seed * 17.0;
	// borde irregular: el radio cambia con el ángulo y con el ruido
	if (mode == 3) {
		// onda: banda de celdas en el radio `ring`, con un frente brillante, runas que
		// parpadean dentro de la banda y una estela tenue detrás
		float ang = atan(q.y, q.x);
		float band = wave_r - r;                             // >0 detrás del frente
		if (band < -0.02 || band > 0.32 || r > 1.0) discard;
		float front = step(band, 0.06);
		float rune = step(0.7, hash(vec2(floor(ang * 18.0 / 6.2831853 * 6.0), floor(r * 14.0)) + seed))
			* step(0.06, band) * step(band, 0.2);
		float trail = 1.0 - band / 0.32;
		vec3 col = tint * (0.35 + 0.65 * front) + tint * rune * 0.5;
		ALBEDO = col * 0.7;
		EMISSION = tint * (front * 0.9 + rune * 0.6);
		ALPHA = clamp(front + rune * 0.8 + trail * 0.25, 0.0, 1.0) * fade;
	} else if (mode == 7) {
		if (r > 1.0) discard;
		float ang = atan(q.y, q.x);
		float t7 = TIME;
		float outer = step(0.9, r) * step(r, 0.99);
		float inner = step(0.7, r) * step(r, 0.75);
		// runas: 20 casillas en la corona que gira, cada una con su dibujo de 3×2 bloques
		float ra = ang + t7 * 0.35;
		float seg = floor(ra / 6.2831853 * 20.0);
		float fa = fract(ra / 6.2831853 * 20.0);
		float fr = (r - 0.76) / 0.13;
		vec2 blk = floor(vec2(fa * 3.0, fr * 2.0));
		float rune = step(0.45, hash(blk + seg * 7.0 + seed)) * step(0.15, fa) * step(fa, 0.85)
			* step(0.0, fr) * step(fr, 1.0);
		// estrella de cinco puntas que gira al revés
		float star = 0.0;
		for (int i = 0; i < 5; i++) {
			float a0 = -t7 * 0.25 + float(i) * 2.5132741;
			float a1 = a0 + 2.5132741 * 2.0;
			vec2 p0 = vec2(cos(a0), sin(a0)) * 0.7, p1 = vec2(cos(a1), sin(a1)) * 0.7;
			vec2 pa = q - p0, ba = p1 - p0;
			float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
			star = max(star, step(length(pa - ba * h), 0.035));
		}
		float pulse = 0.8 + 0.2 * sin(t7 * 4.0);
		float on = clamp(age * 4.0, 0.0, 1.0);
		float lines = max(max(outer, inner), max(rune, star));
		ALBEDO = tint * (0.25 + 0.55 * lines);
		EMISSION = tint * lines * pulse * 0.9;
		ALPHA = (lines * 0.95 + 0.12) * on * fade;
	} else if (mode == 8) {
		// tajo: corona que barre una vuelta; la cabeza es casi blanca y la estela se apaga
		if (r > 1.0 || r < 0.5) discard;
		float ang = mod(atan(q.y, q.x) + 6.2831853, 6.2831853);
		float head = age * 6.2831853 * 1.15;
		float behind = head - ang;
		if (behind < 0.0) behind += 6.2831853 * step(6.2831853, head);
		float trail = 1.0 - behind / 2.6;
		if (behind < 0.0 || trail <= 0.0) discard;
		float band = 1.0 - abs(r - 0.78) / 0.22;
		float streak = step(0.35, hash(vec2(floor(ang * 30.0), floor(r * 10.0)) + seed));
		float edge8 = step(behind, 0.25);
		float k = trail * band * mix(0.55, 1.0, streak);
		vec3 col8 = mix(tint, vec3(1.0), edge8 * 0.7);
		ALBEDO = col8 * 0.75;
		EMISSION = col8 * k * 1.2;
		ALPHA = clamp(k * 1.6 + edge8 * band, 0.0, 1.0) * fade;
	} else {
	float edge = 0.78 + 0.22 * fbm(n * 0.9);
	if (mode == 6) {                                   // salpicadura: núcleo más pequeño y gotas sueltas
		edge = 0.45 + 0.35 * fbm(n * 1.4);
		float drop = step(0.975, hash(floor(c / 2.0) + seed)) * step(r, 0.95) * step(0.5, fbm(n * 0.7));
		edge = max(edge, r * drop + 0.001 * drop);
	}
	float inside = step(r, edge);
	if (inside < 0.5) discard;
	float rim = smoothstep(edge - 0.18, edge, r);          // 0 en el centro, 1 en el borde
	float t = TIME;
	vec3 col; float a; vec3 emi = vec3(0.0);
	float g = hash(c + seed);

	if (mode == 0) {
		// fuego: lecho de brasas; el calor corre hacia fuera y late por celdas
		float heat = fbm(n * 0.9 + vec2(t * 0.35, -t * 0.6)) + 0.12 * sin(t * 6.0 + fbm(n * 0.5) * 12.0) + 0.04 * g;
		heat = heat * (1.0 - rim * 0.7) - 0.05;
		heat = floor(heat * 6.0) / 6.0;                     // escalones, como los voxels
		vec3 coal = vec3(0.10, 0.04, 0.03);
		vec3 red = vec3(0.85, 0.18, 0.04);
		vec3 ora = vec3(1.0, 0.55, 0.10);
		vec3 yel = vec3(1.0, 0.88, 0.45);
		col = mix(coal, red, smoothstep(0.38, 0.58, heat));
		col = mix(col, ora, smoothstep(0.62, 0.8, heat));
		col = mix(col, yel, smoothstep(0.86, 1.0, heat));
		col *= 0.6;                                          // ACES 1,6 quema lo sin iluminar
		emi = col * smoothstep(0.45, 1.0, heat) * 0.9;
		a = mix(0.95, 0.7, rim);
	} else if (mode == 1) {
		// ácido: caldo verde oliva oscuro con vetas lima que brillan, franja luminosa junto
		// al borde corroído y burbujas que se hinchan y revientan
		float liq = fbm(n * 0.9 + vec2(t * 0.22, t * 0.15));
		float vein = 1.0 - abs(liq - 0.5) * 2.0;                 // vetas finas donde cruza 0,5
		vein = step(0.93, vein);
		col = mix(vec3(0.03, 0.07, 0.005), vec3(0.08, 0.17, 0.01), floor(liq * 4.0) / 4.0);
		vec3 lime = vec3(0.42, 0.75, 0.04);
		float fringe = step(edge - 0.2, r) * step(r, edge - 0.08);
		col = mix(col, lime * 0.55, max(vein, fringe) * 0.8);
		col = mix(col, vec3(0.02, 0.03, 0.01), step(edge - 0.08, r));   // borde quemado
		// burbujas: grupos de 6×6 celdas, cada uno con su fase
		vec2 b = floor(c / 6.0);
		vec2 bc = b * 6.0 + 3.0;
		float ph = fract(t * (0.45 + hash(b + 3.0) * 0.5) + hash(b + seed));
		float on = step(0.5, hash(b + 9.0 + floor(t * 0.45 + hash(b))));
		float br = length(c + 0.5 - bc);
		float size = ph * 3.0;
		float ring = step(br, size) * step(size - 1.0, br) * step(ph, 0.85);
		float fill = step(br, size - 1.0) * step(ph, 0.85) * 0.35;
		float pop = step(0.85, ph) * step(br, 3.2) * step(2.2, br);
		float bub = clamp(ring + fill + pop, 0.0, 1.0) * on * (1.0 - rim);
		col = mix(col, vec3(0.6, 0.9, 0.2) * 0.6, bub);
		emi = lime * (max(vein, fringe) * 0.3 + bub * 0.9) + col * 0.2;
		a = mix(0.95, 0.85, rim);
	} else if (mode == 4) {
		// gas de cloro: capas turbias amarillo verdosas que derivan, más densas en el centro
		float den = fbm(n * 0.6 + vec2(t * 0.3, t * 0.12));
		den = floor((den + 0.35 * (1.0 - rim)) * 4.0) / 4.0;
		col = mix(vec3(0.18, 0.2, 0.03), vec3(0.5, 0.56, 0.12), den) * 0.6;
		emi = col * 0.15;
		a = clamp(den * 0.85, 0.0, 0.8) * (1.0 - rim * 0.7);
	} else if (mode == 5) {
		// polvo de Ibn-Ghazi: tierra sepia a manchas con motas doradas que se encienden
		float sd = fbm(n * 1.1);
		col = mix(vec3(0.22, 0.13, 0.04), vec3(0.45, 0.3, 0.1), floor(sd * 4.0) / 4.0);
		float mote = step(0.93, hash(c + floor(t * 3.0 + g * 5.0)));
		col = mix(col, vec3(1.0, 0.82, 0.4) * 0.7, mote * (1.0 - rim));
		emi = vec3(1.0, 0.8, 0.35) * mote * (1.0 - rim) * 0.8;
		a = mix(0.85, 0.4, rim);
	} else if (mode == 6) {
		float wet = 1.0 - smoothstep(0.0, 0.8, age);
		col = tint * 0.6 * (0.8 + 0.25 * floor(fbm(n * 1.5) * 3.0) / 3.0);
		float shine = step(0.9, hash(c + 33.0)) * wet;
		col = mix(col, tint * 1.1 + 0.06, shine * 0.5);
		emi = vec3(0.0);
		a = mix(0.85, 0.6, rim) * (0.55 + 0.45 * wet);
	} else {
		// quemado: negro hollín irregular con brasas que se apagan
		float soot = fbm(n * 1.3);
		col = mix(vec3(0.02, 0.018, 0.015), vec3(0.12, 0.10, 0.08), floor(soot * 4.0) / 4.0 * rim);
		float ember = step(0.955 + age * 0.04, hash(c + 51.0)) * step(0.5, fbm(n * 0.8)) * (1.0 - rim);
		float cool = 1.0 - smoothstep(0.0, 0.6, age);
		vec3 ec = mix(vec3(0.9, 0.2, 0.03), vec3(1.0, 0.7, 0.25), hash(c + 7.0));
		float flick = 0.7 + 0.3 * sin(t * 11.0 + g * 30.0);
		col = mix(col, ec, ember * cool * flick);
		col *= 1.0 - 0.4 * ember * cool;
		emi = ec * ember * cool * flick * 0.8;
		a = mix(0.85, 0.35, rim);
	}
	ALBEDO = col * (0.94 + 0.08 * g);
	EMISSION = emi;
	ALPHA = a * fade;
	}
}
