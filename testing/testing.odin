package main

import "core:fmt"
import "core:os"
import img "vendor:stb/image"
import ttf "vendor:stb/truetype"

main :: proc() {
	// Reading font data
	font_file, ok := os.read_entire_file_from_filename("./Comic Sans MS.ttf")
	defer delete(font_file)

	font_size: f32 = 64.
	fontAtlasWidth: i32 = 1024
	fontAtlasHeight: i32 = 1024
	fontAtlasBitmap: []u8 = make([]u8, fontAtlasWidth * fontAtlasHeight)
	fontDataBuf: []u8 = make([]u8, len(font_file))
	charsToInclude := i32('~') - i32(' ')
	fmt.println(charsToInclude)

	packedChars: []ttf.packedchar = make([]ttf.packedchar, charsToInclude)
	alignedQuads: []ttf.aligned_quad = make([]ttf.aligned_quad, charsToInclude)

	font_ctx: ttf.pack_context
	ttf.PackBegin(&font_ctx, raw_data(fontAtlasBitmap), fontAtlasWidth, fontAtlasHeight, 0, 1, nil)
	ttf.PackFontRange(
		&font_ctx,
		raw_data(font_file),
		0,
		font_size,
		i32(' '),
		charsToInclude,
		raw_data(packedChars),
	)
	ttf.PackEnd(&font_ctx)

	for i in 0 ..< charsToInclude {
		unusedX, unusedY: f32
		ttf.GetPackedQuad(
			raw_data(packedChars),
			fontAtlasWidth,
			fontAtlasHeight,
			i,
			&unusedX,
			&unusedY,
			&alignedQuads[i],
			false,
		)
	}
	img.write_png(
		"./test.png",
		fontAtlasWidth,
		fontAtlasHeight,
		1,
		raw_data(fontAtlasBitmap),
		fontAtlasWidth,
	)

	fmt.println(packedChars[2])
	fmt.println(alignedQuads[2])
}
