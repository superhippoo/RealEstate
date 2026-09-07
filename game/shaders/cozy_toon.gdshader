// Cozy Toon Shader — 아기자기한 모바일 게임 룩
// 3단 톤램프 + 림라이트 + 따뜻한 색보정
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.8;
uniform float toon_steps = 3.0;
uniform float toon_softness = 0.15;
uniform float rim_strength = 0.6;
uniform float rim_width = 0.35;
uniform vec3 rim_color : source_color = vec3(1.0, 0.92, 0.82);
uniform float warmth = 0.15;
uniform float saturation_boost = 1.55;
uniform float brightness_target = 0.35;

void fragment() {
    vec3 base_color = albedo.rgb;

    // 채도 부스트
    float lum = dot(base_color, vec3(0.299, 0.587, 0.114));
    base_color = mix(vec3(lum), base_color, saturation_boost);

    // 웜니스 (R 채널 미세 상향, B 채널 미세 하향)
    base_color.r = min(base_color.r * (1.0 + warmth * 0.5), 1.0);
    base_color.b = max(base_color.b * (1.0 - warmth * 0.3), 0.0);

    ALBEDO = base_color;
    ROUGHNESS = roughness;
    METALLIC = 0.0;
}

void light() {
    vec3 n = NORMAL;
    vec3 v = VIEW;
    vec3 l = LIGHT;

    float NdotL = dot(n, l);
    float NdotV = dot(n, v);

    // 3단 톤램프 (부드러운 계단)
    float ramp;
    if (toon_steps < 2.5) {
        ramp = smoothstep(0.0, toon_softness, NdotL);
    } else {
        float step1 = 0.35;
        float step2 = 0.7;
        ramp = smoothstep(step1 - toon_softness, step1 + toon_softness, NdotL) * 0.5
             + smoothstep(step2 - toon_softness, step2 + toon_softness, NdotL) * 0.5;
    }

    // 기본 조명 (어둡게 시작 → 톤램프로 밝아짐)
    vec3 diffuse = LIGHT_COLOR * ALBEDO * ramp * brightness_target;

    // 하이라이트 (밝은 면에 살짝)
    float highlight = smoothstep(0.85, 1.0, NdotL);
    diffuse += LIGHT_COLOR * ALBEDO * highlight * 0.3;

    // 림라이트 (가장자리 따뜻한 빛 — "아기자기" 핵심)
    float rim = 1.0 - abs(NdotV);
    rim = smoothstep(1.0 - rim_width, 1.0, rim);
    diffuse += rim_color * rim * rim_strength;

    DIFFUSE_LIGHT = diffuse;

    // 스페큘러 최소화 (부드러운 느낌)
    SPECULAR_LIGHT = vec3(0.0);
}
