shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 1.0;
uniform float oval_width : hint_range(0.1, 2.0) = 1.0;
uniform float oval_height : hint_range(0.1, 2.0) = 1.0;
uniform float softness : hint_range(0.0, 1.0) = 0.3;
uniform float dither_size : hint_range(1.0, 8.0) = 4.0;

// Bayer matrix for dithering
float bayer4x4(vec2 coord) {
    int x = int(mod(coord.x, 4.0));
    int y = int(mod(coord.y, 4.0));
    
    const float bayer[16] = float[](
        0.0/16.0,  8.0/16.0,  2.0/16.0, 10.0/16.0,
        12.0/16.0, 4.0/16.0, 14.0/16.0,  6.0/16.0,
        3.0/16.0, 11.0/16.0,  1.0/16.0,  9.0/16.0,
        15.0/16.0, 7.0/16.0, 13.0/16.0,  5.0/16.0
    );
    
    return bayer[x + y * 4];
}

void fragment() {
    vec2 uv = UV - 0.5;
    
    // Create oval distance
    float dist = length(vec2(uv.x * oval_width, uv.y * oval_height));
    
    // Animated threshold based on progress
    float threshold = progress * 0.8;
    
    // Create gradient from edges to center
    float vignette = smoothstep(threshold - softness, threshold + softness, dist);
    
    // Get dither value
    vec2 dither_coord = FRAGCOORD.xy / dither_size;
    float dither = bayer4x4(dither_coord);
    
    // Apply dithering to the vignette
    float dithered_vignette = step(dither, vignette);
    
    // Get original color
    vec4 color = texture(TEXTURE, UV);
    
    // Mix between original and transparent based on dithered vignette
    COLOR = vec4(color.rgb, color.a * (1.0 - dithered_vignette));
}