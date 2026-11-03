// Reflejos en el agua (hito 16.31, WaterReflection): la imagen de la cámara espejo (jugadores y
// faroles, con fondo transparente) y su matriz. Para el agua a la altura w.y, el reflejo está en el
// punto simétrico respecto al suelo (x, -y, z) visto con esa cámara. d: desplazamiento de las ondas (m).
global uniform sampler2D refl_tex : filter_linear;
global uniform mat4 refl_vp;
global uniform float refl_on;

// rgb, en lineal (aproximado), y a, cuánto tapa
vec4 water_reflection(vec3 w, vec2 d) {
	if (refl_on <= 0.0) return vec4(0.0);
	vec4 clip = refl_vp * vec4(w.x + d.x, -w.y, w.z + d.y, 1.0);
	vec2 uv = clip.xy / clip.w * 0.5 + 0.5;
	uv.y = 1.0 - uv.y;
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) return vec4(0.0);
	vec4 r = texture(refl_tex, uv);
	return vec4(r.rgb * r.rgb, r.a);
}
