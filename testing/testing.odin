package main

import "core:fmt"
import "core:os"
import "core:strings"

input :: proc() -> string {
	buffer: [1024]u8
	total_read, error := os.read(os.stdin, buffer[:])
	assert(error == nil)
	return strings.clone_from(buffer[:total_read - 2])
}

Shader :: struct {
	type: Sh_Type,
}

Sh_Type :: enum {
	render,
	compute,
}

main :: proc() {
	shader: Shader = {.compute}
	assert(shader.type == .render, "Shader is not render type")
}

