shader_type canvas_item;

uniform float sink_progress = 0.0;
uniform float edge_fade = 0.05;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	
	// Sinks from bottom up - inverted mask
	float mask = 1.0 - smoothstep(1.0 - sink_progress - edge_fade, 1.0 - sink_progress + edge_fade, UV.y);
	
	COLOR = tex_color;
	COLOR.a = tex_color.a * mask;
}
