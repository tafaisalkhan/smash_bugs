shader_type canvas_item;
// Removes the magenta (#FF00FF) background from the sprite sheets.
// The tolerance also cleans JPEG edge artifacts around the characters.

uniform float tolerance : hint_range(0.0, 1.0) = 0.42;
uniform float softness : hint_range(0.0, 0.5) = 0.12;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float dist = distance(tex.rgb, vec3(1.0, 0.0, 1.0));
	float alpha = smoothstep(tolerance - softness, tolerance, dist);
	// Remove magenta tint left on anti-aliased edges.
	vec3 rgb = tex.rgb;
	float spill = min(rgb.r, rgb.b) - rgb.g;
	if (spill > 0.0) {
		rgb.r -= spill * 0.6;
		rgb.b -= spill * 0.6;
	}
	COLOR = vec4(rgb, tex.a * alpha) * COLOR.a;
	COLOR.rgb = rgb * COLOR.rgb / max(COLOR.a, 0.0001) * COLOR.a;
}
