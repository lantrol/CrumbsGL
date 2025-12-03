#+feature dynamic-literals
package GuiTree

import crgl "../"
import "core:container/queue"
import "core:container/rbtree"
import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:slice"
import "core:strings"
import gl "vendor:OpenGL"
import sdl "vendor:sdl3"

MAX_VERTEX :: 200
MAX_GLYPH :: 1000
MAX_MESH_BUFFER :: 2000

Window :: struct {
	wind_x, wind_y: i32,
	wind_w, wind_h: i32,

	// Components
	content:        Container,

	// State
	hidden:         bool,
	moving:         bool,

	// Styling
	top_bar_height: i32,
	vpadding:       i32,
	hpadding:       i32,
}

Rect :: struct {
	x, y:          i32,
	width, height: i32,
}

Component :: union {
	^Button,
	^Container,
}

Button :: struct {
	text:       string,
	using rect: Rect,
	pressed:    bool,
}

Container :: struct {
	type:           Container_Type,
	using area:     Rect,
	cont_w, cont_h: i32,
	v_offs, h_offs: i32,
	comps:          [dynamic]Component,
}

Container_Type :: enum {
	Column,
	Row,
}

Style :: struct {
	top_bar_height: i32,
	inner_padding:  i32,
}

Rect_Vertex :: [6]crgl.Vertex_Uv_Color

@(private)
gFont_data: Font_Data
@(private)
gAll_windows: map[string]Window

@(private)
gVertex_buffer: struct {
	buffer:       []crgl.Vertex_Uv_Color,
	max_capacity: i32,
	filled:       i32,
}
@(private)
gGlyph_buffer: struct {
	buffer:       []crgl.Vertex_Uv_Color,
	max_capacity: i32,
	filled:       i32,
}
@(private)
gDefault_style: Style = {
	top_bar_height = 20,
	inner_padding  = 8,
}

gui_init :: proc(font: Font_Data) {
	gVertex_buffer = {
		buffer       = make([]crgl.Vertex_Uv_Color, MAX_VERTEX),
		max_capacity = MAX_VERTEX,
		filled       = 0,
	}
	gGlyph_buffer = {
		buffer       = make([]crgl.Vertex_Uv_Color, MAX_GLYPH),
		max_capacity = MAX_GLYPH,
		filled       = 0,
	}
	gFont_data = font
}

set_font :: proc(font: Font_Data) {
	gFont_data = font
}

button_create :: proc(
	parent: ^Container,
	text: string,
	width: i32 = -1,
	height: i32 = -1,
) -> ^Button {

	button: ^Button = new(Button)
	button.text = text
	button.width = width
	button.height = height
	append(&parent.comps, button)
	return button
}

button_layout :: proc(container: ^Container, bttn: ^Button) {
	padding := gDefault_style.inner_padding
	bttn.x = container.x + container.h_offs
	bttn.y = container.y + container.v_offs

	switch container.type {
	case .Column:
		if bttn.height == -1 {
			bttn.height = i32(
				f32(container.height - padding * i32(len(container.comps) + 1)) /
				f32(len(container.comps)),
			)
		}
		if bttn.width == -1 do bttn.width = container.width - 2 * padding
		bttn.x += i32(f32(container.width - bttn.width) / 2)
		bttn.y += padding
		container.cont_w = max(container.cont_w, bttn.width + 2 * padding)
		container.cont_h += bttn.height + padding
		container.v_offs += bttn.height + padding
	case .Row:
		if bttn.width == -1 {
			bttn.width = i32(
				f32(container.width - padding * i32(len(container.comps) + 1)) /
				f32(len(container.comps)),
			)
		}
		if bttn.height == -1 do bttn.height = container.height - 2 * padding
		bttn.y += i32(f32(container.height - bttn.height) / 2)
		bttn.x += padding
		container.cont_h = max(container.cont_h, bttn.height + 2 * padding)
		container.cont_w += bttn.width + padding
		container.h_offs += bttn.width + padding
	}
}

container_create :: proc(
	parent: ^Container,
	type: Container_Type,
	width: i32,
	height: i32,
) -> ^Container {

	container: ^Container = new(Container)
	container.width = width
	container.height = height
	append(&parent.comps, container)
	return container
}

