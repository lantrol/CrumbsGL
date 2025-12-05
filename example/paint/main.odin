package main

import crgl "../../crumbsgl"
import gui "../../crumbsgl/gui-tree"
import "core:fmt"
import "core:math"
import glm "core:math/linalg/glsl"
import "core:mem"
import "core:slice"
import gl "vendor:OpenGL"
import sdl "vendor:sdl3"


main :: proc() {
	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				total: int = 0
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
					total += entry.size
				}
				fmt.println(total)
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

	window, ok := crgl.window_init(
		name = "Paint",
		width = 800,
		height = 800,
		GLmajor = 4,
		GLminor = 5,
	);defer crgl.window_delete(&window)

	if !ok {
		fmt.eprintln("ERROR: Coulnt create window")
		return
	}
	crgl.window_enable_blending()

	font, f_ok := gui.font_atlas_from_file("../../crumbsgl/gui-tree/fonts/IBMPlexSans-Regular.ttf")
	gui.gui_init(font)

	stroke_width: f32 = 8
	all_strokes: [dynamic]Stroke
	curr_stroke: ^Stroke
	state: enum {
		Stop,
		Drawing,
	}
	blocked: bool = false

	canvass_w: f32 = 800
	canvass_h: f32 = 800
	canvass_scale: f32 = 1.
	canvass_x: f32 = 0
	canvass_y: f32 = 0

	// Build gui
	gui_wind := gui.window_begin("1", 0, 0, 150, 250)
	white_b := gui.button_create(&gui_wind.content, "White")
	red_b := gui.button_create(&gui_wind.content, "Red")
	green_b := gui.button_create(&gui_wind.content, "Green")
	blue_b := gui.button_create(&gui_wind.content, "Blue")
	clear_b := gui.button_create(&gui_wind.content, "Clear")

	color: [4]f32 = {1., 1., 1., 1.}

	loop: for {
		crgl.handle_events()
		if crgl.has_quit() do break loop
		if crgl.key_is_state(sdl.K_ESCAPE, .JustPressed) do break loop

		// Paint logic
		// -- Block painting if moving camera or in gui
		blocked = false
		if crgl.is_modifier_pressed(.LCTRL) do blocked = true
		if crgl.is_modifier_pressed(.LCTRL) && crgl.is_button_pressed(.LEFT) {
			dx, dy := crgl.get_mouse_displacement()
			canvass_x -= canvass_scale * f32(dx)
			canvass_y += canvass_scale * f32(dy)
		}
		if gui.mouse_in_window(&gui_wind) do blocked = true

		// -- Start painting
		if crgl.is_button_just_pressed(.LEFT) && state == .Stop && !blocked {
			state = .Drawing
			str: Stroke
			str.color = color
			append(&all_strokes, str)
			curr_stroke = &all_strokes[len(all_strokes) - 1]
			x, y := crgl.get_mouse_position()
			point: crgl.Point = {
				f32(x) * canvass_scale + canvass_x,
				f32(y) * canvass_scale + canvass_y,
			}
			stroke_append_point(curr_stroke, point)
		}

		// -- Add points while painting
		if crgl.is_button_pressed(.LEFT) && state == .Drawing && !blocked {
			disp_x, disp_y := crgl.get_mouse_displacement()
			if disp_x == 0 && disp_y == 0 {
				continue
			}
			x, y := crgl.get_mouse_position()
			point: crgl.Point = {
				f32(x) * canvass_scale + canvass_x,
				f32(y) * canvass_scale + canvass_y,
			}
			stroke_append_point(curr_stroke, point)
		}

		// -- End stroke
		if crgl.is_button_released(.LEFT) && state == .Drawing && !blocked {
			state = .Stop
			curr_stroke = nil
		}

		// Zoom to mouse position
		mx, my := crgl.get_mouse_position()
		scroll := crgl.get_mouse_scroll()
		zoom_val := canvass_scale * 0.1
		canvass_scale -= zoom_val * f32(scroll)
		canvass_x += zoom_val * f32(scroll) * f32(mx)
		canvass_y += zoom_val * f32(scroll) * f32(my)

		// Gui handling
		gui.window_handle_events(&gui_wind)
		if white_b.pressed do color = {1., 1., 1., 1.}
		if red_b.pressed do color = {1., 0., 0., 1.}
		if green_b.pressed do color = {0., 1., 0., 1.}
		if blue_b.pressed do color = {0., 0., 1., 1.}
		if clear_b.pressed {
			for stroke in all_strokes {
				delete(stroke.points)
			}
			clear(&all_strokes)
		}

		// Draw
		crgl.window_clear_color(.2, .2, .2, 1.)

		// Projection of canvass size to screen
		proj := glm.mat4Ortho3d(
			left = 0 + canvass_x,
			right = canvass_w * canvass_scale + canvass_x,
			bottom = 0 + canvass_y,
			top = canvass_h * canvass_scale + canvass_y,
			near = -1,
			far = 1,
		)
		crgl.set_uniform(crgl.gDefShaders.rect_sh, "uProjection", proj)

		for &stroke in all_strokes {
			stroke_draw_points(&stroke, stroke_width)
		}

		// -- Gui draw
		gui.window_draw(&gui_wind)

		crgl.window_end_frame(&window)
		free_all(context.temp_allocator)
	}
}

