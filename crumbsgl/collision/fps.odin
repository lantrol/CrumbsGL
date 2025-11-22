package collision

import "core:time"

get_new_delta :: proc() -> (delta: f64) {
	@(static) last_tick: time.Tick
	duration := time.tick_since(last_tick)
	delta = time.duration_seconds(duration)
	last_tick = time.tick_now()
	return delta
}
