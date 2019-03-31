shader_type spatial;
uniform vec2 resolution = vec2(640.0, 360.0);

void fragment() {
	vec3 basis = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
	vec3 adjacent = texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x, SCREEN_UV.y - (1.0 / resolution.y))).rgb;
	adjacent += texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x, SCREEN_UV.y + (1.0 / resolution.y))).rgb;
	adjacent += texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x - (1.0 / resolution.x), SCREEN_UV.y)).rgb;
	adjacent += texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x + (1.0 / resolution.x), SCREEN_UV.y)).rgb;
	adjacent += texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x + (1.0 / resolution.x), SCREEN_UV.y - (1.0 / resolution.y))).rgb;
	adjacent += texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x - (1.0 / resolution.x), SCREEN_UV.y + (1.0 / resolution.y))).rgb;
	adjacent += texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x - (1.0 / resolution.x), SCREEN_UV.y - (1.0 / resolution.y))).rgb;
	adjacent += texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x + (1.0 / resolution.x), SCREEN_UV.y + (1.0 / resolution.y))).rgb;
	adjacent /= 8.0;
	float l_diff = length(adjacent) - length(basis);
	adjacent = normalize(adjacent);
	basis = normalize(basis);
	float diff = dot(basis, adjacent);
	if (diff < 0.99) {
		ALBEDO = vec3(0.0, 0.0, 0.0);
	} else if (l_diff > 0.001) {
		ALBEDO = vec3(0.0, 0.0, 0.0);
	} else {
		ALPHA = 0.0;
	}
}