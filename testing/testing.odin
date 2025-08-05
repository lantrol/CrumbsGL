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

main :: proc() {

}
