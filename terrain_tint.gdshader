shader_type spatial;

uniform sampler2D albedo_texture;
uniform sampler2D normal_texture;
uniform sampler2D roughness_texture;

uniform vec4 tint_color : source_color = vec4(1.0);

void fragment() {
    vec4 albedo = texture(albedo_texture, UV);
    ALBEDO = albedo.rgb * tint_color.rgb;

    NORMAL_MAP = texture(normal_texture, UV).rgb;
    ROUGHNESS = texture(roughness_texture, UV).r;
}