shader_type spatial;
render_mode blend_mix,cull_front,unshaded;
uniform vec4 albedo : hint_color;
uniform float transparency : hint_range(0.0, 1.0);

void fragment() {
	float viewangle = 1.0 - dot(VIEW, NORMAL);
	// at 90 degrees, viewangle is 1.0
	// when view and normal are facing each other, viewangle is 0.0

	// flicker
	float xtra_threshold = 0.07;
	if (mod(TIME, 0.13333333) > 0.0666666666) {
		xtra_threshold = -0.07;
	}

	float transparency_multiplier = 1.0;
	if (viewangle > 0.65) {
		transparency_multiplier = 1.0 - ((viewangle - 0.65) / 0.35);
	}
	
	if (viewangle > 0.5 + xtra_threshold) {
		viewangle = 1.0;
	} else if (viewangle < 0.4 + xtra_threshold) {
		viewangle = 0.0;
	}

	vec3 inverse_albedo = vec3(1.0) - albedo.rgb;
	ALBEDO = vec3(1.0) - (viewangle * inverse_albedo);
	ALPHA = transparency * transparency_multiplier;
}
