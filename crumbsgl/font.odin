package CrumbsGL

import "core:fmt"
import "core:os"
import gl "vendor:OpenGL"
import img "vendor:stb/image"
import ttf "vendor:stb/truetype"

ATLAS_SIZE :: 1024
FONT_SIZE :: 64.

FontData :: struct {
	atlas:        []u8,
	atlasTex:     Texture,
	packedChars:  []ttf.packedchar,
	alignedQuads: []ttf.aligned_quad,
	firstChar:    i32,
	charRange:    i32,
}

font_atlas_from_file :: proc(
	file: string,
	firstChar: i32,
	charRange: i32,
) -> (
	fontData: FontData,
	font_ok: bool,
) {
	fontFile, ok := os.read_entire_file_from_filename(file)
	if !ok {
		fmt.println("Error opening font file")
		return {}, false
	}
	defer delete(fontFile)

	fontAtlas := make([]u8, ATLAS_SIZE * ATLAS_SIZE)
	packedChars := make([]ttf.packedchar, charRange)
	alignedQuads := make([]ttf.aligned_quad, charRange)

	fontCtx: ttf.pack_context
	ttf.PackBegin(&fontCtx, raw_data(fontAtlas), ATLAS_SIZE, ATLAS_SIZE, 0, 1, nil)
	ttf.PackFontRange(
		&fontCtx,
		raw_data(fontFile),
		0,
		f32(FONT_SIZE),
		i32(' '),
		charRange,
		raw_data(packedChars),
	)
	ttf.PackEnd(&fontCtx)

	for i in 0 ..< charRange {
		unusedX, unusedY: f32
		ttf.GetPackedQuad(
			raw_data(packedChars),
			ATLAS_SIZE,
			ATLAS_SIZE,
			i,
			&unusedX,
			&unusedY,
			&alignedQuads[i],
			false,
		)
	}

	fontData.atlasTex = createTexture2D(ATLAS_SIZE, ATLAS_SIZE)
	writeTexture2D(fontData.atlasTex, fontAtlas, 1, ATLAS_SIZE, ATLAS_SIZE)
	fontData.atlas = fontAtlas
	fontData.packedChars = packedChars
	fontData.alignedQuads = alignedQuads
	fontData.firstChar = firstChar
	fontData.charRange = charRange

	return fontData, true
}

font_font_to_png :: proc(fontData: FontData, $fileName: cstring) {
	img.write_png(fileName, ATLAS_SIZE, ATLAS_SIZE, 1, raw_data(fontData.atlas), ATLAS_SIZE)
}

font_get_char_quad :: proc(font: FontData, char: rune, position: [2]f32) -> ([6]Vertex, bool) {
	if i32(char) < font.firstChar || i32(char) > font.firstChar + font.charRange {
		return {}, false
	}
	charIndex: i32 = i32(char) - font.firstChar
	pixelScaleX: f32 = 1. / f32(font.atlasTex.width)
	pixelScaleY: f32 = 1. / f32(font.atlasTex.height)

	_packed := font.packedChars[charIndex]
	_aligned := font.alignedQuads[charIndex]
	quadSize := [2]f32{f32(_packed.x1) - f32(_packed.x0), f32(_packed.y1) - f32(_packed.y0)}

	quad: [6]Vertex = {
		{
			{
				position[0] + f32(_packed.xoff) * pixelScaleX,
				position[1] - f32(_packed.yoff) * pixelScaleY,
				0.,
			},
			{f32(_aligned.s0), f32(_aligned.t0)},
		},
		{
			{
				position[0] + (f32(quadSize[0]) + f32(_packed.xoff)) * pixelScaleX,
				position[1] - f32(_packed.yoff) * pixelScaleY,
				0.,
			},
			{f32(_aligned.s1), f32(_aligned.t0)},
		},
		{
			{
				position[0] + f32(_packed.xoff) * pixelScaleX,
				position[1] - (f32(quadSize[1]) + f32(_packed.yoff)) * pixelScaleY,
				0.,
			},
			{f32(_aligned.s0), f32(_aligned.t1)},
		},
		{
			{
				position[0] + (f32(quadSize[0]) + f32(_packed.xoff)) * pixelScaleX,
				position[1] - f32(_packed.yoff) * pixelScaleY,
				0.,
			},
			{f32(_aligned.s1), f32(_aligned.t0)},
		},
		{
			{
				position[0] + f32(_packed.xoff) * pixelScaleX,
				position[1] - (f32(quadSize[1]) + f32(_packed.yoff)) * pixelScaleY,
				0.,
			},
			{f32(_aligned.s0), f32(_aligned.t1)},
		},
		{
			{
				position[0] + (f32(quadSize[0]) + f32(_packed.xoff)) * pixelScaleX,
				position[1] - (f32(quadSize[1]) + f32(_packed.yoff)) * pixelScaleY,
				0.,
			},
			{f32(_aligned.s1), f32(_aligned.t1)},
		},
	}

	return quad, true
}

font_draw_text :: proc(font: FontData, text: string, position: [2]f32) {
	origin := position
	offset: f32 = 0

	drawPoint({origin[0], origin[1], 0.}, color = {1., 0., 1.})
	for char in text {
		charQuad, char_ok := font_get_char_quad(font, char, origin + {offset, 0})
		if !char_ok {
			return
		}
		charMesh := createMesh(charQuad[:])
		defer deleteMesh(&charMesh)
		renderMesh(charMesh, sh_get_default_font_shader(), font.atlasTex)
		offset += font_get_char_advance(font, char)
	}
}

font_get_char_advance :: proc(font: FontData, char: rune) -> f32 {
	if i32(char) < font.firstChar || i32(char) > font.firstChar + font.charRange {
		return 0
	}
	charIndex: i32 = i32(char) - font.firstChar
	pixelScaleX: f32 = 1. / f32(font.atlasTex.width)

	return f32(font.packedChars[charIndex].xadvance) * pixelScaleX
}
