// Painterly Post v2 — 단계적 debug
shader_type canvas_item;
render_mode unshaded;

uniform float posterize_steps = 8.0;
uniform float smooth_radius = 2.0;
uniform vec3 warm_tint = vec3(1.05, 0.96, 0.86);
uniform float grain_strength = 0.025;

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void fragment() {
    vec3 col = SCREEN_TEXTURE .rgb;

    // 1) 간단 박스 블러 (표면 평탄화)
    vec2 px = SCREEN_PIXEL_SIZE * smooth_radius;
    vec3 blur = vec3(0.0);
    blur += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(-px.x, -px.y)).rgb;
    blur += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(0.0, -px.y)).rgb;
    blur += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(px.x, -px.y)).rgb;
    blur += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(-px.x, 0.0)).rgb;
    blur += col;
    blur += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(px.x, 0.0)).rgb;
    blur += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(-px.x, px.y)).rgb;
    blur += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(0.0, px.y)).rgb;
    blur += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(px.x, px.y)).rgb;
    blur /= 9.0;

    // 2) 포스터라이즈
    vec3 posterized = floor(blur * posterize_steps + 0.5) / posterize_steps;

    // 3) 웜 틴트
    posterized *= warm_tint;

    // 4) 미세 노이즈
    float n = fract(sin(dot(SCREEN_UV * 1000.0, vec2(12.9898, 78.233))) * 43758.5453);
    posterized += (n - 0.5) * grain_strength;

    COLOR = vec4(clamp(posterized, 0.0, 1.0), 1.0);
}
