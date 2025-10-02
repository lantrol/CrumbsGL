#version 450 core

struct VertexData {
    float position[3];
    float uv[2];
    float color[4];
};

layout(binding = 0, std430) readonly buffer ssbo1 {
    VertexData data[];
};

uniform mat4 uProjection;

out vec2 iUvs;
out vec4 iColor;

vec3 getPosition(int index) {
    return vec3(
        data[index].position[0],
        data[index].position[1],
        data[index].position[2]
    );
}

vec2 getUV(int index) {
    return vec2(
        data[index].uv[0],
        data[index].uv[1]
    );
}

vec4 getColor(int index) {
    return vec4(
        data[index].color[0],
        data[index].color[1],
        data[index].color[2],
        data[index].color[3]
    );
}

void main() {
    iUvs = getUV(gl_VertexID);
    iColor = getColor(gl_VertexID);
    gl_Position = uProjection * vec4(getPosition(gl_VertexID), 1.0);
}
