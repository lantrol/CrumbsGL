package CrumbsGL

sh_get_default_font_shader :: proc() -> u32 {
	return gContext.defFontSh
}

@(private)
gDefColorVS: string = `
#version 450 core

struct VertexData {
	float position[3];
	float color[3];
};

layout(binding = 0, std430) readonly buffer ssbo1 {
	VertexData data[];
};

out vec3 iColor;

vec3 getPosition(int index) {
    return vec3(
        data[index].position[0],
        data[index].position[1],
        data[index].position[2]
    );
}

vec3 getColor(int index) {
    return vec3(
        data[index].color[0],
        data[index].color[1],
        data[index].color[2]
    );
}

void main() {
    iColor = getColor(gl_VertexID);
    gl_Position = vec4(getPosition(gl_VertexID), 1.0);
}
`


@(private)
gDefColorFS: string = `
#version 450 core

in vec3 iColor;
out vec4 frag_color;

void main() {
	frag_color = vec4(iColor, 1.);
}

`


@(private)
gDefUvsVS: string = `
#version 450 core

struct VertexData {
	float position[3];
	float uv[2];
};

layout(binding = 0, std430) readonly buffer ssbo1 {
	VertexData data[];
};

out vec2 iUvs;

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

void main() {
    iUvs = getUV(gl_VertexID);
    gl_Position = vec4(getPosition(gl_VertexID), 1.0);
}
`


@(private)
gDefFontFS: string = `
#version 450 core

uniform sampler2D atlas;

in vec2 iUvs;
out vec4 frag_color;

void main() {
	vec4 pixel_color = texture(atlas, iUvs);
	float alpha = 1.;

	if (pixel_color.r < 0.01) {
		alpha = 0;
	}
	pixel_color.a = alpha;
	frag_color = vec4(pixel_color.x, pixel_color.x, pixel_color.x, alpha);
}

`
