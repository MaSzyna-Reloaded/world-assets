shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_lambert, specular_schlick_ggx;

#include "res://world_assets/common_biomes/materials/tree_wind.gdshaderinc"

// the light modes of the grass (grass/shaders/grass.gdshaderinc), the same numbers
uniform int light_mode : hint_enum("Lambert", "Normal grass", "Unshaded", "Flat shadowed") = 3;

void light() {
	switch(light_mode) {
	case 0: // Lambert, as without light() but with no specular
		DIFFUSE_LIGHT += clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION * LIGHT_COLOR / PI;
		break;
	case 1: // Normal grass: lit as a surface facing up
		DIFFUSE_LIGHT += clamp(dot(mat3(VIEW_MATRIX) * vec3(0.0, 1.0, 0.0), LIGHT), 0.0, 1.0) * ATTENUATION * LIGHT_COLOR / PI;
		break;
	case 2: // Unshaded
		DIFFUSE_LIGHT = vec3(1.0);
		break;
	case 3: // Flat, shadowed: as the grass's mode 3 - by the light's colour and shadow, no face dark by its normal
		DIFFUSE_LIGHT += ATTENUATION * 0.25 * LIGHT_COLOR;
		break;
	}
}
