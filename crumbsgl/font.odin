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
	packedChars:  []ttf.packedchar,
	alignedQuads: []ttf.aligned_quad,
	firstChar:    i32,
	charRange:    i32,
}

font_atlas_from_file :: proc(file: string, firstChar: i32, charRange: i32) -> (FontData, bool) {
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
		FONT_SIZE,
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

	return FontData{fontAtlas, packedChars, alignedQuads, firstChar, charRange}, true
}

font_font_to_png :: proc(fontData: FontData, $fileName: cstring) {
	img.write_png(fileName, ATLAS_SIZE, ATLAS_SIZE, 1, raw_data(fontData.atlas), ATLAS_SIZE)
}

font_laod_default_shader :: proc() -> (u32, bool) {
	return gl.load_shaders_source(defaultVS, defaultFS)
}


@(private = "file")
defaultVS: string = `
#version 450 core

struct VertexData {
	float position[3];
	float uv[2];
};

layout(binding = 0, std430) readonly buffer ssbo1 {
	VertexData data[];
};

out vec2 iUvs;

vec3 getPosition(int index) {
    return vec3(
        data[index].position[0],
        data[index].position[1],
        data[index].position[2]
    );
}

vec2 getUV(int index) {
    return vec2(
        data[index].uv[0],
        data[index].uv[1]
    );
}

void main() {
    iUvs = getUV(gl_VertexID);
    gl_Position = vec4(getPosition(gl_VertexID), 1.0);
}
`


@(private = "file")
defaultFS: string = `
#version 450 core

uniform sampler2D atlas;

in vec2 iUvs;
out vec4 frag_color;

void main() {
	frag_color = texture(atlas, iUvs);
}

`
