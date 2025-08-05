package CrumbsGL

import "core:fmt"
import "core:strings"
import gl "vendor:OpenGL"

Shader :: struct {
	id:       u32,
	type:     Shader_Type,
	uniforms: map[string]i32,
}

Shader_Type :: enum {
	render,
	compute,
}

sh_get_default_font_shader :: proc() -> u32 {
	return gContext.defFontSh
}

sh_get_default_rect_shader :: proc() -> u32 {
	return gContext.defRectSh
}

sh_load_files :: proc(vertexSh, fragmentSh: string) -> Shader {
	program, ok := gl.load_shaders_file(vertexSh, fragmentSh)
	if !ok {
		fmt.eprintln("ERROR: couldnt load shader program")
	}

	sh: Shader = {
		id       = program,
		type     = .render,
		uniforms = make(map[string]i32),
	}

	// Uniform reading
	paramCount: i32
	gl.GetProgramiv(program, gl.ACTIVE_UNIFORMS, &paramCount)

	for i in 0 ..< paramCount {
		name: [128]u8
		length, size: i32
		type: u32
		location: i32

		gl.GetActiveUniform(
			program,
			u32(i),
			size_of(name),
			&length,
			&size,
			&type,
			raw_data(name[:]),
		)
		location = gl.GetUniformLocation(program, cstring(raw_data(name[:])))
		sh.uniforms[strings.clone_from(name[:length])] = location

		// TODO: check type
	}

	return sh
}

sh_delete_program :: proc(sh: ^Shader) {
	gl.DeleteProgram(sh.id)
	delete(sh.uniforms)
	sh^ = {}
}

@(private)
gDefColorVS: string = `
#version 450 core

struct VertexData {
	float position[3];
	float color[4];
};

layout(binding = 0, std430) readonly buffer ssbo1 {
	VertexData data[];
};

out vec4 iColor;

vec3 getPosition(int index) {
    return vec3(
        data[index].position[0],
        data[index].position[1],
        data[index].position[2]
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
    iColor = getColor(gl_VertexID);
    gl_Position = vec4(getPosition(gl_VertexID), 1.0);
}
`


@(private)
gDefColorFS: string = `
#version 450 core

in vec4 iColor;
out vec4 frag_color;

void main() {
	frag_color = iColor;
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
gDefUvsColorVS: string = `
#version 450 core

struct VertexData {
	float position[3];
	float uv[2];
	float color[4];
};

layout(binding = 0, std430) readonly buffer ssbo1 {
	VertexData data[];
};

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
    gl_Position = vec4(getPosition(gl_VertexID), 1.0);
}
`


@(private)
gDefFontFS: string = `
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

`


@(private)
gDefRectFS: string = `
#version 450 core

in vec2 iUvs;
in vec4 iColor;
out vec4 frag_color;

void main() {
	frag_color = iColor;
}

`
