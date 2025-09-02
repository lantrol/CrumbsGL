package CrumbsGL2

import "core:fmt"
import "core:math"
import "core:time"
import gl "vendor:OpenGL"
import sdl "vendor:sdl3"


ButtonState :: enum {
	NotPressed,
	JustPressed,
	Pressed,
	JustReleased,
}


// Event handling
@(private = "file")
Pressed_Keys: map[sdl.Keycode]ButtonState
@(private = "file")
Key_Modifiers: map[sdl.KeymodFlag]ButtonState
@(private = "file")
Mouse_Buttons: map[sdl.MouseButtonFlag]ButtonState
@(private = "file")
Mouse_Position: [2]i32 = {}
@(private = "file")
Mouse_Displacement: [2]i32 = {}
@(private = "file")
Mouse_Scroll: struct {
	scrolled: bool,
	amount:   i32,
}
@(private = "file")
Event_Quit: bool = false

handle_events :: proc() {
	// Pre event handle and resets
	for key, value in Pressed_Keys {
		if value == .JustPressed {
			Pressed_Keys[key] = .NotPressed
		}
	}
	Mouse_Displacement[0] = 0
	Mouse_Displacement[1] = 0
	Mouse_Scroll = {false, 0}

	// Event Handling
	event: sdl.Event
	for sdl.PollEvent(&event) {
		if event.type == .QUIT {
			Event_Quit = true
		} else if event.type == .WINDOW_RESIZED {
			gl.Viewport(0, 0, event.window.data1, event.window.data2)
			gl.Scissor(0, 0, event.window.data1, event.window.data2)
			gContext.window.width = event.window.data1
			gContext.window.height = event.window.data2
		} else if event.type == .KEY_DOWN {
			if Pressed_Keys[event.key.key] == .JustPressed {
				Pressed_Keys[event.key.key] = .Pressed
			} else if Pressed_Keys[event.key.key] != .Pressed {
				Pressed_Keys[event.key.key] = .JustPressed
			}
		} else if event.type == .KEY_UP {
			Pressed_Keys[event.key.key] = .JustReleased
		} else if event.type == .MOUSE_MOTION {
			Mouse_Displacement[0] = i32(event.motion.xrel)
			Mouse_Displacement[1] = i32(event.motion.yrel)
		} else if event.type == .MOUSE_WHEEL {
			Mouse_Scroll = {true, event.wheel.integer_y}
			fmt.println(event.wheel.x, event.wheel.y)
		}
	}

	// Key modifiers
	modState: sdl.Keymod = sdl.GetModState()
	for modifier in sdl.KeymodFlag {
		if modifier in modState {
			#partial switch Key_Modifiers[modifier] {
			case .Pressed:
			case .JustPressed:
				Key_Modifiers[modifier] = .Pressed
			case:
				Key_Modifiers[modifier] = .JustPressed
			}
		} else {
			#partial switch Key_Modifiers[modifier] {
			case .NotPressed:
			case .JustReleased:
				Key_Modifiers[modifier] = .NotPressed
			case:
				Key_Modifiers[modifier] = .JustReleased
			}
		}
	}

	// Mouse input handled here to get position at same time
	x, y: f32
	mouseState: sdl.MouseButtonFlags = sdl.GetMouseState(&x, &y)
	for button in sdl.MouseButtonFlag {
		if button in mouseState {
			#partial switch Mouse_Buttons[button] {
			case .Pressed:
			case .JustPressed:
				Mouse_Buttons[button] = .Pressed
			case:
				Mouse_Buttons[button] = .JustPressed
			}
		} else {
			#partial switch Mouse_Buttons[button] {
			case .NotPressed:
			case .JustReleased:
				Mouse_Buttons[button] = .NotPressed
			case:
				Mouse_Buttons[button] = .JustReleased
			}
		}
	}
	Mouse_Position[0] = i32(x)
	Mouse_Position[1] = gContext.window.height - i32(y)
}

reset_events :: proc() {
	for key, value in Pressed_Keys {
		Pressed_Keys[key] = .NotPressed
	}
	Mouse_Buttons = {}
	Event_Quit = false
}

key_is_state :: proc(key: sdl.Keycode, state: ButtonState) -> bool {
	return Pressed_Keys[key] == state
}

key_is_states :: proc(key: sdl.Keycode, states: bit_set[ButtonState]) -> bool {
	return Pressed_Keys[key] in states
}

is_key_just_pressed :: proc(key: sdl.Keycode) -> bool {
	return Pressed_Keys[key] == .JustPressed
}

is_button_just_pressed :: proc(button: sdl.MouseButtonFlag) -> bool {
	return Mouse_Buttons[button] == .JustPressed
}

is_button_pressed :: proc(button: sdl.MouseButtonFlag) -> bool {
	return Mouse_Buttons[button] == .Pressed
}

is_modifier_pressed :: proc(mod: sdl.KeymodFlag) -> bool {
	return Key_Modifiers[mod] == .Pressed || Key_Modifiers[mod] == .JustPressed
}

get_mouse_position :: proc() -> (x, y: i32) {
	return Mouse_Position[0], Mouse_Position[1]
}

get_mouse_displacement :: proc() -> (x, y: i32) {
	return Mouse_Displacement[0], Mouse_Displacement[1]
}

has_quit :: proc() -> bool {
	return Event_Quit
}

