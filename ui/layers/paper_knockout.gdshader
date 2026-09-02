shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform vec4 paper_color : source_color = vec4(0.956863, 0.937255, 0.894118, 1.0);
uniform float threshold : hint_range(0.0, 1.0) = 0.12;
uniform float softness : hint_range(0.0, 0.5) = 0.10;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float d = distance(tex.rgb, paper_color.rgb);
	float a = smoothstep(threshold, threshold + softness, d);
	COLOR = vec4(tex.rgb, tex.a * a);
}
