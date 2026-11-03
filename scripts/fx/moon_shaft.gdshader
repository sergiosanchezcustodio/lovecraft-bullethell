// Haz de luna en el aire (hito 16.32, MoonShafts). La malla es el contorno del haz; cada píxel
// recorta el rayo de la vista con las seis caras del haz y con lo que hay en la escena (la
// profundidad), y suma la luz de unas muestras a lo largo del tramo: lo que tapa el parteluz deja
// franjas oscuras y el polvo la hace irregular. Aditivo: solo aclara.
shader_type spatial;
render_mode blend_add, unshaded, cull_back, depth_draw_never, depth_test_disabled, shadows_disabled, fog_disabled;

#include "res://scripts/fx/moon_shaft.gdshaderinc"

uniform vec3 color : source_color = vec3(0.62, 0.72, 1.0);
uniform float energy = 1.0;
uniform float density = 0.8;
uniform float fade_top = 0.2;                    // m de fundido desde la abertura
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;

const int STEPS = 12;

void clip_plane(inout float lo, inout float hi, vec3 n, float c, vec3 o, vec3 r) {
	float v0 = dot(n, o) + c;
	float rate = dot(n, r);
	if (abs(rate) < 1e-6) {
		if (v0 < 0.0) hi = -1.0;
		return;
	}
	float x = -v0 / rate;
	if (rate > 0.0) lo = max(lo, x); else hi = min(hi, x);
}

float dust(vec3 p) {                             // polvo que deriva despacio
	vec3 q = p * 1.7 + vec3(0.0, TIME * 0.06, TIME * 0.04);
	vec2 c = floor(q.xz + q.y * 0.37);
	vec2 f = fract(q.xz + q.y * 0.37);
	f = f * f * (3.0 - 2.0 * f);
	float a = mix(shaft_hash(c), shaft_hash(c + vec2(1.0, 0.0)), f.x);
	float b = mix(shaft_hash(c + vec2(0.0, 1.0)), shaft_hash(c + vec2(1.0, 1.0)), f.x);
	return 0.55 + 0.9 * mix(a, b, f.y);
}

void fragment() {
	vec3 P = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 R = PROJECTION_MATRIX[3][3] > 0.5 ? normalize((INV_VIEW_MATRIX * vec4(0.0, 0.0, -1.0, 0.0)).xyz) : normalize(P - CAMERA_POSITION_WORLD);
	vec3 O = P - R * 80.0;
	vec3 o = shaft_local(O);
	vec3 r = (shaft_to_local * vec4(R, 0.0)).xyz;
	float lo = 0.0;
	float hi = 200.0;
	clip_plane(lo, hi, vec3(1.0, 0.0, 0.0), 0.0, o, r);
	clip_plane(lo, hi, vec3(-1.0, 0.0, 0.0), 1.0, o, r);
	clip_plane(lo, hi, vec3(0.0, 1.0, 0.0), 0.0, o, r);
	clip_plane(lo, hi, vec3(0.0, -1.0, 0.0), 1.0, o, r);
	clip_plane(lo, hi, vec3(0.0, 0.0, 1.0), 0.0, o, r);
	clip_plane(lo, hi, vec3(shaft_floor.y, shaft_floor.z, -shaft_floor.w), shaft_floor.x, o, r);
	// lo que hay delante (paredes, estatuas, investigadores) corta el haz
	float d = texture(depth_tex, SCREEN_UV).r;
	vec4 vv = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, d, 1.0);
	vec3 S = (INV_VIEW_MATRIX * vec4(vv.xyz / vv.w, 1.0)).xyz;
	hi = min(hi, dot(S - O, R));
	if (hi <= lo) discard;
	float stp = (hi - lo) / float(STEPS);
	float j = shaft_hash(FRAGCOORD.xy);
	float acc = 0.0;
	for (int i = 0; i < STEPS; i++) {
		float lam = lo + (float(i) + j) * stp;
		vec3 l = o + r * lam;
		acc += shaft_mask(l.xy) * smoothstep(0.0, fade_top, l.z) * dust(O + R * lam) * stp;
	}
	ALBEDO = color * energy * (1.0 - exp(-acc * density));
	ALPHA = 1.0;
}