Stroke :: struct {
	color:  [4]f32,
	points: [dynamic]crgl.Point,
}

stroke_clear :: proc(stroke: ^Stroke) {
	clear(&stroke.points)
}

stroke_append_point :: proc(stroke: ^Stroke, point: crgl.Point) {
	append(&stroke.points, point)
}

stroke_draw_points :: proc(stroke: ^Stroke, width: f32) {
	gl.PointSize(width)
	mesh := crgl.mesh_create_empty(
		math.max(len(stroke.points), 12) * size_of([6]crgl.Vertex_Uv_Color),
	);defer crgl.mesh_delete(&mesh)

	stroke_verts := make([][6]crgl.Vertex_Uv_Color, len(stroke.points) - 1)
	defer delete(stroke_verts)
	stroke_idx: i32 = 0

	color := stroke.color
	for i in 0 ..< len(stroke.points) - 1 {
		a := stroke.points[i]
		b := stroke.points[i + 1]
		quad := quad_between_points(a, b, width, color)
		stroke_verts[stroke_idx] = quad
		stroke_idx += 1

		point_vert := quad_point_circle(a, width, color);defer delete(point_vert)
		_ = crgl.mesh_write(&mesh, slice.reinterpret([]crgl.Vertex_Uv_Color, point_vert[:]))
		crgl.mesh_render(mesh, crgl.gDefShaders.rect_sh, mode = gl.TRIANGLES)
	}

	point_vert := quad_point_circle(
		stroke.points[len(stroke.points) - 1],
		width,
		color,
	);defer delete(point_vert)
	_ = crgl.mesh_write(&mesh, slice.reinterpret([]crgl.Vertex_Uv_Color, point_vert[:]))
	crgl.mesh_render(mesh, crgl.gDefShaders.rect_sh, mode = gl.TRIANGLES)

	_ = crgl.mesh_write(&mesh, slice.reinterpret([]crgl.Vertex_Uv_Color, stroke_verts[:]))
	crgl.mesh_render(mesh, crgl.gDefShaders.rect_sh, mode = gl.TRIANGLES)
}

quad_between_points :: proc(
	a, b: crgl.Point,
	width: f32 = 6,
	color: [4]f32,
) -> [6]crgl.Vertex_Uv_Color {
	a_vec: glm.vec2 = {a.x, a.y}
	b_vec: glm.vec2 = {b.x, b.y}

	// Get normalized perpendicular vector
	dir: glm.vec2 = {b.x - a.x, b.y - a.y}
	dir = {-dir.y, dir.x}
	dir = glm.normalize_vec2(dir)

	// Get 4 points of quad
	aa := a_vec + dir * width / 2
	ab := a_vec - dir * width / 2
	ba := b_vec + dir * width / 2
	bb := b_vec - dir * width / 2

	// Create vertex data
	data: [6]crgl.Vertex_Uv_Color = {
		{pos = {aa.x, aa.y, 0}, uv = {}, color = color},
		{pos = {ab.x, ab.y, 0}, uv = {}, color = color},
		{pos = {ba.x, ba.y, 0}, uv = {}, color = color},
		{pos = {ab.x, ab.y, 0}, uv = {}, color = color},
		{pos = {ba.x, ba.y, 0}, uv = {}, color = color},
		{pos = {bb.x, bb.y, 0}, uv = {}, color = color},
	}

	return data
}

quad_point_circle :: proc(p: crgl.Point, diameter: f32, color: [4]f32) -> []crgl.Vertex_Uv_Color {
	sections: i32 = 16
	base_dir: [2]f32 = {1., 0.} * diameter / 2

	// Triangle per section
	verts := make([]crgl.Vertex_Uv_Color, 3 * sections)
	idx: i32 = 0
	grads := 2 * math.PI / f32(sections)

	for sect in 0 ..< sections {
		new_dir: [2]f32 = {
			base_dir.x * math.cos_f32(grads) - base_dir.y * math.sin_f32(grads),
			base_dir.x * math.sin_f32(grads) + base_dir.y * math.cos_f32(grads),
		}

		aa: [2]f32 = {p.x, p.y}
		bb: [2]f32 = aa + base_dir
		cc: [2]f32 = aa + new_dir

		verts[idx] = crgl.Vertex_Uv_Color {
			pos   = {p.x, p.y, 0},
			uv    = {},
			color = color,
		}
		verts[idx + 1] = crgl.Vertex_Uv_Color {
			pos   = {bb.x, bb.y, 0},
			uv    = {},
			color = color,
		}
		verts[idx + 2] = crgl.Vertex_Uv_Color {
			pos   = {cc.x, cc.y, 0},
			uv    = {},
			color = color,
		}
		idx += 3

		base_dir = new_dir
	}

	return verts
}

