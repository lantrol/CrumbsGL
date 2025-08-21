#version 450 core

uniform sampler2D atlas;

in vec2 iUvs;
in vec4 iColor;
out vec4 frag_color;

void main() {
    vec4 pixel_color = texture(atlas, iUvs);
    float alpha = 1.;

    if (pixel_color.r < 0.01) {
        alpha = 0;
    }
    pixel_color.a = alpha;
    pixel_color.xyz = vec3(pixel_color.x) * iColor.xyz;
    frag_color = pixel_color;
}
