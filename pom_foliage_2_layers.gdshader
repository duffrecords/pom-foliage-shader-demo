shader_type spatial;
render_mode depth_prepass_alpha, cull_back, world_vertex_coords;

uniform sampler2D top_albedo : source_color;
uniform sampler2D top_normal : hint_normal;
uniform sampler2D top_roughness : hint_default_white;

uniform sampler2D bottom_albedo : source_color;
uniform sampler2D bottom_normal : hint_normal;
uniform sampler2D bottom_roughness : hint_default_white;

uniform float depth = 0.05;
uniform vec3 light_direction = vec3(-0.3, -0.7, -0.6); // world-space

const int STEPS = 32;

varying vec3 view_dir_tangent;
varying vec3 light_dir_tangent;

void vertex() {
    // VERTEX, TANGENT, BINORMAL, NORMAL are now in world space
    mat3 tbn = mat3(
        normalize(TANGENT),
        normalize(BINORMAL),
        normalize(NORMAL)
    );

    vec3 view_dir_world = CAMERA_POSITION_WORLD - VERTEX;

    view_dir_tangent = normalize(tbn * view_dir_world);
    light_dir_tangent = normalize(tbn * light_direction); // still world-space
}


vec2 parallax_uv(vec2 uv, vec3 view_dir, float scale) {
    float layer_depth = 1.0 / float(STEPS);
    vec3 shadow_ray = normalize(-view_dir);
	vec2 delta_uv = (shadow_ray.xy / shadow_ray.z) * scale / float(STEPS);

    float current_layer = 0.0;
    vec2 current_uv = uv;
    float alpha_val = texture(top_albedo, current_uv).a;

    while (current_layer < 1.0 && alpha_val <= 0.0) {
        current_uv -= delta_uv;
        current_layer += layer_depth;
        alpha_val = texture(top_albedo, current_uv).a;
    }

    return current_uv;
}

bool check_shadow(vec2 uv, vec3 light_dir, float scale) {
    float layer_depth = 1.0 / float(STEPS);
    
    // March *in the direction the light comes from* (not opposite)
    vec3 shadow_ray = normalize(light_dir); // ✅ do NOT negate

    vec2 delta_uv = (shadow_ray.xy / shadow_ray.z) * scale / float(STEPS);

    float current_layer = 0.0;
    vec2 current_uv = uv;

    while (current_layer < 1.0) {
        current_uv += delta_uv;
        current_layer += layer_depth;
        float alpha_val = texture(top_albedo, current_uv).a;
        if (alpha_val > 0.0) return true;
    }

    return false;
}

/*
void fragment() {
	float intensity = dot(normalize(light_dir_tangent), vec3(0.0, 0.0, 1.0)); // tangent-space Z+
	ALBEDO = vec3(clamp(intensity, 0.0, 1.0));
    //vec3 light_dir_vis = normalize(light_dir_tangent);
    //ALBEDO = abs(light_dir_vis); // Show XYZ direction as color
    //NORMAL = NORMAL;
    //ROUGHNESS = 1.0;
}
*/
void fragment() {
    vec2 uv = UV;
    vec4 top_sample = texture(top_albedo, uv);
    float alpha = top_sample.a;

    vec3 albedo_color;
    vec3 normal_map;
    float roughness_val;

    if (alpha > 0.0) {
        albedo_color = top_sample.rgb;
        normal_map = texture(top_normal, uv).rgb * 2.0 - 1.0;
        roughness_val = texture(top_roughness, uv).r;
    } else {
        vec2 displaced_uv = parallax_uv(uv, view_dir_tangent, depth);
        albedo_color = texture(bottom_albedo, displaced_uv).rgb;
        normal_map = texture(bottom_normal, displaced_uv).rgb * 2.0 - 1.0;
        roughness_val = texture(bottom_roughness, displaced_uv).r;

        if (check_shadow(displaced_uv, light_dir_tangent, depth)) {
            albedo_color *= 0.5; // simple shadow attenuation
        }
    }

    // Apply normal map using Godot's tangent space basis
    NORMAL = normalize(
        TANGENT * normal_map.x +
        BINORMAL * normal_map.y +
        NORMAL * normal_map.z
    );

    //ALBEDO = clamp(albedo_color, 0.0, 1.0);
	ALBEDO = vec3(0.5) + 0.5 * normalize(light_dir_tangent);
    ROUGHNESS = roughness_val;
}