layout_update :: layout_build
layout_build :: proc(root: union {
		^Window,
		^Container,
	}) {

	container: ^Container
	switch &v in root {
	case ^Window:
		container = &v.content
		container.x = root.(^Window).wind_x
		container.y = root.(^Window).wind_y + root.(^Window).top_bar_height
		container.width = root.(^Window).wind_w
		container.height = root.(^Window).wind_h - root.(^Window).top_bar_height

		// Reset values for rebuilding
		container.cont_h = 0
		container.cont_w = 0
		container.v_offs = 0
		container.h_offs = 0
	case ^Container:
		container = v

		// Reset values for rebuilding
		container.cont_h = 0
		container.cont_w = 0
		container.v_offs = 0
		container.h_offs = 0
	}

	// Build the area that each component will use
	for &component in container.comps {
		switch &comp in component {
		case ^Button:
			button_layout(container, comp)
		case ^Container:
			comp.x = container.x + container.h_offs
			comp.y = container.y + container.v_offs

			layout_build(comp)

			padding := gDefault_style.inner_padding
			switch container.type {
			case .Column:
				container.cont_w = max(container.cont_w, comp.width + 2 * padding)
				container.cont_h += comp.height
				container.v_offs += comp.height
			case .Row:
				container.cont_h = max(container.cont_h, comp.height + 2 * padding)
				container.cont_w += comp.width
				container.h_offs += comp.width
			}
		}
	}
}

window_draw :: proc(window: ^Window) {
	gVertex_buffer.filled = 0
	gGlyph_buffer.filled = 0

	mesh := crgl.mesh_create_empty(MAX_MESH_BUFFER * size_of(crgl.Vertex_Uv_Color))
	defer crgl.mesh_delete(&mesh)

	proj := glm.mat4Ortho3d(
		left = 0,
		right = f32(crgl.gContext.window.width),
		bottom = f32(crgl.gContext.window.height),
		top = 0,
		near = 1,
		far = -1,
	)
	crgl.set_uniform(crgl.gDefShaders.rect_sh, "uProjection", proj)

	// --- Draws ---
	// Window background
	hb_rect := window_rect_to_vertex(
		{window.wind_x, window.wind_y, window.top_bar_height, window.top_bar_height},
		color = Purple_3,
	)
	tb_rect := window_rect_to_vertex(
		{
			window.wind_x + window.top_bar_height,
			window.wind_y,
			window.wind_w - window.top_bar_height,
			window.top_bar_height,
		},
		color = Purple_2,
	)
	back_rect := window_rect_to_vertex(
		Rect {
			x = window.wind_x,
			y = window.wind_y + window.top_bar_height,
			width = window.wind_w,
			height = window.wind_h,
		},
		color = Purple_1,
	)

	crgl.mesh_write(&mesh, tb_rect[:])
	crgl.mesh_render(mesh, crgl.gDefShaders.rect_sh)
	crgl.mesh_write(&mesh, hb_rect[:])
	crgl.mesh_render(mesh, crgl.gDefShaders.rect_sh)

	if window.hidden do return // Stop painting if hidden

	crgl.mesh_write(&mesh, back_rect[:])
	crgl.mesh_render(mesh, crgl.gDefShaders.rect_sh)

	// Components
	all_comps: queue.Queue(Component);defer queue.destroy(&all_comps)
	ok, err := queue.push_back(&all_comps, &window.content)

	comp: Component
	for comp, ok = queue.pop_front_safe(&all_comps);
	    ok == true;
	    comp, ok = queue.pop_front_safe(&all_comps) {

		switch &v in comp {
		case ^Button:
			rect := window_rect_to_vertex(comp.(^Button).rect, color = Purple_3)
			push_rect_vertex(comp.(^Button).rect, color = Purple_3)

			// First get default font size bbox of text
			// Then adjust scale to fit text in button width
			bb_w, bb_h := font_get_text_bbox(gFont_data, v.text, scale = 1)
			text_scale := min(f32(v.height) / gFont_data.font_size, f32(v.width) / bb_w)
			bb_w, bb_h = font_get_text_bbox(gFont_data, v.text, scale = text_scale)

			font_vert := font_get_text_quads(
				gFont_data,
				v.text,
				{v.x + i32((f32(v.width) - bb_w) / 2), v.y + i32((f32(v.height) - bb_h) / 2)},
				scale = text_scale,
			);defer delete(font_vert)
			push_text_vertex(font_vert[:])
		case ^Container:
			for &child in v.comps {
				queue.push_back(&all_comps, child)
			}
		}
	}

	crgl.mesh_write(&mesh, gVertex_buffer.buffer[:gVertex_buffer.filled])
	crgl.mesh_render(mesh, crgl.gDefShaders.rect_sh)

	crgl.mesh_write(&mesh, gGlyph_buffer.buffer[:gGlyph_buffer.filled])
	crgl.mesh_render(mesh, crgl.gDefShaders.font_sh, gFont_data.atlas_tex)
}

