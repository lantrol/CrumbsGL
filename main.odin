package main

import "core:fmt"
import "core:math"
import glm "core:math/linalg/glsl"
import "core:mem"
import "core:os"
import "core:sys/info"
import "core:testing"
import crgl "crumbsgl"
import col "crumbsgl/collision"
import gui "crumbsgl/gui"
import gl "vendor:OpenGL"
import sdl "vendor:sdl3"
import "vendor:stb/truetype"

GL_VERSION_MAJOR :: 4
GL_VERSION_MINOR :: 5
SCREEN_SIZE :: 900

main :: proc() {
	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

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
	gui.gui_init()
	font, _ := gui.font_atlas_from_file("crumbsgl/gui/fonts/IBMPlexSans-Regular.ttf")
	gui.set_font(font)

	// Col testing
	a: Entity = {{{5, 5}, 0.4, 0.5}, {0, 0}, .FLOOR}
	b: Entity = {{{5, 1}, 3, 3}, {0, 0}, .FLOOR}

	gravity: f32 = -14
	max_vel: f32 = 3.5

	_ = col.get_new_delta()
	loop: for {
		delta := col.get_new_delta()
		fps: f64 = 1 / delta

		// Events
		crgl.handle_events()
		if crgl.is_key_just_pressed(sdl.K_ESCAPE) do break loop
		if crgl.has_quit() do break loop

		// Move
		if a.state == .FLOOR {
			a.velocity.y = 0
			if !crgl.key_is_states(sdl.K_RIGHT, {.JustPressed, .Pressed}) &&
			   !crgl.key_is_states(sdl.K_LEFT, {.JustPressed, .Pressed}) {
				rate: f32 = 12
				a.velocity.x -=
					math.sign_f32(a.velocity.x) *
					min(abs(a.velocity.x), abs(a.velocity.x * rate * f32(delta)))
			}
		}
		a.velocity.y += gravity * f32(delta)
		if crgl.key_is_states(sdl.K_RIGHT, {.JustPressed, .Pressed}) do a.velocity.x += 20 * f32(delta)
		if crgl.key_is_states(sdl.K_LEFT, {.JustPressed, .Pressed}) do a.velocity.x -= 20 * f32(delta)
		if crgl.key_is_states(sdl.K_UP, {.JustPressed, .Pressed}) && a.state == .FLOOR {
			a.velocity.y = 6
			a.state = .AIR
		}
		//if crgl.key_is_states(sdl.K_DOWN, {.JustPressed, .Pressed}) do a.velocity.y -= 0.08

		a.velocity.x = max(min(a.velocity.x, max_vel), -max_vel)

		col_point, ok := collide_and_slide(&a, &b, delta)
		if ok {
			in_range :: proc(a, b: f32) -> bool {
				return a <= b + 0.0001 && a >= b - 0.0001
			}
			if in_range(col_point.y, a.center.y - a.halfHeight) {
				a.state = .FLOOR
			}
		} else {
			a.state = .AIR
		}

		// Draw
		gl.ClearColor(0., 0., 0., 1.)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		a_rect := crgl.rect_to_vertex(
			{
				a.center.x - a.halfWidth,
				a.center.y - a.halfHeight,
				a.halfWidth * 2,
				a.halfHeight * 2,
			},
			color = {1, 1, 1, 1},
		)
		b_rect := crgl.rect_to_vertex(
			{
				b.center.x - b.halfWidth,
				b.center.y - b.halfHeight,
				b.halfWidth * 2,
				b.halfHeight * 2,
			},
			color = {0.7, 0.7, 0.7, 1},
		)

		// Draw boxes and collision point
		proj := glm.mat4Ortho3d(left = 0, right = 10, bottom = 0, top = 10, near = 1, far = -1)
		crgl.set_uniform(crgl.gDefShaders.rect_sh, "uProjection", proj)

		rect_mesh := crgl.mesh_create(b_rect[:]);defer crgl.mesh_delete(&rect_mesh)
		crgl.mesh_render(rect_mesh, crgl.gDefShaders.rect_sh)

		crgl.mesh_write(&rect_mesh, a_rect[:])
		crgl.mesh_render(rect_mesh, crgl.gDefShaders.rect_sh)

		if ok do crgl.draw_point({col_point.x, col_point.y}, color = {0, 1, 0, 1})

		gui.window_begin("aasd", 0, 0, 200, 60)
		_ = gui.button_create(fmt.tprintf("{:.2f}", fps))
		gui.window_end()

		sdl.GL_SwapWindow(window.window)
		free_all(context.temp_allocator)
	}
}


Entity :: struct {
	using collider: col.AABB_Box,
	velocity:       [2]f32,
	state:          enum {
		FLOOR,
		AIR,
	},
}

collide_and_slide :: proc(player, wall: ^Entity, delta: f64) -> (col_point: [2]f32, ok: bool) {
	player.center += player.velocity * f32(delta)
	snap: [2]f32
	col_point, snap, ok = col.collide_aabb(player, wall)
	player.center += snap
	col_point += snap
	return col_point, ok
}
