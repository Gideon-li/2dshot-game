shader_type canvas_item;
render_mode blend_add, unshaded;

uniform vec4 paper_color : source_color = vec4(0.956863, 0.937255, 0.894118, 1.0);
uniform float intensity : hint_range(0.0, 1.0) = 0.32;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float luma = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	float paper_luma = dot(paper_color.rgb, vec3(0.299, 0.587, 0.114));
	float glow = smoothstep(paper_luma + 0.015, paper_luma + 0.20, luma);
	COLOR = vec4(tex.rgb * glow * intensity, glow * intensity);
}
