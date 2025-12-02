package GuiTree

import crgl "../"
import "core:fmt"
import "core:os"
import gl "vendor:OpenGL"
import sdl "vendor:sdl3"
import ttf "vendor:stb/truetype"

ATLAS_SIZE :: 1024
FONT_SIZE :: 64.

Font_Data :: struct {
	info:          ttf.fontinfo,
	font_size:     f32,
	atlas_tex:     crgl.Texture,
	packed_chars:  []ttf.packedchar,
	aligned_quads: []ttf.aligned_quad,
	first_char:    i32,
	char_range:    i32,
	ascent:        i32,
	descent:       i32,
	linegap:       i32,
	scale:         f32,
}

Font_Quad :: [6]crgl.Vertex_Uv_Color

font_atlas_from_file :: proc(
	file: string,
	first_char: i32 = i32(' '),
	last_char: i32 = i32('~'),
	font_size: f32 = FONT_SIZE,
) -> (
	font_data: Font_Data,
	font_ok: bool,
) {
	font_file, ok := os.read_entire_file_from_filename(file)
	if !ok {
		fmt.println("Error opening font file")
		return {}, false
	}
	defer delete(font_file)

	if last_char < first_char {
		fmt.eprintln("ERROR: Invalid character range")
		os.exit(-1)
	}
	char_range: i32 = last_char - first_char + 1
	font_atlas := make([]u8, ATLAS_SIZE * ATLAS_SIZE)
	packed_chars := make([]ttf.packedchar, char_range)
	aligned_quads := make([]ttf.aligned_quad, char_range)
	defer delete(font_atlas)

	fontCtx: ttf.pack_context
	ttf.PackBegin(&fontCtx, raw_data(font_atlas), ATLAS_SIZE, ATLAS_SIZE, 0, 1, nil)
	ttf.PackFontRange(
		&fontCtx,
		raw_data(font_file),
		0,
		f32(font_size),
		i32(' '),
		char_range,
		raw_data(packed_chars),
	)
	ttf.PackEnd(&fontCtx)

	for i in 0 ..< char_range {
		unusedX, unusedY: f32
		ttf.GetPackedQuad(
			raw_data(packed_chars),
			ATLAS_SIZE,
			ATLAS_SIZE,
			i,
			&unusedX,
			&unusedY,
			&aligned_quads[i],
			false,
		)
	}

	ttf.InitFont(&font_data.info, raw_data(font_file), 0)
	font_data.atlas_tex = crgl.texture_create_2D({ATLAS_SIZE, ATLAS_SIZE}, filter = gl.LINEAR)
	crgl.texture_write_2D(font_data.atlas_tex, font_atlas, 1)
	font_data.packed_chars = packed_chars
	font_data.aligned_quads = aligned_quads
	font_data.first_char = first_char
	font_data.char_range = char_range
	font_data.font_size = font_size

	font_data.scale = ttf.ScaleForPixelHeight(&font_data.info, font_size)
	ttf.GetFontVMetrics(&font_data.info, &font_data.ascent, &font_data.descent, &font_data.linegap)

	return font_data, true
}

