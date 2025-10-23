package CrumbsGL

import "core:fmt"
import "core:math/linalg"
import glm "core:math/linalg/glsl"
import "core:os"
import "core:slice"
import "core:strings"
import gl "vendor:OpenGL"

set_uniform :: proc {
	setUniformf32,
	setUniformf32v,
	setUniformi32,
	setUniformi32v,
	setUniformui32,
	setUniformui32v,
	setUniformf32Sh,
	setUniformf32vSh,
	setUniformi32Sh,
	setUniformi32vSh,
	setUniformui32Sh,
	setUniformui32vSh,
	setUniformMat4Sh,
}

setUniformf32 :: proc(shader: u32, name: string, data: f32) {
	uniformName: cstring = strings.clone_to_cstring(name)
	defer delete(uniformName)
	location: i32 = gl.GetUniformLocation(shader, uniformName)

	if location == -1 {
		fmt.eprintln("ERROR: uniform", name, "does not exist")
		os.exit(1)
	}

	gl.ProgramUniform1f(shader, location, data)
}

setUniformf32v :: proc(shader: u32, name: string, data: []f32) {
	uniformName: cstring = strings.clone_to_cstring(name)
	defer delete(uniformName)
	location: i32 = gl.GetUniformLocation(shader, uniformName)

	if location == -1 {
		fmt.eprintln("ERROR: uniform", name, "does not exist")
		os.exit(1)
	}

	switch len(data) {
	case 1:
		gl.ProgramUniform1fv(shader, location, 1, raw_data(data))
	case 2:
		gl.ProgramUniform2fv(shader, location, 1, raw_data(data))
	case 3:
		gl.ProgramUniform3fv(shader, location, 1, raw_data(data))
	case 4:
		gl.ProgramUniform4fv(shader, location, 1, raw_data(data))
	}
}

setUniformi32 :: proc(shader: u32, name: string, data: i32) {
	uniformName: cstring = strings.clone_to_cstring(name)
	defer delete(uniformName)
	location: i32 = gl.GetUniformLocation(shader, uniformName)

	if location == -1 {
		fmt.eprintln("ERROR: uniform", name, "does not exist")
		os.exit(1)
	}

	gl.ProgramUniform1i(shader, location, data)
}

setUniformi32v :: proc(shader: u32, name: string, data: []i32) {
	uniformName: cstring = strings.clone_to_cstring(name)
	defer delete(uniformName)
	location: i32 = gl.GetUniformLocation(shader, uniformName)

	if location == -1 {
		fmt.eprintln("ERROR: uniform", name, "does not exist")
		os.exit(1)
	}

	switch len(data) {
	case 1:
		gl.ProgramUniform1iv(shader, location, 1, raw_data(data))
	case 2:
		gl.ProgramUniform2iv(shader, location, 1, raw_data(data))
	case 3:
		gl.ProgramUniform3iv(shader, location, 1, raw_data(data))
	case 4:
		gl.ProgramUniform4iv(shader, location, 1, raw_data(data))
	}
}

setUniformui32 :: proc(shader: u32, name: string, data: u32) {
	uniformName: cstring = strings.clone_to_cstring(name)
	defer delete(uniformName)
	location: i32 = gl.GetUniformLocation(shader, uniformName)

	if location == -1 {
		fmt.eprintln("ERROR: uniform", name, "does not exist")
		os.exit(1)
	}

	gl.ProgramUniform1ui(shader, location, data)
}

setUniformui32v :: proc(shader: u32, name: string, data: []u32) {
	uniformName: cstring = strings.clone_to_cstring(name)
	defer delete(uniformName)
	location: i32 = gl.GetUniformLocation(shader, uniformName)

	if location == -1 {
		fmt.eprintln("ERROR: uniform", name, "does not exist")
		os.exit(1)
	}

	switch len(data) {
	case 1:
		gl.ProgramUniform1uiv(shader, location, 1, raw_data(data))
	case 2:
		gl.ProgramUniform2uiv(shader, location, 1, raw_data(data))
	case 3:
		gl.ProgramUniform3uiv(shader, location, 1, raw_data(data))
	case 4:
		gl.ProgramUniform4uiv(shader, location, 1, raw_data(data))
	}
}

// Shader type

setUniformf32Sh :: proc(shader: Shader, name: string, data: f32) {
	location, ok := shader.uniforms[name]

	if !ok {
		fmt.eprintln("ERROR: uniform", name, "does not exist")
		os.exit(1)
	}

	gl.ProgramUniform1f(shader.id, location, data)
}

setUniformf32vSh :: proc(shader: Shader, name: string, data: []f32) {
	location, ok := shader.uniforms[name]

	if !ok {
		fmt.eprintln("ERROR: uniform", name, "does not exist")
		os.exit(1)
	}

	switch len(data) {
	case 1:
		gl.ProgramUniform1fv(shader.id, location, 1, raw_data(data))
	case 2:
		gl.ProgramUniform2fv(shader.id, location, 1, raw_data(data))
	case 3:
		gl.ProgramUniform3fv(shader.id, location, 1, raw_data(data))
	case 4:
		gl.ProgramUniform4fv(shader.id, location, 1, raw_data(data))
	}
}

setUniformi32Sh :: proc(shader: Shader, name: string, data: i32) {
	location, ok := shader.uniforms[name]

	if !ok {
		fmt.eprintln("ERROR: uniform", name, "does not exist")
		os.exit(1)
	}

	gl.ProgramUniform1i(shader.id, location, data)
}

setUniformi32vSh :: proc(shader: Shader, name: string, data: []i32) {
	location, ok := shader.uniforms[name]

	if !ok {
		fmt.eprintln("ERROR: uniform", name, "does not exist")
		os.exit(1)
	}

	switch len(data) {
	case 1:
		gl.ProgramUniform1iv(shader.id, location, 1, raw_data(data))
	case 2:
		gl.ProgramUniform2iv(shader.id, location, 1, raw_data(data))
	case 3:
		gl.ProgramUniform3iv(shader.id, location, 1, raw_data(data))
	case 4:
		gl.ProgramUniform4iv(shader.id, location, 1, raw_data(data))
	}
}

setUniformui32Sh :: proc(shader: Shader, name: string, data: u32) {
	location, ok := shader.uniforms[name]

	if !ok {
		fmt.eprintln("ERROR: uniform", name, "does not exist")
		os.exit(1)
	}

	gl.ProgramUniform1ui(shader.id, location, data)
}

setUniformui32vSh :: proc(shader: Shader, name: string, data: []u32) {
	location, ok := shader.uniforms[name]

	if !ok {
		fmt.eprintln("ERROR: uniform", name, "does not exist")
		os.exit(1)
	}

	switch len(data) {
	case 1:
		gl.ProgramUniform1uiv(shader.id, location, 1, raw_data(data))
	case 2:
		gl.ProgramUniform2uiv(shader.id, location, 1, raw_data(data))
	case 3:
		gl.ProgramUniform3uiv(shader.id, location, 1, raw_data(data))
	case 4:
		gl.ProgramUniform4uiv(shader.id, location, 1, raw_data(data))
	}
}

setUniformMat4Sh :: proc(shader: Shader, name: string, data: matrix[4, 4]f32) {
	location, ok := shader.uniforms[name]

	if !ok {
		fmt.eprintln("ERROR: uniform", name, "does not exist")
		os.exit(1)
	}

	mat_data := linalg.matrix_flatten(data)
	gl.ProgramUniformMatrix4fv(shader.id, location, 1, false, raw_data(mat_data[:]))
}
