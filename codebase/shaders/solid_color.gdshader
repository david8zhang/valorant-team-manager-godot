shader_type canvas_item;

uniform bool enabled = false;
uniform vec4 solid_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);

    if (enabled) {
        // Preserve original alpha so transparent areas stay transparent
        COLOR = vec4(solid_color.rgb, tex_color.a * solid_color.a);
    } else {
        COLOR = tex_color;
    }
}