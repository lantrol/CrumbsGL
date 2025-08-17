package files

import module "../"
import "core:fmt"

le_second_print :: proc() {
	module.le_print()
	fmt.println("Le Second Print")
}