font_get_char_quad :: proc(
	font: Font_Data,
	char: rune,
	position: [2]f32,
	scale: f32 = 1.,
	color: [4]f32 = {1., 1., 1., 1.},
) -> (
	Font_Quad,
	bool,
) {
	if i32(char) < font.first_char || i32(char) > font.first_char + font.char_range {
		return {}, false
	}
	char_index: i32 = i32(char) - font.first_char
	pixel_scale_X: f32 = 2. * scale / f32(crgl.gContext.window.width)
	pixel_scale_Y: f32 = 2. * scale / f32(crgl.gContext.window.height)

	_packed := font.packed_chars[char_index]
	_aligned := font.aligned_quads[char_index]
	quad_size := [2]f32{f32(_packed.x1) - f32(_packed.x0), f32(_packed.y1) - f32(_packed.y0)}

	quad: Font_Quad = {
		{
			pos = {
				position[0] + f32(_packed.xoff) * pixel_scale_X,
				position[1] - f32(_packed.yoff) * pixel_scale_Y,
				0.,
			},
			uv = {f32(_aligned.s0), f32(_aligned.t0)},
			color = {1., 1., 1., 1.},
		},
		{
			pos = {
				position[0] + (f32(quad_size[0]) + f32(_packed.xoff)) * pixel_scale_X,
				position[1] - f32(_packed.yoff) * pixel_scale_Y,
				0.,
			},
			uv = {f32(_aligned.s1), f32(_aligned.t0)},
			color = {1., 1., 1., 1.},
		},
		{
			pos = {
				position[0] + f32(_packed.xoff) * pixel_scale_X,
				position[1] - (f32(quad_size[1]) + f32(_packed.yoff)) * pixel_scale_Y,
				0.,
			},
			uv = {f32(_aligned.s0), f32(_aligned.t1)},
			color = {1., 1., 1., 1.},
		},
		{
			pos = {
				position[0] + (f32(quad_size[0]) + f32(_packed.xoff)) * pixel_scale_X,
				position[1] - f32(_packed.yoff) * pixel_scale_Y,
				0.,
			},
			uv = {f32(_aligned.s1), f32(_aligned.t0)},
			color = {1., 1., 1., 1.},
		},
		{
			pos = {
				position[0] + f32(_packed.xoff) * pixel_scale_X,
				position[1] - (f32(quad_size[1]) + f32(_packed.yoff)) * pixel_scale_Y,
				0.,
			},
			uv = {f32(_aligned.s0), f32(_aligned.t1)},
			color = {1., 1., 1., 1.},
		},
		{
			pos = {
				position[0] + (f32(quad_size[0]) + f32(_packed.xoff)) * pixel_scale_X,
				position[1] - (f32(quad_size[1]) + f32(_packed.yoff)) * pixel_scale_Y,
				0.,
			},
			uv = {f32(_aligned.s1), f32(_aligned.t1)},
			color = {1., 1., 1., 1.},
		},
	}

	return quad, true
}


font_draw_text :: proc(
	font: Font_Data,
	text: string,
	position: [2]i32,
	scale: f32 = 1.,
	color: [4]f32 = {1., 1., 1., 1},
) {
	line_jump: i32 = i32(f32(font.ascent - font.descent + font.linegap) * font.scale * scale)

	// The origin is displaced by the font ascent
	// The text position is defined by the top left position
	// But the glyph quad is made from the bottom left corner
	origin := position + {0, i32(f32(font.ascent) * font.scale * scale)}
	offset: f32 = 0

	// screenPos := position_pixel_to_screen(position) // For debug
	// drawPoint({screenPos[0], screenPos[1], 0.}, color = {1., 0., 1.}) // For debug
	for char in text {
		if char == '\n' {
			origin.x = position.x
			origin.y += line_jump
			offset = 0
			continue
		}

		screen_pos := position_pixel_to_screen(origin + {i32(offset), 0})
		char_quad, char_ok := font_get_char_quad(font, char, screen_pos, scale, color)
		if !char_ok {
			continue
		}
		char_mesh := crgl.mesh_create(char_quad[:])
		defer crgl.mesh_delete(&char_mesh)
		crgl.mesh_render(char_mesh, crgl.gDefShaders.font_sh, font.atlas_tex)
		offset += font_get_char_advance(font, char, scale)
	}
}

