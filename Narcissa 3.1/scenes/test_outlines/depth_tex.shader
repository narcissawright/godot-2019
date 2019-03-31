shader_type spatial;
render_mode unshaded;
uniform float near = 0.01;
uniform float far = 100;
uniform vec2 resolution = vec2(640.0, 360.0);

float linearize(float c_depth) {
	c_depth = 2.0 * c_depth - 1.0;
	return near * far / (far + c_depth * (near - far));
}

void fragment() {
	float zpos = linearize(FRAGCOORD.z);
	//ALBEDO = NORMAL;
	ALBEDO = (NORMAL / 2.0) + (zpos / 2.0);
	//DEPTH = zpos;
}