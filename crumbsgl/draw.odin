package CrumbsGL

import "core:fmt"
import gl "vendor:OpenGL"

Rect :: struct {
	x, y:          f32,
	width, height: f32,
}

Point :: struct {
	x, y: f32,
}

rect_to_vertex :: proc(rect: Rect, color: [4]f32 = {}) -> [6]Vertex_Uv_Color {
	data: [6]Vertex_Uv_Color = {
		{pos = {rect.x, rect.y + rect.height, 0.}, uv = {0, 0}, color = color},
		{pos = {rect.x, rect.y, 0.}, uv = {0, 1}, color = color},
		{pos = {rect.x + rect.width, rect.y + rect.height, 0.}, uv = {1, 0}, color = color},
		{pos = {rect.x, rect.y, 0.}, uv = {0, 1}, color = color},
		{pos = {rect.x + rect.width, rect.y + rect.height, 0.}, uv = {1, 0}, color = color},
		{pos = {rect.x + rect.width, rect.y, 0.}, uv = {1, 1}, color = color},
	}
	return data
}

draw_point :: proc(p: Point, color: [4]f32 = {1, 1, 1, 1}) {
	gl.PointSize(4)
	point := [1]Vertex_Uv_Color{{pos = {p.x, p.y, 0.}, uv = {0, 0}, color = color}}
	mesh := mesh_create(point[:])
	mesh_render(mesh, gDefShaders.rect_sh, mode = gl.POINTS)
	mesh_delete(&mesh)
}
