package main

import "core:crypto/chacha20"
import "core:fmt"
import "core:os"
import "core:strings"
import "testmod"
import "testmod/files"

input :: proc() -> string {
	buffer: [1024]u8
	total_read, error := os.read(os.stdin, buffer[:])
	assert(error == nil)
	return strings.clone_from(buffer[:total_read - 2])
}

Shader :: struct {
	type: Sh_Type,
	id:   i32,
}

Sh_Type :: enum {
	render,
	compute,
}
main :: proc() {
	shader: Shader = {
		type = .render,
	}
	assert(shader.type == .render, "Shader is not render type")
	//fmt.println(string(testmod.theFile))
	fmt.println(string(testmod.theOther))
	testmod.le_print()
	files.le_second_print()
}

