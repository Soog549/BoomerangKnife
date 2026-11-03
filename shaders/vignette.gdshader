shader_type canvas_item;

uniform float strength : hint_range(0.0, 1.0) = 0.35;
uniform vec4 tint : source_color = vec4(0.02, 0.03, 0.06, 1.0);

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float d = length(uv * vec2(1.05, 1.15));
	float v = smoothstep(0.78, 0.30, d);
	COLOR = vec4(tint.rgb, (1.0 - v) * strength);
}
