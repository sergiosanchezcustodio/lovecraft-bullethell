shader_type spatial;
// Suelo de nieve en voxel fino (rehecho el 30-09-2026 para igualar la resolución de los
// modelos): celdas de 1/32 m (el grano del atrezo; antes 12,5 cm, que se veía tosco al lado
// de los personajes). Relieve en escalones de un voxel (ventisqueros grandes y sastrugi
// alargados por el viento) sombreado como los modelos: canto claro arriba y a la izquierda,
// oscuro abajo y a la derecha, sin líneas marcadas. Grano fino de nieve con algún destello,
// placas de hielo azulado con vetas y nieve pisada alrededor del campamento.
// Todo en coordenadas del mundo: no depende de cómo esté hecha la malla.

uniform float cell = 0.03125;
uniform vec3 snow_hi : source_color = vec3(0.94, 0.96, 0.99);
uniform vec3 snow_lo : source_color = vec3(0.82, 0.87, 0.94);
uniform vec3 ice : source_color = vec3(0.64, 0.79, 0.90);
uniform vec3 ice_vein : source_color = vec3(0.80, 0.90, 0.97);
uniform vec3 trampled : source_color = vec3(0.76, 0.78, 0.82);
uniform vec3 edge_col : source_color = vec3(0.55, 0.70, 0.82);
uniform vec2 wind = vec2(0.8, 0.6);
uniform float camp_radius = 14.0;
uniform float relief = 1.0;

varying vec3 wpos;
varying vec3 wnrm;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

float vnoise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

float fbm(vec2 p) {          // 3 octavas (4 costaban demasiado a pantalla completa)
	float s = 0.0, a = 0.5;
	mat2 r = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
	for (int i = 0; i < 3; i++) { s += a * vnoise(p); p = r * p * 2.03; a *= 0.5; }
	return s * 1.14;
}

// Altura de la celda c, en escalones de un voxel. Los ventisqueros y los sastrugi dan las
// formas grandes; los escalones son finos, así que los bordes se ven como en los modelos.
float height(vec2 c) {
	vec2 p = c * cell;
	vec2 wd = normalize(wind);
	vec2 q = vec2(dot(p, wd), dot(p, vec2(-wd.y, wd.x)));
	float drift = fbm(p * 0.07) * 9.0;                            // ventisqueros
	float sas = vnoise(vec2(q.x * 1.9, q.y * 0.4)) * 2.6;             // sastrugi, alargados por el viento
	return floor(drift + sas);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	if (wnrm.y < 0.5) {                                            // frente de la orilla
		ALBEDO = edge_col;
		ROUGHNESS = 0.4;
	} else {
		vec2 c = floor(wpos.xz / cell);
		float h = height(c);
		vec2 pc = (c + 0.5) * cell;                               // todo por celda: bordes de voxel, no curvas
		// escalones: canto claro si la celda de "arriba a la izquierda" (hacia la cámara y la
		// luz) está más baja; oscuro si la de abajo a la derecha está más alta
		float up = h - height(c + vec2(-1, -1));
		float dn = height(c + vec2(1, 1)) - h;
		float shade = 1.0 + clamp(up, 0.0, 1.0) * 0.11 * relief - clamp(dn, 0.0, 1.0) * 0.13 * relief;

		float t = clamp(h / 10.0, 0.0, 1.0);
		vec3 col = mix(snow_lo, snow_hi, t);
		float g = hash(c + 17.0);
		col *= 0.975 + 0.04 * g;                                      // grano fino de nieve
		// placas de hielo (en las hondonadas y por manchas), con vetas claras
		float icy = fbm(pc * 0.05 + 40.0);
		float ice_m = step(0.64, icy) * step(h, 4.0);
		float vein = step(0.94, 1.0 - abs(vnoise(pc * 1.3 + 7.0) - 0.5) * 2.0);
		vec3 ice_c = mix(ice, ice_vein, vein * 0.45) * (0.97 + 0.05 * hash(c + 3.0));
		// nieve pisada alrededor del campamento, a manchas
		float d = length(pc);
		float tr = step(fbm(pc * 0.35 + 9.0), 0.52 - (d - camp_radius) * 0.04) * step(d, camp_radius + 4.0);
		col = mix(col, trampled * (0.97 + 0.05 * g), tr * 0.75);
		col = mix(col, ice_c, ice_m);
		ALBEDO = col * shade;
		// algún destello de cristal de nieve (muy pocos, pequeños)
		float spark = step(0.996, hash(c + 91.0)) * (1.0 - ice_m) * (1.0 - tr);
		EMISSION = vec3(0.9, 0.95, 1.0) * spark * 0.25;
		ROUGHNESS = mix(0.9, 0.3, ice_m);
		SPECULAR = mix(0.3, 0.6, ice_m);
	}
}
