package main

import "core:fmt"
import "core:os"
import crgl "crumbsgl"
import gl "vendor:OpenGL"
import sdl "vendor:sdl3"
import "vendor:stb/truetype"

VSYNC :: 1
GL_VERSION_MAJOR :: 4
GL_VERSION_MINOR :: 5
SCREEN_SIZE :: 800

main :: proc() {
	window, wind_ok := crgl.windowInit(
		SCREEN_SIZE,
		SCREEN_SIZE,
		GL_VERSION_MAJOR,
		GL_VERSION_MINOR,
	)
	defer crgl.windowDelete(&window)
	gl.Enable(gl.BLEND)

	font, ok := crgl.font_atlas_from_file("./crumbsgl/fonts/Comic Sans MS.ttf", i32(' '), 94)
	//crgl.font_font_to_png(font, "test.png")
	fmt.println(font.packedChars[1])
	fmt.println(font.alignedQuads[1])

	fontTex: crgl.Texture = crgl.createTexture2D(crgl.ATLAS_SIZE, crgl.ATLAS_SIZE)
	crgl.writeTexture2D(fontTex, font.atlas, 1, crgl.ATLAS_SIZE, crgl.ATLAS_SIZE)

	screen: crgl.Mesh = crgl.createQuadFS()
	shader, sh_ok := crgl.font_laod_default_shader()

	loop: for {
		// Events
		crgl.handle_events()
		if crgl.is_key_just_pressed(sdl.K_ESCAPE) do break loop
		if crgl.has_quit() do break loop

		// Draw
		gl.ClearColor(0.2, 0.2, 0.2, 1.)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		// button: crgl.GuiRect = {0, 0, 200, 80, {1., 1., 1.}}
		// crgl.gui_draw(button)
		// if crgl.gui_is_pressed(button) {
		// 	fmt.println("PUTOOOOOO")
		// }

		// Text testing
		// crgl.renderMesh(screen, shader, fontTex)


		// UI testing
		{
			crgl.gui_begin_window("Nombre")

			if crgl.gui_button() {
				fmt.println("Button")
			}

			if crgl.gui_button() {
				fmt.println("This too!")
			}
			if crgl.gui_button() {
				fmt.println("el tercero")
			}
			crgl.gui_end_window()
		}


		sdl.GL_SwapWindow(window.window)
	}
}
