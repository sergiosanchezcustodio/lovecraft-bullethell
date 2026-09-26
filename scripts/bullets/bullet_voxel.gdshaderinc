// Transformación común de las balas enemigas en voxel (bullet_voxel.gdshader y su silueta).
// La malla (BulletMeshes.orb) tiene tres grupos de cubos, marcados en COLOR.g:
//   0,0 núcleo interior (7 cubos)   0,5 capa exterior del núcleo (12)   1,0 anillo (14)
// COLOR.r es un matiz propio de cada cubo (0..1) para variar el tono.
// INSTANCE_CUSTOM: x = estilo (1 físico, 2 mental, 3 mixto), y = fase, z = edad, w = radio visual.
// Cada estilo enseña unos grupos y esconde los demás (colapsándolos en el centro):
//   físico: núcleo entero (bola maciza)   mental: anillo y núcleo interior   mixto: todo.

varying flat float v_style;
varying float v_group;
varying float v_shade;

float group_of(vec4 c) { return c.g < 0.25 ? 0.0 : (c.g < 0.75 ? 1.0 : 2.0); }

// Devuelve la posición del vértice en el espacio del modelo (sin escala de instancia).
// (Los varyings no se pueden asignar en una función: los pone vertex().)
vec3 bullet_vertex(vec3 v, vec4 c, vec4 custom, float time) {
	float group = group_of(c);
	int style = int(custom.x + 0.5);
	float phase = custom.y;
	bool show = true;
	if (style == 1 && group > 1.5) show = false;           // físico: sin anillo
	if (style == 2 && group > 0.5 && group < 1.5) show = false;   // mental: sin capa exterior
	if (!show) return vec3(0.0);
	float k = style == 1 ? 1.25 : 1.0;                        // la bola física, algo mayor
	float grow = mix(0.45, 1.0, smoothstep(0.0, 0.09, custom.z));   // aparecen creciendo
	if (group > 1.5) {
		// anillo: gira y ondula
		float a = time * 2.2 + phase;
		float ca = cos(a), sa = sin(a);
		v = vec3(v.x * ca - v.z * sa, v.y, v.x * sa + v.z * ca);
		v.y += 0.12 * sin(atan(v.z, v.x) * 3.0 + time * 6.0 + phase);
	} else {
		// núcleo: gira despacio sobre dos ejes (se ve que es un volumen)
		float a = time * 1.3 + phase * 2.0;
		float ca = cos(a), sa = sin(a);
		v = vec3(v.x * ca - v.z * sa, v.y, v.x * sa + v.z * ca);
		float b = 0.5;
		float cb = cos(b), sb = sin(b);
		v = vec3(v.x, v.y * cb - v.z * sb, v.y * sb + v.z * cb);
	}
	return v * k * grow;
}
