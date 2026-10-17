// A water's surface over the ground the scenery importer laid under it: its bed falls from the shore
// (SITerrain.lower_waters()), so the water is clear where shallow and foams where it meets the ground.
// The game's water material (textures/@water06.mat, libmaszyna's legacy water.gdshader): the dudv
// waves, the normal map in RG. Its reflection is the sky's by the Fresnel of a dielectric, not the
// .mat's metallic 0.9 at glossiness 3500: that made a mirror - the sun a blown white blot as wide as
// a lake, the rest of the water black.
shader_type spatial;

render_mode blend_mix, depth_draw_always, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_texture : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D dudv_texture : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D depth_texture : hint_depth_texture, filter_nearest;

// @water06.mat param_color: the water's tint and its opacity looked at from above
uniform vec4 water_color : source_color = vec4(0.51, 0.78, 0.88, 0.7);
// where it is deep: darker, and opaque
uniform vec4 deep_color : source_color = vec4(0.12, 0.2, 0.24, 0.95);
// the depth [m] at which the water is deep_color
uniform float deep_depth = 2.0;
// the depth [m] the water fades in over from the shore
uniform float shore_depth = 0.25;
uniform vec4 foam_color : source_color = vec4(0.9, 0.93, 0.92, 0.85);
// the depth [m] the foam reaches
uniform float foam_depth = 0.12;
// how sharp the sky and the sun lie on the waves; @water06.mat param_wave_strength, param_wave_speed
uniform float roughness : hint_range(0.0, 1.0) = 0.12;
// a water's Fresnel at facing (F0 0.02, Godot's specular 0.5 is 0.04)
uniform float specular : hint_range(0.0, 1.0) = 0.25;
uniform float wave_strength : hint_range(0.0, 1.0) = 0.05;
uniform float wave_speed : hint_range(0.0, 1.0) = 0.02;

vec2 distort_uv(vec2 uv) {
    float move_factor = mod(TIME * wave_speed, 1.0);
    vec2 distorted_uv = texture(dudv_texture, vec2(uv.x + move_factor, uv.y)).rg * 0.1;
    distorted_uv = uv + vec2(distorted_uv.x, distorted_uv.y + move_factor);
    return uv + (texture(dudv_texture, distorted_uv).rg * 2.0 - 1.0) * wave_strength;
}

void fragment() {
    vec2 water_uv = distort_uv(UV);
    vec4 normal_sample = texture(normal_texture, water_uv);

    // the ground under the water, from the depth buffer, and how deep the water is over it
    vec4 ground_view = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, texture(depth_texture, SCREEN_UV).r, 1.0);
    ground_view.xyz /= ground_view.w;
    float ground_y = (INV_VIEW_MATRIX * vec4(ground_view.xyz, 1.0)).y;
    float surface_y = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).y;
    float depth = max(surface_y - ground_y, 0.0);
    float deep = smoothstep(0.0, deep_depth, depth);

    // the foam: a band at the shore, broken up by the moving waves
    float foam = (1.0 - smoothstep(0.0, foam_depth, depth)) * smoothstep(0.35, 0.65, texture(dudv_texture, water_uv * 4.0).g);

    float facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
    float opacity = mix(water_color.a, deep_color.a, deep);
    vec3 tint = mix(water_color.rgb, deep_color.rgb, deep);

    vec3 n = vec3(normal_sample.rg * 2.0 - 1.0, 0.0);
    n.z = sqrt(1.0 - clamp(dot(n.xy, n.xy), 0.0, 1.0));

    ALBEDO = mix(texture(albedo_texture, water_uv).rgb * tint, foam_color.rgb, foam);
    METALLIC = 0.0;
    ROUGHNESS = mix(roughness, 1.0, foam);
    SPECULAR = specular * (1.0 - foam);
    NORMAL_MAP = n * 0.5 + 0.5;
    ALPHA = max(mix(opacity, 1.0, 1.0 - pow(facing, 0.2)) * smoothstep(0.0, shore_depth, depth), foam * foam_color.a);
}
