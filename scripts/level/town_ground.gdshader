shader_type spatial;
// Suelos de la parte 2 (hito 6.0, 06-10-2026): tierra mojada con charcos, adoquín y tablas
// de muelle, en voxel fino como la nieve (snow_ground.gdshader, que no se toca): celdas de
// 1/32 m, todo por celda y en coordenadas del mundo, con el canto claro arriba a la
// izquierda y el oscuro abajo a la derecha, como los modelos.
// kind: 0 tierra (mud), 1 adoquín (cobble), 2 tablas (planks), 3 arrecife (reef, hito 6.5: roca
// negra mojada en escalones, algas, percebes y grietas con luz verde de abajo), 4 R'lyeh (fase 7:
// losas ciclópeas verdinegras cuya rejilla gira y se tuerce por zonas, así que los ángulos no
// cuadran; juntas con limo que brilla apenas). wet (0..1): lluvia; oscurece
// y abrillanta todo. Los charcos son brillo especular falso: sin reflejos reales.

uniform int kind = 0;
uniform float cell = 0.03125;
uniform float wet = 0.5;
uniform vec3 base_hi : source_color = vec3(0.36, 0.29, 0.21);   // tierra / piedra / madera clara
uniform vec3 base_lo : source_color = vec3(0.22, 0.17, 0.12);   // ... oscura
uniform vec3 joint : source_color = vec3(0.07, 0.07, 0.06);     // juntas, huecos y rodadas
uniform vec3 moss : source_color = vec3(0.20, 0.27, 0.15);      // verdín y matas
uniform vec3 puddle : source_color = vec3(0.10, 0.12, 0.14);
uniform vec3 edge_col : source_color = vec3(0.18, 0.15, 0.12);
uniform float stone = 0.25;                                     // tamaño del adoquín (m)
uniform float plank = 0.22;                                     // ancho de la tabla (m)
// carretera de tierra (solo en mud): punto, dirección y ancho (0: sin carretera), con dos rodadas
uniform vec2 road_p = vec2(0.0);
uniform vec2 road_d = vec2(1.0, 0.0);
uniform float road_w = 0.0;
uniform vec3 road_col : source_color = vec3(0.40, 0.34, 0.26);
// road_kind 1 (hito 6.4): terraplén de la vía, balasto de grava sin rodadas
uniform int road_kind = 0;
uniform vec3 ballast_hi : source_color = vec3(0.42, 0.40, 0.37);
uniform vec3 ballast_lo : source_color = vec3(0.24, 0.22, 0.20);
// agua somera del pantano (hito 6.4): la capa "water" del mapa de la arena (la misma que frena)
uniform sampler2D water_tex : filter_linear, repeat_disable;
uniform vec2 water_origin = vec2(-50.0);
uniform float water_extent = 0.0;            // 0: sin agua
uniform vec3 water_deep : source_color = vec3(0.13, 0.19, 0.21);
uniform vec3 water_shallow : source_color = vec3(0.27, 0.36, 0.37);
uniform vec3 duckweed : source_color = vec3(0.30, 0.38, 0.14);
uniform vec3 water_glow : source_color = vec3(0.0);            // luz que sube del agua (arrecife)
uniform vec3 crack_glow : source_color = vec3(0.25, 0.85, 0.45);  // grietas del arrecife
uniform vec3 barnacle : source_color = vec3(0.55, 0.55, 0.50);
// marisma (hito 6.1): más allá de x o z = marsh (0: sin marisma) todo se encharca
uniform float marsh = 0.0;
// muelle (hito 6.2): más allá de x o z = dock (0: sin muelle) el adoquín pasa a tablas
uniform float dock = 0.0;
uniform vec3 dock_hi : source_color = vec3(0.44, 0.38, 0.31);
uniform vec3 dock_lo : source_color = vec3(0.26, 0.22, 0.18);

varying vec3 wpos;
varying vec3 wnrm;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
vec2 grad(vec2 i) { float a = hash(i) * 6.2831853; return vec2(cos(a), sin(a)); }
float gnoise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	float a = dot(grad(i), f), b = dot(grad(i + vec2(1, 0)), f - vec2(1, 0));
	float c = dot(grad(i + vec2(0, 1)), f - vec2(0, 1)), d = dot(grad(i + vec2(1, 1)), f - vec2(1, 1));
	return 0.5 + 0.75 * mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}
float fbm(vec2 p) {
	float s = 0.0, a = 0.5;
	mat2 r = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
	for (int i = 0; i < 3; i++) { s += a * gnoise(p); p = r * p * 2.03; a *= 0.5; }
	return s * 1.14;
}

