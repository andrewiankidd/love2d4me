// CRT scanline + vignette + slight barrel distortion
extern vec2 screen_size;
extern number time;

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
    // Barrel distortion
    vec2 uv = tc - 0.5;
    float d = dot(uv, uv);
    uv *= 1.0 + d * 0.15;
    uv += 0.5;

    // Clamp to edges (black outside barrel)
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        return vec4(0.0, 0.0, 0.0, 1.0);
    }

    vec4 pixel = Texel(tex, uv) * color;

    // Scanlines
    float scanline = sin(uv.y * screen_size.y * 3.14159) * 0.5 + 0.5;
    scanline = mix(0.85, 1.0, scanline);

    // Vignette
    vec2 vig = uv * (1.0 - uv);
    float vignette = vig.x * vig.y * 16.0;
    vignette = clamp(pow(vignette, 0.25), 0.0, 1.0);

    // Subtle color fringing (chromatic aberration)
    float ca = 0.002;
    float r = Texel(tex, vec2(uv.x + ca, uv.y)).r;
    float g = pixel.g;
    float b = Texel(tex, vec2(uv.x - ca, uv.y)).b;

    return vec4(vec3(r, g, b) * scanline * vignette, pixel.a);
}
