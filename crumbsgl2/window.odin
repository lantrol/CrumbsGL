package CrumbsGL2

import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:slice"
import "core:strings"
import gl "vendor:OpenGL"
import sdl "vendor:sdl3"

Window :: struct {
	window:        ^sdl.Window,
	gl_context:    sdl.GLContext,
	width, height: i32,
}

Vsync_Flag :: enum i32 {
	OFF      = 0,
	ON       = 1,
	ADAPTIVE = -1,
}

Context :: struct {
	window:     Window,
	defFontSh:  Shader,
	defColorSh: Shader,
	defRectSh:  Shader,
	defTexSh:   Shader,
}

@(private)
gContext: Context = {}

window_init :: proc(
	name: string,
	width, height, GLmajor, GLminor: i32,
	flags: sdl.InitFlags = {.VIDEO, .EVENTS},
) -> (
	win: Window,
	ok: bool,
) {
	if !sdl.Init(flags) {
		fmt.eprintln("Error inicializando SDL3")
		return {}, false
	}

	sdl.GL_SetAttribute(.CONTEXT_MAJOR_VERSION, GLmajor)
	sdl.GL_SetAttribute(.CONTEXT_MINOR_VERSION, GLminor)
	sdl.GL_SetAttribute(.CONTEXT_PROFILE_MASK, gl.CONTEXT_CORE_PROFILE_BIT)

	window := sdl.CreateWindow(fmt.ctprint(name), width, height, sdl.WindowFlags{.OPENGL})
	gl_context := sdl.GL_CreateContext(window)
	sdl.GL_MakeCurrent(window, gl_context)

	gl.load_up_to(int(GLmajor), int(GLminor), sdl.gl_set_proc_address)

	// Empty VAO to allow rendering with DSA
	emptyVao: u32
	gl.GenVertexArrays(1, &emptyVao)
	gl.BindVertexArray(emptyVao)

	free_all(context.temp_allocator)
	win = {window, gl_context, width, height}
	gContext.window = win

	// Init default shaders
	sh_ok: bool
	gContext.defColorSh, sh_ok = sh_load_sources(gDefColorVS, gDefColorFS)
	assert(sh_ok == true, "Error loading defColorSh")

	gContext.defFontSh, sh_ok = sh_load_sources(gDefUvsColorVS, gDefFontFS)
	assert(sh_ok == true, "ERROR: loading default font shader")

	gContext.defRectSh, sh_ok = sh_load_sources(gDefUvsColorVS, gDefRectFS)
	assert(sh_ok == true, "ERROR: loading default rectangle shader")

	gContext.defTexSh, sh_ok = sh_load_sources(gDefUvsVS, gDefUvsFS)
	assert(sh_ok == true, "ERROR: loading default rectangle shader")

	return win, true
}

window_delete :: proc(window: ^Window) {
	sdl.GL_DestroyContext(window.gl_context)
	sdl.DestroyWindow(window.window)
	sdl.Quit()
	window^ = {}
}

window_set_vsync :: proc(state: Vsync_Flag) {
	sdl.GL_SetSwapInterval(i32(state))
}

window_enable_blending :: proc() {
	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
}

