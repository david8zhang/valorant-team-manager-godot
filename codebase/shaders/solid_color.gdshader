shader_type canvas_item;

uniform bool enabled = false;
uniform vec4 solid_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);

uniform bool outline_enabled = true;
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float outline_width : hint_range(0.0, 10.0) = 2.0;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    float alpha = tex_color.a;

    // Default output
    vec4 result_color = tex_color;

    // Solid color override (your original logic)
    if (enabled) {
        result_color = vec4(solid_color.rgb, alpha * solid_color.a);
    }

    // Outline logic
    if (outline_enabled && alpha == 0.0) {
        vec2 pixel_size = TEXTURE_PIXEL_SIZE * outline_width;
        float max_alpha = 0.0;

        for (int x = -1; x <= 1; x++) {
            for (int y = -1; y <= 1; y++) {
                vec2 offset = vec2(float(x), float(y)) * pixel_size;
                max_alpha = max(
                    max_alpha,
                    texture(TEXTURE, UV + offset).a
                );
            }
        }

        // Draw outline only if near opaque pixel
        if (max_alpha > 0.0) {
            result_color = outline_color;
        }
    }

    COLOR = result_color;
}