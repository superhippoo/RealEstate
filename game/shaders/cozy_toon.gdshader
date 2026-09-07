// Cozy Toon v2 — 더 평면적/일러스트적
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo : source_color = vec4(1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.8;
uniform float toon_steps = 3.0;
uniform float toon_softness = 0.08;  // 더 낮게 = 더 크리스프한 단계
uniform float rim_strength = 0.7;
uniform float rim_width = 0.30;
uniform vec3 rim_color : source_color = vec3(1.0, 0.90, 0.78);
uniform float warmth = 0.18;
uniform float saturation_boost = 1.55;
uniform float brightness_target = 0.42;
uniform float color_posterize = 4.0;  // 색 포스터라이즈 단계
uniform float flatness = 0.85;  // 0=원래 셰이딩, 1=완전 평면색

void fragment() {
    vec3 base = albedo.rgb;

    // 강한 채도 부스트
    float lum = dot(base, vec3(0.299, 0.587, 0.114));
    base = mix(vec3(lum), base, saturation_boost);

    // 색 포스터라이즈 (일러스트 느낌)
    base = floor(base * color_posterize + 0.5) / color_posterize;

    // 웜니스
    base.r = min(base.r * (1.0 + warmth * 0.4), 1.0);
    base.b = max(base.b * (1.0 - warmth * 0.25), 0.0);

    ALBEDO = base;
    ROUGHNESS = roughness;
    METALLIC = 0.0;
}

void light() {
    float NdotL = dot(NORMAL, LIGHT);
    float NdotV = dot(NORMAL, VIEW);

    // 2단 톤램프 (더 극단적 = 일러스트)
    float ramp = smoothstep(0.35 - toon_softness, 0.35 + toon_softness, NdotL);

    // flatness: 셰이딩을 평면색으로 압축
    vec3 flat_color = ALBEDO;  // 완전 평면
    vec3 lit_color = LIGHT_COLOR * ALBEDO * ramp * brightness_target;
    vec3 result = mix(lit_color, flat_color * 0.6, flatness);

    // 하이라이트 (밝은 면)
    float hi = smoothstep(0.9, 1.0, NdotL);
    result += ALBEDO * hi * 0.15;

    // 림라이트
    float rim = 1.0 - abs(NdotV);
    rim = smoothstep(1.0 - rim_width, 1.0, rim);
    result += rim_color * rim * rim_strength;

    DIFFUSE_LIGHT = result;
    SPECULAR_LIGHT = vec3(0.0);
}
