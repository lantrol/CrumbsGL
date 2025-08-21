#+feature dynamic-literals
package Gui

import crgl "../"
import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:slice"
import "core:strings"
import gl "vendor:OpenGL"
import sdl "vendor:sdl3"

Gui_Window :: struct {
	x, y:           i32,
	width, height:  i32,
	// State
	hidden:         bool,
	moving:         bool,
	// Styling
	top_bar_height: i32,
	vpadding:       i32,
	hpadding:       i32,
}

Gui_Rect :: struct {
	x, y:          i32,
	width, height: i32,
}

Gui_Style :: struct {
	top_bar_height: i32,
}

@(private)
gAll_windows: map[string]Gui_Window
@(private)
gActive_window: Gui_Window
@(private)
gDefault_style: Gui_Style = {
	top_bar_height = 10,
}

window_begin :: proc(name: string, x, y: i32, width, height: i32) {
	if gActive_window != {} {
		return
	}

	if name not_in gAll_windows {
		new_win: Gui_Window = {
			x              = x,
			y              = y,
			width          = width,
			height         = height,
			hidden         = false,
			moving         = false,
			top_bar_height = gDefault_style.top_bar_height,
		}
		gAll_windows[name] = new_win
	}
	gActive_window = gAll_windows[name]
}

window_end :: proc() {
	gActive_window = {}
}

window_rect_to_vertex :: proc(rect: Gui_Rect) -> [6]crgl.Vertex_Uv_Color {
	data: [6]crgl.Vertex_Uv_Color

	data = {
		{pos = {f32(rect.x), f32(rect.y + rect.height), 0.}},
		{pos = {f32(rect.x), f32(rect.y), 0.}},
		{pos = {f32(rect.x + rect.height), f32(rect.y + rect.height), 0.}},
		{pos = {f32(rect.x), f32(rect.y), 0.}},
		{pos = {f32(rect.x + rect.height), f32(rect.y + rect.height), 0.}},
		{pos = {f32(rect.x + rect.height), f32(rect.y), 0.}},
	}

	return data
}