font_get_text_quads :: proc(
	font: Font_Data,
	text: string,
	position: [2]i32,
	scale: f32 = 1.,
	color: [4]f32 = {1., 1., 1., 1},
) -> (
	quads: [dynamic]Font_Quad,
) {
	line_jump: i32 = i32(f32(font.ascent - font.descent + font.linegap) * font.scale * scale)

	// The origin is displaced by the font ascent
	// The text position is defined by the top left position
	// But the glyph quad is made from the bottom left corner
	origin := position + {0, i32(f32(font.ascent) * font.scale * scale)}
	offset: f32 = 0

	// screenPos := position_pixel_to_screen(position) // For debug
	// drawPoint({screenPos[0], screenPos[1], 0.}, color = {1., 0., 1.}) // For debug
	for char in text {
		if char == '\n' {
			origin.x = position.x
			origin.y += line_jump
			offset = 0
			continue
		}

		screen_pos := position_pixel_to_screen(origin + {i32(offset), 0})
		char_quad, char_ok := font_get_char_quad(font, char, screen_pos, scale, color)
		if !char_ok {
			continue
		}
		// char_mesh := crgl.mesh_create(char_quad[:])
		// defer crgl.mesh_delete(&char_mesh)
		// crgl.mesh_render(char_mesh, crgl.gDefShaders.font_sh, font.atlas_tex)

		append(&quads, char_quad)
		offset += font_get_char_advance(font, char, scale)
	}
	return quads
}

font_norm_to_pixels :: proc(quad: Font_Quad) -> Font_Quad {
	new_quad: Font_Quad
	for i in 0 ..< len(quad) {
		new_quad[i] = quad[i]
		new_quad[i].pos.xy =
			((new_quad[i].pos.xy + {1, 1}) / 2) *
			{f32(crgl.gContext.window.width), f32(crgl.gContext.window.height)}
	}
	return new_quad
}

// Acordar de reimplementar esto
//
// gui_textf :: proc(text: string, args: ..any) {
// 	if activeWindow.hidden do return
// 	if activeWindow.textCount == len(guiTextArray) {
// 		fmt.println("Error: max text count reached")
// 		return
// 	}
// 	text := fmt.tprintf(text, ..args)

// 	x: i32 = activeWindow.x + gGuiOptions.vpadding
// 	y: i32 = activeWindow.y + gGuiOptions.topBarHeight + activeWindow.voffset
// 	bboxWidth, bboxHeight := font_get_text_bbox(gGuiOptions.font, text, gGuiOptions.textScale)

// 	activeWindow.voffset += i32(bboxHeight) + gGuiOptions.vpadding
// 	guiTextArray[activeWindow.textCount] = GuiText{text, x, y}
// 	activeWindow.textCount += 1
// }

font_get_text_bbox :: proc(
	font: Font_Data,
	text: string,
	scale: f32 = 1.,
) -> (
	bbox_width: f32,
	bbox_height: f32,
) {
	font := font
	line_jump: i32 = i32(f32(font.ascent - font.descent + font.linegap) * font.scale * scale)

	temp_bbox_width: f32
	bbox_width = 0
	temp_bbox_width = 0
	bbox_height = f32(line_jump)

	for char in text {
		if char == '\n' {
			temp_bbox_width = 0
			bbox_height += f32(line_jump)
			continue
		}
		temp_bbox_width += font_get_char_advance(font, char, scale)
		if bbox_width < temp_bbox_width {
			bbox_width = temp_bbox_width
		}
	}
	return bbox_width, bbox_height
}

font_get_char_advance :: proc(font: Font_Data, char: rune, scale: f32 = 1.) -> f32 {
	if i32(char) < font.first_char || i32(char) > font.first_char + font.char_range {
		return 0
	}
	char_index: i32 = i32(char) - font.first_char
	return font.packed_chars[char_index].xadvance * scale
}

@(private)
position_pixel_to_screen :: proc(position: [2]i32) -> (gl_pos: [2]f32) {
	wind_X := crgl.gContext.window.width
	wind_Y := crgl.gContext.window.height
	gl_pos.x = (f32(position.x) / f32(wind_X)) * 2 - 1
	gl_pos.y = (1 - f32(position.y) / f32(wind_Y)) * 2 - 1
	return gl_pos
}

@(private)
size_pixel_to_screen :: proc(size: [2]i32) -> (gl_size: [2]f32) {
	pixel_scale_X: f32 = 2. / f32(crgl.gContext.window.width)
	pixel_scale_Y: f32 = 2. / f32(crgl.gContext.window.height)
	gl_size.x = f32(size.x) * pixel_scale_X
	gl_size.y = f32(size.y) * pixel_scale_Y
	return gl_size
}
