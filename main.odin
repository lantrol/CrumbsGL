package main

import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:mem"
import "core:os"
import "core:sys/info"
import crgl "crumbsgl"
import gui "crumbsgl/gui"
import gl "vendor:OpenGL"
import sdl "vendor:sdl3"
import "vendor:stb/truetype"

GL_VERSION_MAJOR :: 4
GL_VERSION_MINOR :: 5
SCREEN_SIZE :: 900

main :: proc() {
	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

	window, wind_ok := crgl.window_init(
		"Hello",
		SCREEN_SIZE,
		SCREEN_SIZE,
		GL_VERSION_MAJOR,
		GL_VERSION_MINOR,
	)
	defer crgl.window_delete(&window)
	crgl.window_enable_blending()
	crgl.window_set_vsync(.ON)
	gui.gui_init()

	screen := crgl.mesh_create_quadfs_norm()
	texture := crgl.texture_create_2D({2, 2}, .RGB8)
	crgl.texture_write_2D(texture, []u8{80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80}, 3)

	// data: []crgl.Vertex = make([]crgl.Vertex, 6)
	// gl.GetNamedBufferSubData(screen.ssbo, 0, 20 * 6, raw_data(data))

	data := crgl.buffer_read(screen.ssbo, crgl.Vertex_Uv, 6)

	font, ok := gui.font_atlas_from_file("crumbsgl/gui/fonts/IBMPlexSans-Regular.ttf")
	assert(ok, "Error cargando fuente")
	gui.set_font(font)

	bbox_width, bbox_height := gui.font_get_text_bbox(font, "Hola")
	rect := gui.Gui_Rect{0, 0, 0, 0}
	mesh_data := gui.window_rect_to_vertex(rect, color = {1, 1, 1, 0.2})
	meshs := crgl.mesh_create(mesh_data[:])
	rect = gui.Gui_Rect{200, 200, i32(bbox_width), i32(bbox_height)}
	mesh_data = gui.window_rect_to_vertex(rect, color = {1, 1, 1, 0.2})
	ok = crgl.mesh_write(&meshs, mesh_data[:])

	if !ok {
		fmt.println("Write error")
		return
	}

	// Y increases going down-wards
	proj := glm.mat4Ortho3d(0, SCREEN_SIZE, SCREEN_SIZE, 0, -1, 1)

	loop: for {

		// Events
		crgl.handle_events()
		if crgl.is_key_just_pressed(sdl.K_ESCAPE) do break loop
		if crgl.has_quit() do break loop

		// Draw
		gl.ClearColor(0., 0., 0., 1.)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		// crgl.mesh_render(screen, crgl.gDefShaders.tex_sh, texture)

		// gui.font_draw_text(font, "Hola", {200, 200})

		// crgl.setUniformMat4Sh(crgl.gDefShaders.rect_sh, "uProjection", proj)
		// crgl.mesh_render(meshs, crgl.gDefShaders.rect_sh)

		{
			gui.window_begin("1", 100, 100, 400, 200)

			sp1, sp2 := gui.window_vsplit(gui.gActive_window^, 0.5)
			//gui.debug_draw_box(sp1)

			if gui.button_create("Button", &sp1) {
				fmt.println("Pressed!")
			}
			if gui.button_create("Another Button", &sp2) {
				fmt.println("Second Pressed!")
			}

			gui.window_end()
		}

		{
			gui.window_begin("2", 550, 100, 300, 200)

			if gui.button_create("A") {
				fmt.println("Pressed!")
			}
			if gui.button_create("B") {
				fmt.println("Second Pressed!")
			}
			if gui.button_create("C") {
				fmt.println("Third Pressed!")
			}

			row, width := gui.window_row(gui.gActive_window, cols = 3, height = 50)
			if gui.button_create("C", &row, btn_width = width) {
				fmt.println("Third Pressed!")
			}
			if gui.button_create("C", &row, btn_width = width) {
				fmt.println("Third Pressed!")
			}
			if gui.button_create("C", &row, btn_width = width) {
				fmt.println("Third Pressed!")
			}
			// gui.debug_draw_box(row, {0.7, 0.7, 0.7, 1})

			gui.window_end()
		}

		sdl.GL_SwapWindow(window.window)
		free_all(context.temp_allocator)
	}
}
