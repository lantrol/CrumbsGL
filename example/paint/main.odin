package main

import crgl "../../crumbsgl"
import "core:fmt"
import "core:math"
import glm "core:math/linalg/glsl"
import "core:slice"
import gl "vendor:OpenGL"
import sdl "vendor:sdl3"

main :: proc() {
	window, ok := crgl.window_init(
		name = "Paint",
		width = 800,
		height = 800,
		GLmajor = 4,
		GLminor = 6,
	);defer crgl.window_delete(&window)

	if !ok {
		fmt.eprintln("ERROR: Coulnt create window")
		return
	}

	canvass_w: f32 = 800
	canvass_h: f32 = 800
	canvass_scale: f32 = 1.
	canvass_x: f32 = 0
	canvass_y: f32 = 0

	stroke_width: f32 = 8
	all_strokes: [dynamic]Stroke
	curr_stroke: ^Stroke
	state: enum {
		Stop,
		Drawing,
	}
	blocked: bool = false

	loop: for {
		crgl.handle_events()
		if crgl.has_quit() do break loop
		if crgl.key_is_state(sdl.K_ESCAPE, .JustPressed) do break loop

		// Paint logic

		// -- Block painting if moving camera
		blocked = false
		if crgl.is_modifier_pressed(.LCTRL) && crgl.is_button_pressed(.LEFT) {
			dx, dy := crgl.get_mouse_displacement()
			canvass_x += f32(dx)
			canvass_y += f32(dy)
			blocked = true
		}

		// -- Start painting
		if crgl.is_button_just_pressed(.LEFT) && state == .Stop && !blocked {
			state = .Drawing
			str: Stroke
			append(&all_strokes, str)
			curr_stroke = &all_strokes[len(all_strokes) - 1]
			x, y := crgl.get_mouse_position()
			point: crgl.Point = {
				f32(x) * canvass_scale - canvass_x,
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
				f32(x) * canvass_scale - canvass_x,
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
		canvass_scale += 0.03 * f32(scroll)
		canvass_x += 0.03 * f32(scroll) * f32(mx)
		canvass_y -= 0.03 * f32(scroll) * f32(my)

		// Draw
		crgl.window_clear_color(.2, .2, .2, 1.)

		// Projection of canvass size to screen
		proj := glm.mat4Ortho3d(
			left = 0 - canvass_x,
			right = canvass_w * canvass_scale - canvass_x,
			bottom = 0 + canvass_y,
			top = canvass_h * canvass_scale + canvass_y,
			near = 1,
			far = -1,
		)
		crgl.set_uniform(crgl.gDefShaders.rect_sh, "uProjection", proj)

		for &stroke in all_strokes {
			stroke_draw_points(&stroke, stroke_width, color = {1., 1., 1., 1.})
		}

		crgl.window_end_frame(&window)
	}
}

Stroke :: struct {
	points: [dynamic]crgl.Point,
}

stroke_clear :: proc(stroke: ^Stroke) {
	clear(&stroke.points)
}

stroke_append_point :: proc(stroke: ^Stroke, point: crgl.Point) {
	append(&stroke.points, point)
}

stroke_draw_points :: proc(stroke: ^Stroke, width: f32, color: [4]f32 = {1, 1, 1, 1}) {
	gl.PointSize(width)
	mesh := crgl.mesh_create_empty(len(stroke.points) * size_of([6]crgl.Vertex_Uv_Color))

	stroke_verts := make([][6]crgl.Vertex_Uv_Color, len(stroke.points) - 1)
	stroke_idx: i32 = 0

	for i in 0 ..< len(stroke.points) - 1 {
		a := stroke.points[i]
		b := stroke.points[i + 1]
		quad := quad_between_points(a, b, width)
		stroke_verts[stroke_idx] = quad
		stroke_idx += 1

		point_vert := quad_point_circle(a, width);defer delete(point_vert)
		_ = crgl.mesh_write(&mesh, slice.reinterpret([]crgl.Vertex_Uv_Color, point_vert[:]))
		crgl.mesh_render(mesh, crgl.gDefShaders.rect_sh, mode = gl.TRIANGLES)
	}
	_ = crgl.mesh_write(&mesh, slice.reinterpret([]crgl.Vertex_Uv_Color, stroke_verts[:]))
	crgl.mesh_render(mesh, crgl.gDefShaders.rect_sh, mode = gl.TRIANGLES)
	crgl.mesh_delete(&mesh)
	delete(stroke_verts)
}

quad_between_points :: proc(a, b: crgl.Point, width: f32 = 6) -> [6]crgl.Vertex_Uv_Color {
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
	color: [4]f32 = {1., 1., 1., 1.}
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

quad_point_circle :: proc(p: crgl.Point, diameter: f32) -> []crgl.Vertex_Uv_Color {
	sections: i32 = 9
	base_dir: [2]f32 = {1., 0.} * diameter / 2
	color: [4]f32 = {1., 1., 1., 1.}

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
