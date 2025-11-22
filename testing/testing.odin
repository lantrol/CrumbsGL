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

foo :: proc(callback: proc(data: $T), data: T) {
	callback(data)
}

Callback :: struct($DATA: typeid) {
	func: proc(a: DATA),
	data: DATA,
}

main :: proc() {
	Data :: struct {
		a: int,
		b: f32,
	}
	a: Data = {1, 2.2}
	b := rawptr(a)
	c := transmute(Data)(b^)
}
