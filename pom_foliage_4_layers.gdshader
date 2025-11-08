shader_type spatial;
render_mode unshaded, cull_back, world_vertex_coords;

uniform sampler2D albedo1 : source_color;
uniform vec2 scale1 = vec2(1.0);
uniform float rotate1 = 0.0;
uniform vec2 offset1 = vec2(0.0);

uniform sampler2D albedo2 : source_color;
uniform float depth2 = 0.02;
uniform vec2 scale2 = vec2(1.0);
uniform float rotate2 = 0.0;
uniform vec2 offset2 = vec2(0.0);
uniform float shadow2 = 0.5;

uniform sampler2D albedo3 : source_color;
uniform float depth3 = 0.04;
uniform vec2 scale3 = vec2(1.0);
uniform float rotate3 = 0.0;
uniform vec2 offset3 = vec2(0.0);
uniform float shadow3 = 0.5;

uniform sampler2D albedo4 : source_color;
uniform float depth4 = 0.06;
uniform vec2 scale4 = vec2(1.0);
uniform float rotate4 = 0.0;
uniform vec2 offset4 = vec2(0.0);
uniform float shadow4 = 0.5;

uniform vec3 light_direction = vec3(-0.3, -0.7, -0.6);

const int STEPS = 32;
varying vec3 view_dir_tangent;
varying vec3 light_dir_tangent;
varying mat3 tbn_matrix;

void vertex() {
	mat3 tbn = mat3(
		normalize(TANGENT),
		normalize(cross(NORMAL, TANGENT)),
		normalize(NORMAL)
	);
	tbn_matrix = tbn;
	vec3 view_dir_world = CAMERA_POSITION_WORLD - VERTEX;
	view_dir_tangent = normalize(tbn * view_dir_world);
	light_dir_tangent = normalize(tbn * light_direction);
}

vec2 parallax_uv(vec2 uv, vec3 view_dir, float scale) {
	return uv - view_dir.xy * scale;
}

mat2 rotate(float angle) {
	float s = sin(angle);
	float c = cos(angle);
	return mat2(vec2(c, s), vec2(-s, c));
}

vec2 transform_uv(vec2 uv, vec2 scale, float angle, vec2 offset) {
	uv = rotate(angle) * ((uv - 0.5) * scale) + 0.5 + offset;
	return fract(uv);
}

bool check_shadow(vec2 uv, sampler2D albedo_tex, vec3 light_dir, float scale, vec2 scale_uv, float angle, vec2 offset) {
	float layer_depth = 1.0 / float(STEPS);
	vec2 offset_dir = normalize(light_dir.xy);
	vec2 delta_uv = offset_dir * scale / float(STEPS);
	float current_layer = 0.0;
	vec2 current_uv = uv;

	while (current_layer < 1.0) {
		current_uv += delta_uv;
		current_layer += layer_depth;
		vec2 test_uv = transform_uv(current_uv, scale_uv, angle, offset);
		if (texture(albedo_tex, test_uv).a > 0.0) return true;
	}
	return false;
}

void fragment() {
	vec2 uv = UV;
	vec4 result = vec4(0.0);

	// Layer 1 (topmost, no parallax, no shadow)
	vec2 uv1 = transform_uv(uv, scale1, rotate1, offset1);
	vec4 s1 = texture(albedo1, uv1);
	if (s1.a > 0.0) {
		result.rgb += s1.rgb * s1.a; // * (1.0 - result.a);
		result.a += s1.a; //  * (1.0 - result.a);
	}

	// Layer 2
	vec2 uv2 = transform_uv(parallax_uv(uv, view_dir_tangent, depth2), scale2, rotate2, offset2);
	vec4 s2 = texture(albedo2, uv2);
	if (s2.a > 0.0) {
		vec3 col = s2.rgb; // / s2.a;
		if (check_shadow(uv, albedo2, light_dir_tangent, depth2, scale2, rotate2, offset2)) {
			col *= 1.0 - shadow2;
		}
		result.rgb += col * s2.a * (1.0 - result.a);
		result.a += s2.a * (1.0 - result.a);
	}

	// Layer 3
	vec2 uv3 = transform_uv(parallax_uv(uv, view_dir_tangent, depth3), scale3, rotate3, offset3);
	vec4 s3 = texture(albedo3, uv3);
	if (s3.a > 0.0) {
		vec3 col = s3.rgb; // / s3.a;
		if (check_shadow(uv, albedo3, light_dir_tangent, depth3, scale3, rotate3, offset3)) {
			col *= 1.0 - shadow3;
		}
		result.rgb += col * s3.a * (1.0 - result.a);
		result.a += s3.a * (1.0 - result.a);
	}

	// Layer 4 (opaque base layer)
	vec2 uv4 = transform_uv(parallax_uv(uv, view_dir_tangent, depth4), scale4, rotate4, offset4);
	vec3 base = texture(albedo4, uv4).rgb;
	if (
		check_shadow(uv, albedo2, light_dir_tangent, depth4, scale2, rotate2, offset2) ||
		check_shadow(uv, albedo3, light_dir_tangent, depth4, scale3, rotate3, offset3) ||
		check_shadow(uv, albedo1, light_dir_tangent, depth4, scale1, rotate1, offset1)) {
		base *= 1.0 - shadow4;
	}
	result.rgb += base * (1.0 - result.a);

	ALBEDO = result.rgb; // / max(result.a, 0.001);
}