// --- adoquín: hileras desplazadas medio adoquín; cada uno con su tono y esquinas romas ---
// Devuelve (id del adoquín, distancia al borde en celdas, altura en escalones)
vec3 cobble_at(vec2 c) {
	vec2 p = (c + 0.5) * cell;
	float row = floor(p.y / stone);
	vec2 q = vec2(p.x / (stone * 1.15) + 0.5 * mod(row, 2.0), p.y / stone);
	vec2 id = floor(q);
	vec2 f = fract(q) - 0.5;
	vec2 e = (0.5 - abs(f)) * vec2(stone * 1.15, stone) / cell;   // a los bordes, en celdas
	float ed = min(e.x, e.y);
	float corner = 2.2 - length(max(vec2(2.2) - e, vec2(0.0)));     // esquinas romas
	ed = min(ed, corner);
	float h = ed < 1.0 ? 0.0 : 1.0 + step(2.5, ed) + floor(hash(id + 5.0) * 1.5);
	return vec3(hash(id), ed, h);
}

// --- tablas: a lo largo de x, de 1,5 a 3 m, con juntas al tope desplazadas ---
// Devuelve (id de la tabla, distancia al canto en celdas, altura)
vec3 plank_at(vec2 c) {
	vec2 p = (c + 0.5) * cell;
	float row = floor(p.y / plank);
	float len = 1.5 + hash(vec2(row, 3.0)) * 1.5;
	float x = p.x + hash(vec2(row, 9.0)) * 3.0;
	float col = floor(x / len);
	vec2 id = vec2(col, row);
	float ey = (0.5 - abs(fract(p.y / plank) - 0.5)) * plank / cell;
	float ex = (0.5 - abs(fract(x / len) - 0.5)) * len / cell;
	float ed = min(ey, ex);
	float h = ed < 1.0 ? -1.0 : 1.0 + floor(hash(id + 2.0) * 2.0);   // tablas combadas a distinta altura
	return vec3(hash(id), ed, h);
}

// --- arrecife: roca en escalones más bruscos, con grietas ---
float reef_h(vec2 c) {
	vec2 p = c * cell;
	return floor(fbm(p * 0.5) * 7.0 + gnoise(p * 3.0) * 1.5);
}

// --- R'lyeh: cada zona de ~7 m tiene su rejilla de losas girada y torcida ---
// Devuelve (id de la losa, distancia a la junta en celdas, altura)
vec3 rlyeh_at(vec2 c) {
	vec2 p = (c + 0.5) * cell;
	vec2 zone = floor(p / 7.0 + vec2(fbm(p * 0.05), fbm(p * 0.05 + 9.0)) * 0.8);
	float a = (hash(zone) - 0.5) * 1.1;                       // giro de la zona: hasta ±30°
	float sh = (hash(zone + 3.0) - 0.5) * 0.6;                 // y una torsión que deja ángulos raros
	mat2 r = mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a)));
	vec2 q = r * p;
	q.x += q.y * sh;
	float size = 1.1 + hash(zone + 7.0) * 0.8;
	vec2 id = floor(q / size);
	vec2 f = fract(q / size) - 0.5;
	float ed = min(0.5 - abs(f.x), 0.5 - abs(f.y)) * size / cell;
	float h = ed < 1.0 ? -1.0 : floor(hash(id + zone * 13.0) * 3.0);
	return vec3(hash(id + zone), ed, h);
}

