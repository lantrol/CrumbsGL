package main

import "core:fmt"
import "core:os"
import "core:sys/info"
import crgl "crumbsgl"
import gl "vendor:OpenGL"
import sdl "vendor:sdl3"
import "vendor:stb/truetype"

VSYNC :: 1
GL_VERSION_MAJOR :: 4
GL_VERSION_MINOR :: 5
SCREEN_SIZE :: 1000

main :: proc() {
	window, wind_ok := crgl.windowInit(
		SCREEN_SIZE,
		SCREEN_SIZE,
		GL_VERSION_MAJOR,
		GL_VERSION_MINOR,
	)
	defer crgl.windowDelete(&window)
	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

	font, ok := crgl.font_atlas_from_file("./crumbsgl/fonts/Comic Sans MS.ttf", i32(' '), i32('~'))
	crgl.gui_set_font(font)
	//fmt.println(font.packedChars[i32('H') - font.firstChar])
	//fmt.println(font.alignedQuads[i32('H') - font.firstChar])

	shader := crgl.sh_load_files(
		"./crumbsgl/shaders/defColorVS.glsl",
		"./crumbsgl/shaders/defColorFS.glsl",
	)

	for key, value in shader.uniforms {
		fmt.println("Uniform", key, ":", value)
	}

	crgl.setUniform(shader, "alpha", 2.)

	screen: crgl.Mesh = crgl.createQuadFS()

	counter: i32 = 0
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
		// crgl.drawPoint({textOrigin[0], textOrigin[1], 0.}, color = {1., 0., 1.})
		// crgl.renderMesh(charMesh, crgl.sh_get_default_font_shader(), fontTex)

		bboxWidth, bboxHeight := crgl.font_get_text_bbox(font, "Hello :)\nWhats up?", scale = 0.5)
		bbox: crgl.GuiRect = {400, 400, i32(bboxWidth), i32(bboxHeight), {0.4, 0.4, 0.4, 1}}
		crgl.gui_draw(bbox)
		crgl.font_draw_text(font, "Hello :)\nWhats up?", {400., 400.}, scale = 0.5)

		// UI testing
		{
			crgl.gui_begin_window("Nombre", alpha = 0.4)

			if crgl.gui_button("Hello Button") {
				fmt.println("Hello!")
			}

			crgl.gui_text("Contador:", counter)
			crgl.gui_end_window()
		}

		counter += 1

		// Debug info
		//fmt.println("Current buffers: ", crgl.BufferDeltaCreation())
		//fmt.println("Current textures: ", crgl.TextureDeltaCreation())

		sdl.GL_SwapWindow(window.window)
	}
}
