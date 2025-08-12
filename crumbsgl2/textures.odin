package CrumbsGL2

import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:slice"
import "core:strings"
import gl "vendor:OpenGL"
import sdl "vendor:sdl3"

Texture :: struct {
	id:             u32,
	width, height:  i32,
	internalformat: Texture_Format,
}

Texture_Format :: enum u32 {
	NONE,
	RGBA8 = gl.RGBA8,
	RGBA32F = gl.RGBA32F,
	RGB8 = gl.RGB8,
	RGB32F = gl.RGB32F,
	RG8 = gl.RG8,
	RG32F = gl.RG32F,
	R8 = gl.R8,
	R32F = gl.R32F,
}

Target :: struct {
	fbo:     u32,
	texture: Texture,
	width:   i32,
	height:  i32,
}

// Debug purpose
@(private)
gDeltaCreatedTextures: i32 = 0


texture_create_2D :: proc(
	dim: [2]i32,
	internalformat: Texture_Format = .RGBA8,
	wrap: i32 = gl.REPEAT,
	filter: i32 = gl.NEAREST,
) -> (
	texture: Texture,
) {
	gDeltaCreatedTextures += 1

	gl.CreateTextures(gl.TEXTURE_2D, 1, &texture.id)

	gl.TextureParameteri(texture.id, gl.TEXTURE_WRAP_S, wrap)
	gl.TextureParameteri(texture.id, gl.TEXTURE_WRAP_T, wrap)
	gl.TextureParameteri(texture.id, gl.TEXTURE_MIN_FILTER, filter)
	gl.TextureParameteri(texture.id, gl.TEXTURE_MAG_FILTER, filter)

	gl.TextureStorage2D(texture.id, 1, u32(internalformat), dim.x, dim.y)

	texture.internalformat = internalformat
	texture.width = dim.x
	texture.height = dim.y
	return texture
}

texture_write_2D :: proc(texture: Texture, data: []$T, components: u32) {
	format, type: u32

	switch typeid_of(T) {
	case u8:
		type = gl.UNSIGNED_BYTE
	case u16:
		type = gl.UNSIGNED_SHORT
	case u32:
		type = gl.UNSIGNED_INT
	case i8:
		type = gl.BYTE
	case i16:
		type = gl.SHORT
	case i32:
		type = gl.INT
	case f16:
		type = gl.HALF_FLOAT
	case f32:
		type = gl.FLOAT
	case f64:
		type = gl.DOUBLE
	case:
		fmt.eprintln("ERROR: Tipo de dato inválido")
		return
	}

	switch components {
	case 1:
		format = gl.RED
	case 2:
		format = gl.RG
	case 3:
		format = gl.RGB
	case 4:
		format = gl.RGBA
	case:
		fmt.eprintln("ERROR: Numero de componentes inválido")
		return
	}

	if data != nil {
		// Pixel Storage alignment is changed to 1 to not require padding for each row to align to 4 bytes
		// Later is restored to 4 for safety. It is NOT really necessary, unless interacting with other OpenGL code
		gl.PixelStorei(gl.UNPACK_ALIGNMENT, 1)
		gl.TextureSubImage2D(
			texture.id,
			0,
			0,
			0,
			texture.width,
			texture.height,
			format,
			type,
			raw_data(data),
		)
		gl.PixelStorei(gl.UNPACK_ALIGNMENT, 4)
	}
}

texture_delete :: proc(texture: ^Texture) {
	gDeltaCreatedTextures -= 1
	gl.DeleteTextures(1, &(texture^.id))
	texture^ = {} // clear values
}

texture_bind :: proc(unit: u32, texture: Texture) {
	gl.BindTextureUnit(unit, texture.id)
}

texture_bind_image :: proc(unit: u32, texture: Texture, use: enum {
		READ       = gl.READ_ONLY,
		WRITE      = gl.WRITE_ONLY,
		READ_WRITE = gl.READ_WRITE,
	}) {
	gl.BindImageTexture(unit, texture.id, 0, false, 0, u32(use), u32(texture.internalformat))
}

texture_target_create :: proc(width, height: i32, format: Texture_Format = .RGBA8) -> Target {
	fbo: u32
	gl.CreateFramebuffers(1, &fbo)
	texture := texture_create_2D({width, height}, format)
	gl.NamedFramebufferTexture(fbo, gl.COLOR_ATTACHMENT0, texture.id, 0)
	target: Target = {fbo, texture, width, height}
	return target
}

texture_target_delete :: proc(target: ^Target) {
	texture_delete(&target.texture)
	gl.DeleteFramebuffers(1, &(target.fbo))
	target^ = {} // Zero the values
}

texture_target_bind :: proc(target: Target, mode: u32 = gl.FRAMEBUFFER) {
	gl.BindFramebuffer(mode, target.fbo)
	gl.Viewport(0, 0, target.width, target.height)
}

texture_targets_unbind :: proc() {
	gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
}

dtexture_created_textures :: proc() -> i32 {
	return gDeltaCreatedTextures
}

