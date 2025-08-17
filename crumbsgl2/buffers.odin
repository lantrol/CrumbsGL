package CrumbsGL2

import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:slice"
import "core:strings"
import gl "vendor:OpenGL"
import sdl "vendor:sdl3"

Vertex_Uv :: struct {
	pos: [3]f32,
	uv:  [2]f32,
}

Vertex_Uv_Color :: struct {
	pos:   [3]f32,
	uv:    [2]f32,
	color: [4]f32,
}

Mesh :: struct {
	ssbo:       u32,
	vertAmount: i32,
}

@(private)
gDeltaCreatedBuffers: i32 = 0

buffer_create :: proc(data: []$T, usage: u32 = gl.DYNAMIC_STORAGE_BIT) -> (ssbo: u32) {
	gDeltaCreatedBuffers += 1
	gl.CreateBuffers(1, &ssbo)
	gl.NamedBufferStorage(ssbo, size_of(data[0]) * len(data), raw_data(data), usage)
	return ssbo
}

buffer_delete :: proc(ssbo: ^u32) {
	gl.DeleteBuffers(1, ssbo)
	ssbo^ = 0
}

buffer_read :: proc(ssbo: u32, $type: typeid, len: int) -> []type {
	data: []type = make([]type, len)
	gl.GetNamedBufferSubData(ssbo, 0, size_of(type) * len, raw_data(data))
	return data
}

mesh_create :: proc(data: []$T) -> (mesh: Mesh) {
	mesh.ssbo = buffer_create(data)
	mesh.vertAmount = i32(len(data))
	return mesh
}

mesh_delete :: proc(mesh: ^Mesh) {
	gDeltaCreatedBuffers -= 1
	gl.DeleteBuffers(1, &(mesh.ssbo))
	mesh^ = {0, 0}
}

mesh_render :: proc(mesh: Mesh, shader: Shader, texture: Texture = {}, mode: u32 = gl.TRIANGLES) {
	gl.UseProgram(shader.id)
	gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 0, mesh.ssbo)
	if texture != {} {
		gl.BindTextureUnit(0, texture.id)
	}
	gl.DrawArrays(mode, 0, mesh.vertAmount)
}

mesh_create_quadfs :: proc() -> (mesh: Mesh) {
	screen_vert := []Vertex_Uv {
		{{-1, 1, 0}, {0, 1}},
		{{-1, -1, 0}, {0, 0}},
		{{1, 1, 0}, {1, 1}},
		{{-1, -1, 0}, {0, 0}},
		{{1, 1, 0}, {1, 1}},
		{{1, -1, 0}, {1, 0}},
	}
	mesh = mesh_create(screen_vert)
	return mesh
}

buffer_created_buffers :: proc() -> i32 {
	return gDeltaCreatedBuffers
}