window_handle_events :: proc(window: ^Window) {
	hb_rect: Rect = {window.wind_x, window.wind_y, window.top_bar_height, window.top_bar_height}

	tb_rect: Rect = {
		window.wind_x + window.top_bar_height,
		window.wind_y,
		window.wind_w - window.top_bar_height,
		window.top_bar_height,
	}

	mouse_in_rect :: proc(rect: Rect) -> bool {
		x, y := crgl.get_mouse_position()
		y = crgl.gContext.window.height - y
		return x >= rect.x && x <= rect.x + rect.width && y >= rect.y && y <= rect.y + rect.height
	}

	// Hide
	if mouse_in_rect(hb_rect) && crgl.is_button_just_pressed(.LEFT) {
		window.hidden = !window.hidden
	}

	// Moving
	if mouse_in_rect(tb_rect) && crgl.is_button_just_pressed(.LEFT) {
		window.moving = true
	}

	if window.moving && crgl.is_button_pressed(.LEFT) {
		x, y := crgl.get_mouse_displacement()
		window.wind_x += x
		window.wind_y += y
	}

	if window.moving && crgl.is_button_released(.LEFT) {
		window.moving = false
	}

	layout_update(window)

	if window.hidden do return

	all_comps: queue.Queue(Component);defer queue.destroy(&all_comps)
	ok, err := queue.push_back(&all_comps, &window.content)

	comp: Component
	for comp, ok = queue.pop_front_safe(&all_comps);
	    ok == true;
	    comp, ok = queue.pop_front_safe(&all_comps) {

		switch &v in comp {
		case ^Button:
			if mouse_in_rect(v.rect) && crgl.is_button_just_pressed(.LEFT) {
				v.pressed = true
			} else {
				v.pressed = false
			}
		case ^Container:
			for &child in v.comps {
				queue.push_back(&all_comps, child)
			}
		}
	}
}

window_begin :: proc(name: string, x, y: i32, width, height: i32) -> Window {
	new_win: Window = {
		wind_x = x,
		wind_y = y,
		wind_w = width,
		wind_h = height,
		content = {type = .Column, x = x, y = y + gDefault_style.top_bar_height},
		hidden = false,
		moving = false,
		top_bar_height = gDefault_style.top_bar_height,
		vpadding = 10,
		hpadding = 10,
	}

	return new_win
}

window_rect_to_vertex :: proc(rect: Rect, uv: [2]f32 = {}, color: [4]f32 = {}) -> Rect_Vertex {
	data: Rect_Vertex

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

push_rect_vertex :: proc(rect: Rect, uv: [2]f32 = {}, color: [4]f32 = {}) {
	if gVertex_buffer.filled == gVertex_buffer.max_capacity {
		fmt.eprintln("Vertex buffer full! Not pushing rect")
		return
	}

	rect_vertex := window_rect_to_vertex(rect, uv, color)

	for i in 0 ..< len(rect_vertex) {
		gVertex_buffer.buffer[gVertex_buffer.filled + i32(i)] = rect_vertex[i]
	}
	gVertex_buffer.filled += i32(len(rect_vertex))
}

push_text_vertex :: proc(text: []Font_Quad) {
	if gGlyph_buffer.filled == gGlyph_buffer.max_capacity {
		fmt.eprintln("Vertex buffer full! Not pushing rect")
		return
	}

	for quad in text {
		for i in 0 ..< len(quad) {
			gGlyph_buffer.buffer[gGlyph_buffer.filled + i32(i)] = quad[i]
		}
		gGlyph_buffer.filled += i32(len(quad))
	}
}

mouse_in_window :: proc(wind: ^Window) -> bool {
	x, y := crgl.get_mouse_position()
	y = crgl.gContext.window.height - y

	height := wind.wind_h + wind.top_bar_height if !wind.hidden else wind.top_bar_height

	if x > wind.wind_x &&
	   x < wind.wind_x + wind.wind_w &&
	   y > wind.wind_y &&
	   y < wind.wind_y + height {
		return true
	}

	return false
}

