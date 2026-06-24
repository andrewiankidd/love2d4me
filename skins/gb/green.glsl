// Game Boy green tint + subtle pixel grid overlay
extern vec2 screen_size;

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
    vec4 pixel = Texel(tex, tc) * color;

    // Convert to luminance then apply Game Boy green palette
    float luma = dot(pixel.rgb, vec3(0.299, 0.587, 0.114));
    vec3 gb_dark  = vec3(0.06, 0.22, 0.06);
    vec3 gb_light = vec3(0.61, 0.74, 0.06);
    vec3 tinted = mix(gb_dark, gb_light, luma);

    // Subtle pixel grid (darken every Nth pixel row/col)
    float grid = 1.0;
    if (mod(floor(sc.x), 3.0) < 0.5 || mod(floor(sc.y), 3.0) < 0.5) {
        grid = 0.92;
    }

    return vec4(tinted * grid, pixel.a);
}
