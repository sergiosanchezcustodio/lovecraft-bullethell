// Vista previa de la pestaña Vídeo (hito 20.12): la miniatura con la curva del brillo elegido, la
// misma que BrightnessPattern y Atmosphere.set_lift (las miniaturas se capturan con el brillo 0).
shader_type canvas_item;

uniform float gamma = 1.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	COLOR = vec4(pow(max(c.rgb, vec3(0.0)), vec3(1.0 / max(gamma, 0.05))), c.a);
}
