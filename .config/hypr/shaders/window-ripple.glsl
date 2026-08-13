#version 320 es
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;
uniform float time;
uniform float effect_time;
uniform vec2 surface_size;

void main() {
    vec2 center = vec2(0.5);
    vec2 aspect = vec2(surface_size.x / max(surface_size.y, 1.0), 1.0);
    vec2 from_center = (v_texcoord - center) * aspect;
    float distance_from_center = length(from_center);
    float size_scale = clamp(1100.0 / max(surface_size.y, 1.0), 0.75, 2.5);
    float speed = exp(-effect_time * 2.8);
    float radius = distance_from_center;
    float wave_phase = radius * 34.0 - effect_time * 18.0;
    // Begin as a tight impulse at the exact center, then expand slowly enough
    // for compact windows to show the whole connected wave.
    float front = exp(-pow((radius - effect_time * 0.52) * 9.0, 2.0));
    float center_hit = exp(-effect_time * 6.0) * exp(-radius * radius * 90.0);
    float wave = sin(wave_phase) * front + center_hit;
    float envelope = smoothstep(1.0, 0.0, radius) * speed;
    vec2 direction = normalize(from_center + vec2(0.0001));
    vec2 offset = direction * wave * envelope * 0.018 * size_scale;

    // Split the colour channels at the same wavefront for a connected
    // prism-like diffraction fringe.
    float chroma = (front + center_hit) * speed * 0.0045 * size_scale;
    vec2 red_offset = offset + direction * chroma * 1.25;
    vec2 blue_offset = offset - direction * chroma;

    float red = texture(tex, v_texcoord + red_offset).r;
    float green = texture(tex, v_texcoord + offset).g;
    float blue = texture(tex, v_texcoord + blue_offset).b;
    float alpha = texture(tex, v_texcoord + offset).a;
    fragColor = vec4(red, green, blue, alpha);
}
