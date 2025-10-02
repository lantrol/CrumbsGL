#+feature dynamic-literals
package Gui

import crgl "../"
import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:strings"
import gl "vendor:OpenGL"
import sdl "vendor:sdl3"

MAX_VERTEX :: 200
MAX_GLYPH :: 1000

Gui_Window :: struct {
	wind_x, wind_y:          i32,
	wind_width, wind_height: i32,
	using box:               Gui_Box,
	// State
	hidden:                  bool,
	moving:                  bool,
	// Styling
	top_bar_height:          i32,
	vpadding:                i32,
	hpadding:                i32,
}

Gui_Rect :: struct {
	x, y:          i32,
	width, height: i32,
}

Gui_Box :: Gui_Rect

Gui_Rect_Vertex :: [6]crgl.Vertex_Uv_Color

Gui_Style :: struct {
	top_bar_height: i32,
	inner_padding:  i32,
}
@(private)
gFont_data: Font_Data
@(private)
gAll_windows: map[string]Gui_Window
//@(private)
gActive_window: ^Gui_Window
@(private)
gActive_box: Gui_Box // unused for now
@(private)
gVertex_buffer: struct {
	buffer:       []Gui_Rect_Vertex,
	max_capacity: i32,
	filled:       i32,
}
@(private)
gGlyph_buffer: struct {
	buffer:       []Gui_Rect_Vertex,
	max_capacity: i32,
	filled:       i32,
}

@(private)
gDefault_style: Gui_Style = {
	top_bar_height = 20,
	inner_padding  = 8,
}

gui_init :: proc() {
	gVertex_buffer = {
		buffer       = make([]Gui_Rect_Vertex, MAX_VERTEX),
		max_capacity = MAX_VERTEX,
		filled       = 0,
	}
	gGlyph_buffer = {
		buffer       = make([]Gui_Rect_Vertex, MAX_GLYPH),
		max_capacity = MAX_GLYPH,
		filled       = 0,
	}
}

window_set_font :: proc(font: Font_Data) {
	gFont_data = font
}

window_begin :: proc(name: string, x, y: i32, width, height: i32) {
	if gActive_window != {} {
		return
	}

	if name not_in gAll_windows {
		new_win: Gui_Window = {
			wind_x = x,
			wind_y = y,
			wind_width = width,
			wind_height = height,
			box = {x = x, y = y + gDefault_style.top_bar_height, width = width, height = height},
			hidden = false,
			moving = false,
			top_bar_height = gDefault_style.top_bar_height,
		}
		gAll_windows[name] = new_win
	}
	gActive_window = &gAll_windows[name]

	hb_rect: Gui_Rect = {
		gActive_window.wind_x,
		gActive_window.wind_y,
		gActive_window.top_bar_height,
		gActive_window.top_bar_height,
	}

	tb_rect: Gui_Rect = {
		gActive_window.wind_x + gActive_window.top_bar_height,
		gActive_window.wind_y,
		gActive_window.wind_width - gActive_window.top_bar_height,
		gActive_window.top_bar_height,
	}

	// Hide
	if mouse_in_rect(hb_rect) && crgl.is_button_just_pressed(.LEFT) {
		gActive_window.hidden = !gActive_window.hidden
	}

	// Moving
	if mouse_in_rect(tb_rect) && crgl.is_button_just_pressed(.LEFT) {
		gActive_window.moving = true
	}

	if gActive_window.moving && crgl.is_button_pressed(.LEFT) {
		x, y := crgl.get_mouse_displacement()
		gActive_window.wind_x += x
		gActive_window.wind_y += y
		gActive_window.x = gActive_window.wind_x
		gActive_window.y = gActive_window.wind_y + gDefault_style.top_bar_height
	}

	if gActive_window.moving && crgl.is_button_released(.LEFT) {
		gActive_window.moving = false
	}

	// Clear used bbox size
	gActive_window.box = {
		x      = gActive_window.wind_x,
		y      = gActive_window.wind_y + gDefault_style.top_bar_height,
		width  = gActive_window.width,
		height = gActive_window.height,
	}
}

// For now I'll do multiple draw calls reusing the buffer
// Later all vertex data should be made in one single draw call
window_end :: proc() {
	hb_rect: Gui_Rect = {
		gActive_window.wind_x,
		gActive_window.wind_y,
		gActive_window.top_bar_height,
		gActive_window.top_bar_height,
	}
	hide_button: Gui_Rect_Vertex = window_rect_to_vertex(hb_rect, color = Purple_3)

	tb_rect: Gui_Rect = {
		gActive_window.wind_x + gActive_window.top_bar_height,
		gActive_window.wind_y,
		gActive_window.wind_width - gActive_window.top_bar_height,
		gActive_window.top_bar_height,
	}
	top_bar: Gui_Rect_Vertex = window_rect_to_vertex(tb_rect, color = Purple_2)

	wnd_rect: Gui_Rect = {
		gActive_window.wind_x,
		gActive_window.wind_y + gActive_window.top_bar_height,
		gActive_window.wind_width,
		gActive_window.wind_height,
	}
	window_vert: Gui_Rect_Vertex = window_rect_to_vertex(wnd_rect, color = Purple_1)

	mesh := crgl.mesh_create(hide_button[:])
	proj := glm.mat4Ortho3d(
		left = 0,
		right = f32(crgl.gContext.window.width),
		bottom = f32(crgl.gContext.window.height),
		top = 0,
		near = 1,
		far = -1,
	)

	crgl.set_uniform(crgl.gDefShaders.rect_sh, "uProjection", proj)
	crgl.mesh_render(mesh, crgl.gDefShaders.rect_sh)

	crgl.mesh_write(&mesh, top_bar[:])
	crgl.mesh_render(mesh, crgl.gDefShaders.rect_sh)

	// Rectangle drawing
	if !gActive_window.hidden {
		crgl.mesh_write(&mesh, window_vert[:])
		crgl.mesh_render(mesh, crgl.gDefShaders.rect_sh)

		for i in 0 ..< gVertex_buffer.filled {
			crgl.mesh_write(&mesh, gVertex_buffer.buffer[i][:])
			crgl.mesh_render(mesh, crgl.gDefShaders.rect_sh)
		}
	}

	// Font drawing
	if !gActive_window.hidden {
		for i in 0 ..< gGlyph_buffer.filled {
			crgl.mesh_write(&mesh, gGlyph_buffer.buffer[i][:])
			crgl.mesh_render(mesh, crgl.gDefShaders.font_sh, gFont_data.atlas_tex)
		}
	}

	crgl.mesh_delete(&mesh)

	gActive_window = {}
	gVertex_buffer.filled = 0
	gGlyph_buffer.filled = 0
}

