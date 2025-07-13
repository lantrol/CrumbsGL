package CrumbsGL

import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:slice"
import "core:strings"
import gl "vendor:OpenGL"
import sdl "vendor:sdl3"

GuiRect :: struct {
	x, y:          i32,
	width, height: i32,
	color:         [3]f32,
}

GuiVertex :: struct {
	position: [3]f32,
	color:    [3]f32,
	uv:       [2]f32,
}

allGuiWindows: map[string]GuiRect
activeWindow: GuiRect = {}

gui_draw :: proc(rect: GuiRect) {
	meshData: []GuiVertex = gui_vertex_from_rect(rect)
	mesh := createMesh(meshData)
	program, ok := gl.load_shaders_source(defaultVS, defaultFS)
	renderMesh(mesh, program, mode = gl.TRIANGLES)
	deleteMesh(&mesh)
}

gui_is_pressed :: proc(rect: GuiRect) -> bool {
	if !is_button_just_pressed(.LEFT) do return false
	x, y := get_mouse_position()
	if x > rect.x && x < rect.x + rect.width && y > rect.y && y < rect.y + rect.height {
		return true
	}
	return false
}

@(private)
gui_vertex_from_rect :: proc(rect: GuiRect) -> []GuiVertex {
	windX, windY: i32
	_ = sdl.GetWindowSize(gContext.window.window, &windX, &windY)
	glX: f32 = (f32(rect.x) / f32(windX)) * 2 - 1
	glY: f32 = (1 - f32(rect.y) / f32(windY)) * 2 - 1
	glWidth: f32 = f32(rect.width) / f32(windX)
	glHeight: f32 = f32(rect.height) / f32(windY)
	data: []GuiVertex = {
		{{glX, glY, 0.}, rect.color, {0, 0}},
		{{glX + glWidth, glY, 0.}, rect.color, {1, 0}},
		{{glX, glY - glHeight, 0.}, rect.color, {0, 1}},
		{{glX + glWidth, glY, 0.}, rect.color, {1, 0}},
		{{glX, glY - glHeight, 0.}, rect.color, {0, 1}},
		{{glX + glWidth, glY - glHeight, 0.}, rect.color, {1, 1}},
	}
	return data
}

@(private)
defaultVS: string = `
#version 450 core

struct VertexData {
	float position[3];
	float color[3];
	float uv[2];
};

layout(binding = 0, std430) readonly buffer ssbo1 {
	VertexData data[];
};

out vec2 iUvs;
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
vec2 getUV(int index) {
    return vec2(
        data[index].uv[0],
        data[index].uv[1]
    );
}

void main() {
    iUvs = getUV(gl_VertexID);
    iColor = getColor(gl_VertexID);
    gl_Position = vec4(getPosition(gl_VertexID), 1.0);
}
`


defaultFS: string = `
#version 450 core

in vec2 iUvs;
in vec3 iColor;
out vec4 frag_color;

void main() {
	frag_color = vec4(iColor, 1.);
}

`

