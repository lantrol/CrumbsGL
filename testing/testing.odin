package main

import "core:fmt"
import "core:os"

when ODIN_DEBUG {
	HELLO :: "Hello"
}

main :: proc() {
	fmt.println(HELLO)
}
