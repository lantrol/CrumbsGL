package testmod

import "core:fmt"
import "core:os"

theFile: []u8

theOther: string = #load("files/test.txt", string)

le_print :: proc() {
	fmt.println("Le Print")
}

