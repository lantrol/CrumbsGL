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

foo :: proc() -> (a: [dynamic]i32) {
	append(&a, 1)
	return a
}

main :: proc() {
	a := foo()
	b := foo()
	append(&a, 2)
	fmt.println(a)
	fmt.println(b)
}