window_vsplit :: proc(box: union {
		Gui_Window,
		Gui_Box,
	}, ratio: f32) -> (split1, split2: Gui_Box) {

	full_box: Gui_Box = {}
	switch v in box {
	case Gui_Window:
		full_box.x = v.x
		full_box.y = v.y
		full_box.width = v.width
		full_box.height = v.height
	case Gui_Box:
		full_box = v
	}

	split1 = {
		x      = full_box.x,
		y      = full_box.y,
		width  = i32(f32(full_box.width) * ratio),
		height = full_box.height,
	}
	split2 = {
		x      = full_box.x + i32(f32(full_box.width) * ratio),
		y      = full_box.y,
		width  = i32(f32(full_box.width) * ratio),
		height = full_box.height,
	}

	return split1, split2
}

window_rect_to_vertex :: proc(
	rect: Gui_Rect,
	uv: [2]f32 = {},
	color: [4]f32 = {},
) -> Gui_Rect_Vertex {
	data: Gui_Rect_Vertex

	data = {
		{pos = {f32(rect.x), f32(rect.y + rect.height), 0.}, uv = uv, color = color},
		{pos = {f32(rect.x), f32(rect.y), 0.}, uv = uv, color = color},
		{pos = {f32(rect.x + rect.width), f32(rect.y + rect.height), 0.}, uv = uv, color = color},
		{pos = {f32(rect.x), f32(rect.y), 0.}, uv = uv, color = color},
		{pos = {f32(rect.x + rect.width), f32(rect.y + rect.height), 0.}, uv = uv, color = color},
		{pos = {f32(rect.x + rect.width), f32(rect.y), 0.}, uv = uv, color = color},
	}

	return data
}

button_create :: proc(text: string, color: Color = Purple_3) -> (pressed: bool) {
	// Temp fixed size values
	btn_height: i32 = 30

	btn_rect: Gui_Rect = {
		x      = gActive_window.x + gDefault_style.inner_padding,
		y      = gActive_window.y + gDefault_style.inner_padding,
		width  = gActive_window.width - 2 * gDefault_style.inner_padding,
		height = btn_height,
	}
	push_rect_vertex(btn_rect, color = color)

	font_scale := f32(btn_height) / gFont_data.font_size
	bbox_w, bbox_h := font_get_text_bbox(gFont_data, text, scale = font_scale)
	pos_x: i32 = btn_rect.x + i32((f32(btn_rect.width) - bbox_w) / 2.)
	pos_y: i32 = btn_rect.y + i32((f32(btn_rect.height) - bbox_h) / 2.)
	text_quads := font_get_text_quads(
		gFont_data,
		text,
		position = {pos_x, pos_y},
		scale = font_scale,
	)
	for quad in text_quads {
		if gGlyph_buffer.filled != gGlyph_buffer.max_capacity {
			gGlyph_buffer.buffer[gGlyph_buffer.filled] = quad
			gGlyph_buffer.filled += 1
		} else {
			break
		}
	}
	delete(text_quads)

	gActive_window.y += btn_rect.height + gDefault_style.inner_padding
	gActive_window.height -= btn_rect.height + gDefault_style.inner_padding

	return mouse_in_rect(btn_rect) && crgl.is_button_just_pressed(.LEFT)
}

debug_draw_box :: proc(box: Gui_Box, color: [4]f32 = {1, 1, 1, 1}) {
	push_rect_vertex(box, color = color)
}

push_rect_vertex :: proc(rect: Gui_Rect, uv: [2]f32 = {}, color: [4]f32 = {}) {
	if gVertex_buffer.filled == gVertex_buffer.max_capacity {
		fmt.eprintln("Vertex buffer full! Not pushing rect")
		return
	}

	gVertex_buffer.buffer[gVertex_buffer.filled] = window_rect_to_vertex(rect, uv, color)
	gVertex_buffer.filled += 1
}

mouse_in_rect :: proc(rect: Gui_Rect) -> bool {
	x, y := crgl.get_mouse_position()
	y = crgl.gContext.window.height - y
	return x >= rect.x && x <= rect.x + rect.width && y >= rect.y && y <= rect.y + rect.height
}
