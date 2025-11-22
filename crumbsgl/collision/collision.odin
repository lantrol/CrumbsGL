package collision

import "core:fmt"
import "core:math"

AABB_Box :: struct {
	center:     [2]f32,
	halfWidth:  f32,
	halfHeight: f32,
}

collide_aabb :: proc(a, b: AABB_Box) -> (col_point: [2]f32, snap: [2]f32, ok: bool) {
	ok = false
	dist := b.center - a.center

	if abs(dist.x) < (a.halfWidth + b.halfWidth) && abs(dist.y) < (a.halfHeight + b.halfHeight) {
		ok = true
		col_point = {
			clamp(dist.x, -a.halfWidth, a.halfWidth),
			clamp(dist.y, -a.halfHeight, a.halfHeight),
		}

		inside: [2]f32 = {
			(abs(dist.x) - (a.halfWidth + b.halfWidth)),
			(abs(dist.y) - (a.halfHeight + b.halfHeight)),
		}

		if abs(inside.x) > abs(inside.y) {
			snap = [2]f32{0, inside.y * math.sign_f32(dist.y)}
		} else {
			snap = [2]f32{inside.x * math.sign_f32(dist.x), 0}
		}
	}

	return a.center + col_point, snap, ok
}

collide_slide :: proc() {
	fmt.println(math.step(0.5, 0.4), math.step(0.5, 0.6))
}

collide_aabb_bk :: proc(a, b: AABB_Box) -> (col_point: [2]f32, ok: bool) {
	ok = false

	dist := b.center - a.center
	inside: [2]f32 = [2]f32 {
		(abs(dist.x) - (a.halfWidth + b.halfWidth)),
		(abs(dist.y) - (a.halfHeight + b.halfHeight)),
	}

	if abs(dist.x) < (a.halfWidth + b.halfWidth) && abs(dist.y) < (a.halfHeight + b.halfHeight) {
		pen: [2]f32
		if abs(inside.x) <= abs(inside.y) {
			pen = [2]f32{0, inside.y * math.sign_f32(dist.y)}
		} else {
			pen = [2]f32{inside.x * math.sign_f32(dist.x), 0}
		}
		col_point =
			[2]f32 {
				clamp(dist.x, -a.halfWidth, a.halfWidth),
				clamp(dist.y, -a.halfHeight, a.halfHeight),
			} -
			pen
		ok = true
	}

	return a.center - col_point, ok
}