// --- tierra: baches y rodadas en escalones de un voxel ---
float mud_h(vec2 c) {
	vec2 p = c * cell;
	return floor(fbm(p * 0.35) * 5.0 + gnoise(p * 2.2) * 1.2);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	if (wnrm.y < 0.5) {
		ALBEDO = edge_col;
		ROUGHNESS = 0.8;
	} else {
		vec2 c = floor(wpos.xz / cell);
		vec2 pc = (c + 0.5) * cell;
		float g = hash(c + 17.0);
		vec3 col;
		float rough = 0.9;
		float spec = 0.3;
		float shade = 1.0;
		float wetm = 0.0;                 // charco (0..1)
		float crack = 0.0;                // grieta que brilla (arrecife)
		vec3 glow = vec3(0.0);
		int k = kind;
		vec3 bhi = base_hi, blo = base_lo;
		if (dock > 0.0 && max(pc.x, pc.y) > dock) { k = 2; bhi = dock_hi; blo = dock_lo; }
		if (k == 1) {
			vec3 s = cobble_at(c);
			float up = s.z - cobble_at(c + vec2(-1, -1)).z;
			float dn = cobble_at(c + vec2(1, 1)).z - s.z;
			shade = 1.0 + clamp(up, 0.0, 1.0) * 0.14 - clamp(dn, 0.0, 1.0) * 0.16;
			col = mix(base_lo, base_hi, 0.25 + 0.75 * s.x) * (0.95 + 0.08 * g);
			float m = step(0.62, fbm(pc * 0.4 + 11.0));
			if (s.y < 1.0) {                                       // junta: tierra, verdín o agua
				col = mix(joint, moss, m * 0.8);
				wetm = step(0.55, fbm(pc * 0.25 + 3.0)) * wet;
			} else {
				col = mix(col, moss * 1.2, m * step(s.y, 2.0) * 0.6);   // verdín en los bordes
			}
			wetm = max(wetm, step(0.66, fbm(pc * 0.18 + 30.0)) * wet * step(s.z, 1.0));   // charcos en las hondas
		} else if (k == 2) {
			vec3 s = plank_at(c);
			float up = s.z - plank_at(c + vec2(-1, -1)).z;
			float dn = plank_at(c + vec2(1, 1)).z - s.z;
			shade = 1.0 + clamp(up, 0.0, 1.0) * 0.12 - clamp(dn, 0.0, 1.0) * 0.14;
			if (s.y < 1.0) {
				col = joint * 0.6;                                     // hueco entre tablas
			} else {
				float grain = gnoise(vec2(pc.x * 1.2, pc.y * 22.0) + s.x * 50.0);
				col = mix(base_lo, base_hi, 0.3 + 0.5 * s.x) * (0.85 + 0.3 * step(0.55, grain) * 0.5 + 0.04 * g);
				col = mix(col, moss, step(0.7, fbm(pc * 0.5 + 7.0)) * 0.35);   // tablas podridas
				// clavos: dos cabezas en cada extremo de la tabla
				vec2 p = pc;
				float row = floor(p.y / plank);
				float fy = fract(p.y / plank);
				if (s.y >= 2.0 && s.y < 3.0 && (abs(fy - 0.3) < 0.07 || abs(fy - 0.7) < 0.07)) {
					col = vec3(0.12, 0.10, 0.09);
				}
			}
			wetm = step(0.7, fbm(pc * 0.2 + 30.0)) * wet * 0.7;
		} else if (k == 4) {
			vec3 s = rlyeh_at(c);
			float up = s.z - rlyeh_at(c + vec2(-1, -1)).z;
			float dn = rlyeh_at(c + vec2(1, 1)).z - s.z;
			shade = 1.0 + clamp(up, 0.0, 1.0) * 0.14 - clamp(dn, 0.0, 1.0) * 0.16;
			if (s.y < 1.0) {                                           // junta: limo verdoso que apenas brilla
				col = mix(joint, moss, 0.6);
				crack = step(0.72, fbm(pc * 0.3 + 4.0)) * 0.18;
			} else {
				col = mix(base_lo, base_hi, 0.25 + 0.75 * s.x) * (0.93 + 0.1 * g);
				col = mix(col, moss, step(0.68, fbm(pc * 0.35 + 21.0)) * 0.5);   // verdín
				if (s.y < 3.0 && hash(floor(c / 3.0)) > 0.97) col *= 0.6;          // muescas
			}
			wetm = step(0.7, fbm(pc * 0.2 + 12.0)) * wet * step(s.z, 0.0);
		} else if (k == 3) {
			float h = reef_h(c);
			float up = h - reef_h(c + vec2(-1, -1));
			float dn = reef_h(c + vec2(1, 1)) - h;
			shade = 1.0 + clamp(up, 0.0, 1.0) * 0.16 - clamp(dn, 0.0, 1.0) * 0.18;
			col = mix(base_lo, base_hi, clamp(h / 7.0, 0.0, 1.0)) * (0.92 + 0.12 * g);
			float alga = step(0.62, fbm(pc * 0.45 + 33.0)) * step(h, 3.0);
			col = mix(col, moss * (0.8 + 0.4 * g), alga * 0.85);                // algas en lo hondo
			float barn = step(0.985, hash(floor(c / 2.0) + 71.0)) * step(5.0, h);
			col = mix(col, barnacle * (0.8 + 0.3 * g), barn);                     // percebes en lo alto
			wetm = step(h, 1.0) * wet;                                            // charcos en las hondonadas
			float cr = abs(gnoise(pc * 0.16 + 5.0) - 0.5);                         // grietas: pocas líneas finas
			if (cr < 0.004 && h < 4.0 && fbm(pc * 0.1 + 2.0) > 0.55) { col = crack_glow; crack = 1.0; }
		} else {
			float h = mud_h(c);
			float up = h - mud_h(c + vec2(-1, -1));
			float dn = mud_h(c + vec2(1, 1)) - h;
			shade = 1.0 + clamp(up, 0.0, 1.0) * 0.10 - clamp(dn, 0.0, 1.0) * 0.12;
			col = mix(base_lo, base_hi, clamp(h / 5.0, 0.0, 1.0)) * (0.94 + 0.1 * g);
			float grass = step(0.66, fbm(pc * 0.3 + 50.0)) * step(0.45, hash(c + 4.0)) * step(2.0, h);
			col = mix(col, moss * (0.9 + 0.3 * g), grass);             // matas de hierba rala
			wetm = step(h, 0.0) * wet;                                 // charcos en lo más hondo
			wetm = max(wetm, step(h, 1.0) * step(0.6, fbm(pc * 0.2 + 2.0)) * wet);
			if (road_w > 0.0) {                                       // carretera: tierra pisada y rodadas
				vec2 dd = normalize(road_d);
				float off = dot(pc - road_p, vec2(-dd.y, dd.x)) + (gnoise(pc * 0.3) - 0.5) * 0.6;
				float on = step(abs(off), road_w * 0.5);
				if (road_kind == 1) {                                 // balasto: piedras de 2-3 celdas en escalones
					vec2 sc = floor(c / 2.5);
					float st = hash(sc + 41.0);
					float hs = floor(st * 2.0);
					float hn = floor(hash(floor((c + vec2(-1.0)) / 2.5) + 41.0) * 2.0);
					vec3 bc = mix(ballast_lo, ballast_hi, 0.3 + 0.7 * st) * (0.92 + 0.12 * g);
					col = mix(col, bc * (1.0 + clamp(hs - hn, 0.0, 1.0) * 0.12 - clamp(hn - hs, 0.0, 1.0) * 0.12), on);
					wetm *= 1.0 - on;
				} else {
				col = mix(col, road_col * (0.94 + 0.1 * g), on * 0.85);
				float rut = on * step(abs(abs(off) - 0.75), 0.16);
				col = mix(col, base_lo * 1.1, rut * 0.7);
				wetm = max(wetm * (1.0 - on), rut * step(0.45, fbm(pc * 0.4 + 8.0)) * wet);
				shade -= rut * 0.08;
				}
			}
			if (marsh > 0.0) {                                        // marisma: agua quieta entre matas
				float m = smoothstep(marsh - 2.0, marsh + 3.0, max(pc.x, pc.y) + (fbm(pc * 0.15) - 0.5) * 6.0);
				wetm = max(wetm, m * step(0.42, fbm(pc * 0.25 + 70.0)));
				col = mix(col, moss * 0.8, m * 0.5);
			}
		}
		col *= mix(1.0, 0.78, wet);                                    // todo mojado oscurece
		col = mix(col, puddle, wetm);
		if (water_extent > 0.0) {                                      // ciénaga: agua quieta con lentejas
			float wv = texture(water_tex, (pc - water_origin) / water_extent).r;
			wv += (fbm(pc * 0.9 + 13.0) - 0.5) * 0.35;                  // orilla irregular, no a celdas de 25 cm
			float inw = step(0.5, wv);
			float shore = step(0.38, wv) * (1.0 - inw);                 // barro mojado en la orilla
			col = mix(col, puddle * 1.3, shore);
			wetm = max(wetm, shore * 0.6);
			if (inw > 0.5) {
				float depth = clamp((wv - 0.5) * 2.5, 0.0, 1.0);
				vec3 wc = mix(water_shallow, water_deep, depth);
				float weed = step(0.70, fbm(pc * 0.5 + 90.0)) * step(0.3, hash(c + 9.0));   // lentejas de agua, a manchas
				float ripple = step(0.985, hash(floor(c / 2.0) + floor(TIME * 0.8)));       // alguna onda que destella
				float rim = 1.0 - smoothstep(0.5, 0.62, wv);                  // borde claro junto a la orilla
				col = mix(wc * (1.0 + rim * 0.5), duckweed * (0.85 + 0.3 * g), weed);
				shade = 1.0 + ripple * 0.35 * (1.0 - weed);
				wetm = 1.0 - weed * 0.8;
				crack = 0.0;
				glow = water_glow * (0.6 + 0.4 * depth) * (1.0 - weed) * (0.85 + 0.15 * sin(TIME * 1.3 + fbm(pc * 0.3) * 6.0));
			}
		}
		ALBEDO = col * shade;
		EMISSION = glow + crack_glow * crack * 0.7;
		ROUGHNESS = mix(mix(rough, 0.45, wet), 0.04, wetm);
		SPECULAR = mix(mix(spec, 0.5, wet), 0.9, wetm);
	}
}
