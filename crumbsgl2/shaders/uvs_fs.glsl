#version 450 core

uniform sampler2D texture0;

in vec2 iUvs;
out vec4 frag_color;

void main() {
    frag_color = texture(texture0, iUvs);
}
