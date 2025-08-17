package main

import "core:fmt"
import "core:os"
import "core:sys/info"
import crgl "crumbsgl2"
import gl "vendor:OpenGL"
import sdl "vendor:sdl3"
import "vendor:stb/truetype"

GL_VERSION_MAJOR :: 4
GL_VERSION_MINOR :: 5
SCREEN_SIZE :: 900

main :: proc() {
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

	screen := crgl.mesh_create_quadfs()
	texture := crgl.texture_create_2D({2, 2}, .RGB8)
	crgl.texture_write_2D(texture, []u8{80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80}, 3)

	// data: []crgl.Vertex = make([]crgl.Vertex, 6)
	// gl.GetNamedBufferSubData(screen.ssbo, 0, 20 * 6, raw_data(data))

	data := crgl.buffer_read(screen.ssbo, crgl.Vertex_Uv, 6)
	fmt.println(data)

	font, ok := crgl.font_atlas_from_file("crumbsgl/fonts/Comic Sans MS.ttf")
	assert(ok, "Error cargando fuente")


	loop: for {

		// Events
		crgl.handle_events()
		if crgl.is_key_just_pressed(sdl.K_ESCAPE) do break loop
		if crgl.has_quit() do break loop

		// Draw
		gl.ClearColor(0., 0., 0., 1.)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		crgl.mesh_render(screen, crgl.sh_get_default_uvs_shader(), texture)

		crgl.font_draw_text(font, "Hola", {200, 200})

		sdl.GL_SwapWindow(window.window)
	}
}

