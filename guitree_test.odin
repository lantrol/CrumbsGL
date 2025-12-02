package main

import "core:fmt"
import crgl "crumbsgl"
import gui "crumbsgl/gui-tree"
import gl "vendor:OpenGL"
import sdl "vendor:sdl3"

main :: proc() {
	window, ok := crgl.window_init(
		name = "GUI Tree Test",
		width = 800,
		height = 800,
		GLmajor = 4,
		GLminor = 6,
	);defer crgl.window_delete(&window)
	assert(ok, "ERROR: Could not create window")
	crgl.window_enable_blending()

	// Gui initialization
	font, f_ok := gui.font_atlas_from_file("crumbsgl/gui-tree/fonts/IBMPlexSans-Regular.ttf")
	assert(f_ok, "ERROR: Couldnt load font data")
	gui.gui_init(font)

	// Gui definition
	gui_wind := gui.window_begin("A", 0, 0, 300, 200)
	gui_wind.content.type = .Column
	c1 := gui.container_create(&gui_wind.content, .Row, 300, 100)
	c2 := gui.container_create(&gui_wind.content, .Row, 300, 100)
	gui.button_create(c1, "Hola que tal", -1, -1)
	gui.button_create(c1, "12", -1, -1)
	gui.button_create(c2, "12", -1, -1)
	b4 := gui.button_create(c2, "12", -1, -1)

	loop: for {
		crgl.handle_events()
		if crgl.is_key_just_pressed(sdl.K_ESCAPE) do break loop
		if crgl.has_quit() do break loop

		// Draw
		crgl.window_clear_color(0.2, 0.2, 0.2, 1.)

		gui.window_handle_events(&gui_wind)
		gui.window_draw(&gui_wind)

		if b4.pressed do fmt.println("Button!")

		crgl.window_end_frame(&window)
		free_all(context.temp_allocator)
	}
}
