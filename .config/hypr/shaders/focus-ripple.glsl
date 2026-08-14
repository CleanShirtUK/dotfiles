#version 320 es
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;
uniform float effect_time;
uniform vec2 surface_size;

void main() {
    float left = v_texcoord.x;
    float right = 1.0 - v_texcoord.x;
    float top = v_texcoord.y;
    float bottom = 1.0 - v_texcoord.y;
    float edge_distance = min(min(left, right), min(top, bottom));
    vec2 direction = left <= min(min(right, top), bottom) ? vec2(1.0, 0.0) :
        right <= min(min(top, bottom), left) ? vec2(-1.0, 0.0) :
        top <= bottom ? vec2(0.0, 1.0) : vec2(0.0, -1.0);
    float size_scale = clamp(1100.0 / max(surface_size.y, 1.0), 0.75, 2.5);
    float speed = exp(-effect_time * 4.0) * smoothstep(0.7, 0.35, effect_time);
    float wave_phase = edge_distance * 34.0 - effect_time * 18.0;
    float front = exp(-pow((edge_distance - effect_time * 0.32) * 10.0, 2.0));
    float edge_hit = exp(-effect_time * 8.0) * exp(-edge_distance * 70.0);
    float wave = sin(wave_phase) * front + edge_hit;
    float envelope = exp(-edge_distance * 2.5) * speed;
    vec2 offset = direction * wave * envelope * 0.0028 * size_scale;

    float chroma = (front + edge_hit) * speed * 0.0014 * size_scale;
    vec2 red_offset = offset + direction * chroma * 1.2;
    vec2 blue_offset = offset - direction * chroma;

    float red = texture(tex, v_texcoord + red_offset).r;
    float green = texture(tex, v_texcoord + offset).g;
    float blue = texture(tex, v_texcoord + blue_offset).b;
    float alpha = texture(tex, v_texcoord + offset).a;
    fragColor = vec4(red, green, blue, alpha);
}
