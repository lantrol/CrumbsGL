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

GuiRectData :: [6]GuiRect

GuiWindowContext :: struct {
	x, y:          i32,
	width, height: i32,
	color:         [3]f32,
	voffset:       i32,
	hidden:        bool,
	moving:        bool,
	rectCount:     i32,
}

GuiOptions :: struct {
	elemHeight:   i32,
	topBarHeight: i32,
	vpadding:     i32,
}

@(private = "file")
allGuiWindows: map[string]GuiWindowContext
@(private = "file")
activeWindow: ^GuiWindowContext
@(private = "file")
guiOptions := GuiOptions {
	elemHeight   = 40,
	topBarHeight = 40,
	vpadding     = 10,
}
@(private = "file")
guiRectsArray: [200]GuiRect

gui_draw :: proc(rect: GuiRect) {
	meshData: [6]GuiVertex = gui_vertex_from_rect(rect)
	mesh := createMesh(meshData[:])
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

gui_begin_window :: proc(name: string) {
	if name not_in allGuiWindows {
		newWindow := GuiWindowContext {
			10,
			10,
			i32(0.4 * f32(gContext.window.width)),
			0,
			{0.5, 0.5, 0.5},
			guiOptions.vpadding,
			false,
			false,
			0,
		}
		allGuiWindows[name] = newWindow
	}
	activeWindow = &allGuiWindows[name]

	// Handle window movement
	topBar := GuiRect {
		activeWindow.x,
		activeWindow.y,
		activeWindow.width,
		guiOptions.topBarHeight,
		{0, 0, 1},
	}
	if gui_is_pressed(topBar) && !activeWindow.moving {
		activeWindow.moving = true
	} else if activeWindow.moving && is_button_pressed(.LEFT) {
		mouseX, mouseY: i32 = get_mouse_displacement()
		activeWindow.x += mouseX
		activeWindow.y += mouseY
	} else {
		activeWindow.moving = false
	}
}

gui_end_window :: proc() {
	// Window drawing
	topBar := GuiRect {
		activeWindow.x,
		activeWindow.y,
		activeWindow.width,
		guiOptions.topBarHeight,
		{0, 0, 1},
	}
	gui_draw(topBar)

	windowRect := GuiRect {
		activeWindow.x,
		activeWindow.y + guiOptions.topBarHeight,
		activeWindow.width,
		activeWindow.voffset,
		{0.4, 0.4, 0.4},
	}
	gui_draw(windowRect)

	// Window items drawing
	for rect, index in guiRectsArray {
		if i32(index) == activeWindow.rectCount do break
		gui_draw(rect)
	}

	activeWindow.rectCount = 0
	activeWindow.voffset = guiOptions.vpadding
}

gui_button :: proc() -> bool {
	x: i32 = activeWindow.x + guiOptions.vpadding
	y: i32 = activeWindow.y + guiOptions.topBarHeight + activeWindow.voffset
	width: i32 = activeWindow.width - 2 * guiOptions.vpadding
	height: i32 = guiOptions.elemHeight

	if activeWindow.rectCount == len(guiRectsArray) {
		fmt.println("Error: max rect count reached")
	}

	rect := GuiRect{x, y, width, height, {1., 0., 0.}}
	guiRectsArray[activeWindow.rectCount] = rect

	activeWindow.voffset += height + guiOptions.vpadding
	activeWindow.rectCount += 1

	return gui_is_pressed(rect)
}

@(private)
gui_vertex_from_rect :: proc(rect: GuiRect) -> [6]GuiVertex {
	windX, windY: i32
	_ = sdl.GetWindowSize(gContext.window.window, &windX, &windY)
	glX: f32 = (f32(rect.x) / f32(windX)) * 2 - 1
	glY: f32 = (1 - f32(rect.y) / f32(windY)) * 2 - 1
	glWidth: f32 = (f32(rect.width) / f32(windX)) * 2
	glHeight: f32 = (f32(rect.height) / f32(windY)) * 2
	data: [6]GuiVertex = {
		{{glX, glY, 0.}, rect.color, {0, 0}},
		{{glX + glWidth, glY, 0.}, rect.color, {1, 0}},
		{{glX, glY - glHeight, 0.}, rect.color, {0, 1}},
		{{glX + glWidth, glY, 0.}, rect.color, {1, 0}},
		{{glX, glY - glHeight, 0.}, rect.color, {0, 1}},
		{{glX + glWidth, glY - glHeight, 0.}, rect.color, {1, 1}},
	}
	return data
}

@(private = "file")
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


@(private = "file")
defaultFS: string = `
#version 450 core

in vec2 iUvs;
in vec3 iColor;
out vec4 frag_color;

void main() {
	frag_color = vec4(iColor, 1.);
}

`
