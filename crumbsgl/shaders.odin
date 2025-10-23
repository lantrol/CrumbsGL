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

Default_Shaders :: struct {
	color_sh:    Shader,
	uv_color_sh: Shader,
	font_sh:     Shader,
	rect_sh:     Shader,
	tex_sh:      Shader,
}

@(private)
gDefColorVS: string : #load("shaders/color_vs.glsl", string)
@(private)
gDefColorFS: string : #load("shaders/color_fs.glsl", string)
@(private)
gDefUvsVS: string : #load("shaders/uvs_vs.glsl", string)
@(private)
gDefUvsFS: string : #load("shaders/uvs_fs.glsl", string)
@(private)
gDefUvsColorVS: string : #load("shaders/uvs_color_vs.glsl", string)
@(private)
gDefUvsColorProjVS: string : #load("shaders/uvs_color_proj_vs.glsl", string)
@(private)
gDefFontFS: string : #load("shaders/font_fs.glsl", string)
@(private)
gDefRectFS: string : #load("shaders/rect_fs.glsl", string)

gDefShaders: Default_Shaders = {}

sh_load_default_shaders :: proc() {
	// Init default shaders
	sh_ok: bool
	gDefShaders.color_sh, sh_ok = sh_load_sources(gDefColorVS, gDefColorFS)
	assert(sh_ok == true, "Error loading defColorSh")

	gDefShaders.font_sh, sh_ok = sh_load_sources(gDefUvsColorVS, gDefFontFS)
	assert(sh_ok == true, "ERROR: loading default font shader")

	gDefShaders.rect_sh, sh_ok = sh_load_sources(gDefUvsColorProjVS, gDefRectFS)
	assert(sh_ok == true, "ERROR: loading default rectangle shader")

	gDefShaders.uv_color_sh, sh_ok = sh_load_sources(gDefUvsColorVS, gDefRectFS)
	assert(sh_ok == true, "ERROR: loading default rectangle shader")

	gDefShaders.tex_sh, sh_ok = sh_load_sources(gDefUvsVS, gDefUvsFS)
	assert(sh_ok == true, "ERROR: loading default rectangle shader")
}

sh_load_files :: proc(vertexSh, fragmentSh: string) -> (sh: Shader, ok: bool) {
	program, ok_sh := gl.load_shaders_file(vertexSh, fragmentSh)
	if !ok_sh {
		fmt.eprintln("ERROR: couldnt load shader program")
		return {}, false
	}

	sh = {
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

	return sh, true
}

sh_load_sources :: proc(vertexSh, fragmentSh: string) -> (sh: Shader, ok: bool) {
	program, ok_sh := gl.load_shaders_source(vertexSh, fragmentSh)
	if !ok_sh {
		fmt.eprintln("ERROR: couldnt load shader program")
		return {}, false
	}

	sh = {
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

	return sh, true
}

sh_load_compute_file :: proc(path: string) -> (sh: Shader, ok: bool) {
	program, ok_sh := gl.load_compute_file(path)
	if !ok_sh {
		fmt.eprintln("ERROR: couldnt load shader program")
		return {}, false
	}

	sh = {
		id       = program,
		type     = .compute,
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

	return sh, true
}

sh_load_compute_source :: proc(shader: string) -> (sh: Shader, ok: bool) {
	program, ok_sh := gl.load_compute_source(shader)
	if !ok_sh {
		fmt.eprintln("ERROR: couldnt load shader program")
		return {}, false
	}

	sh = {
		id       = program,
		type     = .compute,
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

	return sh, true
}

sh_delete_program :: proc(sh: ^Shader) {
	gl.DeleteProgram(sh.id)
	delete(sh.uniforms)
	sh^ = {}
}

sh_compute_run :: proc(compute: Shader, group_x: u32 = 1, group_y: u32 = 1, group_z: u32 = 1) {
	assert(compute.type == .compute, "Trying to run none Compute Shader")
	gl.UseProgram(compute.id)
	gl.DispatchCompute(group_x, group_y, group_z)
	gl.MemoryBarrier(gl.ALL_BARRIER_BITS)
}
