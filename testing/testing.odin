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

ST_1 :: struct {
	a:       f32,
	using b: ST_2,
}

ST_2 :: struct {
	x, y: i32,
}

main :: proc() {
	a: ST_1 = {2.2, {1, 2}}
	b: ^ST_2 = &a.b

	b.x = 2
	b.y = 3

	fmt.println(a)
}
