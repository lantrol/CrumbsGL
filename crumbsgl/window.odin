package CrumbsGL

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
	vsync:         Vsync_Flag,
	scissor_test:  bool,
}

Vsync_Flag :: enum i32 {
	OFF      = 0,
	ON       = 1,
	ADAPTIVE = -1,
}

Context :: struct {
	window: Window,
}

Scissor_Stack :: struct {
	rect:  [20]struct {
		x, y:          i32,
		width, height: i32,
	},
	count: i32,
}

gContext: Context = {}
gScissor_stack: Scissor_Stack = {}

window_init :: proc(
	name: string,
	width, height, GLmajor, GLminor: i32,
	flags: sdl.InitFlags = {.VIDEO, .EVENTS},
	gl_flags: sdl.WindowFlags = {},
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

	window := sdl.CreateWindow(
		fmt.ctprint(name),
		width,
		height,
		sdl.WindowFlags{.OPENGL} + gl_flags,
	)
	gl_context := sdl.GL_CreateContext(window)
	sdl.GL_MakeCurrent(window, gl_context)

	gl.load_up_to(int(GLmajor), int(GLminor), sdl.gl_set_proc_address)

	// Empty VAO to allow rendering with DSA
	emptyVao: u32
	gl.GenVertexArrays(1, &emptyVao)
	gl.BindVertexArray(emptyVao)

	free_all(context.temp_allocator)
	win = {window, gl_context, width, height, .ON, false}
	gContext.window = win

	sh_load_default_shaders()

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

window_enable_scissor :: proc() {
	gl.Enable(gl.SCISSOR_TEST)
	gl.Scissor(0, 0, gContext.window.width, gContext.window.height)
}

window_scissors_push :: proc(x, y, width, height: i32) {
	assert(gScissor_stack.count == len(gScissor_stack.rect), "Scissor stack overflow")
	gScissor_stack.rect[gScissor_stack.count] = {x, y, width, height}
	gScissor_stack.count += 1
	gl.Scissor(y, x, width, height)
}

window_scissors_pop :: proc() {
	assert(gScissor_stack.count > 0, "Popping an empty scissor stack")
	gScissor_stack.count -= 1
	if gScissor_stack.count == 0 {
		gl.Scissor(0, 0, gContext.window.width, gContext.window.height)
	} else {
		rect := gScissor_stack.rect[gScissor_stack.count - 1]
		gl.Scissor(rect.x, rect.y, rect.width, rect.height)
	}
}

window_scissors_reset :: proc() {
	gScissor_stack = {}
	gl.Scissor(0, 0, gContext.window.width, gContext.window.height)
}

window_clear_color :: proc(r, g, b, a: f32) {
	gl.ClearColor(r, g, b, a)
	gl.Clear(gl.COLOR_BUFFER_BIT)
}

window_end_frame :: proc(window: ^Window) {
	sdl.GL_SwapWindow(window.window)
}
