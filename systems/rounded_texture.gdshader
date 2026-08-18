shader_type canvas_item;

uniform float radius_pixels : hint_range(0.0, 64.0) = 8.0;
uniform bool round_top = true;
uniform bool round_bottom = true;
uniform vec2 radius_uv = vec2(0.0);
uniform vec2 logical_size_pixels = vec2(0.0);

varying vec2 control_uv;

void vertex() {
	// TextureRect's cover mode crops UV, so texture UV no longer reaches 0/1
	// at the control edges. Keep a second UV based on the drawn quad itself.
	control_uv = logical_size_pixels.x > 0.0 && logical_size_pixels.y > 0.0
		? VERTEX / logical_size_pixels
		: UV;
}

void fragment() {
	vec4 sampled = texture(TEXTURE, UV) * COLOR;
	vec2 mask_uv = logical_size_pixels.x > 0.0 && logical_size_pixels.y > 0.0 ? control_uv : UV;
	vec2 uv_per_pixel = logical_size_pixels.x > 0.0 && logical_size_pixels.y > 0.0
		? vec2(1.0) / logical_size_pixels
		: max(fwidth(mask_uv), vec2(0.000001));
	vec2 corner_radius = radius_uv.x > 0.0 && radius_uv.y > 0.0 ? radius_uv : uv_per_pixel * radius_pixels;
	vec2 nearest_edge = min(mask_uv, vec2(1.0) - mask_uv);
	bool in_horizontal_corner = nearest_edge.x < corner_radius.x;
	bool in_vertical_corner = nearest_edge.y < corner_radius.y;
	bool should_round_row = (mask_uv.y < 0.5 && round_top) || (mask_uv.y >= 0.5 && round_bottom);
	if (in_horizontal_corner && in_vertical_corner && should_round_row) {
		vec2 ellipse_position = (nearest_edge - corner_radius) / corner_radius;
		float edge_distance = length(ellipse_position);
		sampled.a *= 1.0 - smoothstep(0.90, 1.02, edge_distance);
	}
	COLOR = sampled;
}
