package main

import "core:fmt"
import "core:os"
import "core:strings"

when ODIN_DEBUG {
	HELLO :: "Hello"
}

print :: proc(args: ..any) {
	fmt.println(..args)
}

main :: proc() {
	print("A", 3)
}

