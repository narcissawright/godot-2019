shader_type spatial;
//render_mode ambient_light_disabled;
uniform bool use_texture;
uniform float celness : hint_range(0,1);

// supposedly you don't wanna use these with a cel surface:
uniform float metallic : hint_range(0,1);
uniform float roughness : hint_range(0,1);

//Texture for light color
uniform sampler2D light_tex : hint_albedo;
//Texture for shadow color (REMEMBER that shadow areas are light_texture multiplied with shadow_texture, basically)
uniform sampler2D shadow_tex : hint_albedo;
uniform float shadow_amt : hint_range(0,1);
uniform vec4 light_color : hint_color;
uniform vec4 shadow_color: hint_color;

//this varying retrieve uv for usage in light pass!
varying vec2 uv;

//vertex pass -> retriev uv from mesh's UV main channel (channel 0 I think) & will retrieve vertex color for thresholding lighting
void vertex()
{
	uv = UV;
}

void fragment()
{
	METALLIC = metallic;
	ROUGHNESS = roughness;
	if (use_texture == true) {
		ALBEDO = texture(light_tex, uv).rgb;
	} else {
		ALBEDO = light_color.rgb;
		//ALBEDO = NORMAL.rgb;
	}
}

//This function is used for calculate shading
bool calc_shading(float sm)
{
	if(sm > 0.5) {
		return true;
	} else {
		return false;
	}
}

//light pass -> we get LIGHT vector and normalize it, calculate the NdotL, calculate shading and appy LIGHT
//REMEMBER that we aren't really using LIGHT_COLOUR, so it won't affect the mesh colour!
void light()
{
	//vec3 light = normalize(LIGHT);
	vec3 light = LIGHT * ATTENUATION;
	vec3 shadow;
	if (use_texture == true) {
		shadow = texture(shadow_tex, uv).rgb;
	} else {
		shadow = shadow_color.rgb;
	}
	float NdotL = dot(light, NORMAL);
	float sm = smoothstep(0.0, 1.0, NdotL);
	bool shade = calc_shading(sm);
	
	float intensity = (LIGHT_COLOR.r + LIGHT_COLOR.g + LIGHT_COLOR.b) / 3.0;
	vec3 shadow_final = ALBEDO*shadow*LIGHT_COLOR*shadow_amt;
	vec3 remainder = ALBEDO * LIGHT_COLOR - shadow_final;
	vec3 non_cel = (shadow_final) + (remainder * sm);
	vec3 cel;
	if(shade == true) {
		cel = ALBEDO * LIGHT_COLOR;
	} else {
		cel = ALBEDO*shadow * LIGHT_COLOR * shadow_amt;
	}
	if (dot(VIEW, NORMAL) < 0.25) {
		DIFFUSE_LIGHT = vec3(0,0,0);
	} else {
		DIFFUSE_LIGHT += (non_cel * (1.0 - celness)) + (cel * celness);
	}
}