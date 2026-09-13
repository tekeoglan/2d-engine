package input

import fo "../foundation"
import "core:c"
import sdl "vendor:sdl3"

// Sdl_Input_State owns the live-device sampling behind the input seam.
// window_handle borrows the platform window (rawptr so callers never import
// SDL); wheel_accum sums vertical wheel ticks observed by the event watch
// since the last sample. No memory is allocated; the value must stay at a
// stable address while sources borrow it.
Sdl_Input_State :: struct {
	window_handle:  rawptr,
	wheel_accum:    f32,
	is_initialized: bool,
}

// sdl_input_init prepares live keyboard/mouse sampling over a borrowed
// platform window. A nil window is allowed and simply reports focused with
// a zero mouse position; production callers pass the platform window
// handle so focus and mouse state track the real window.
//
// The adapter registers an SDL event watch that accumulates vertical wheel
// motion. The watch lets wheel deltas survive the platform event drain:
// platform polling drops input events, but the watch observes every wheel
// event when it is pushed, sums it here, and the sampler reads and clears
// the sum once per input frame.
//
// Preconditions: state points to zeroed, stable storage and is not already
// initialized. The SDL video/events subsystem is initialized before the
// first sample.
// Postconditions: on success, sdl_input_source may be called.
// Ownership/lifetime: window stays owned by the platform caller and must
// outlive state or be replaced via sdl_input_set_window.
// Failure: an invalid state returns Invalid_Argument; a failed event-watch
// registration returns a Platform error and acquires nothing.
// Thread: main engine thread in 0.1; not internally synchronized.
sdl_input_init :: proc(state: ^Sdl_Input_State, window_handle: rawptr) -> fo.Engine_Error {
	if state == nil || state.is_initialized {
		return fo.Engine_Error{.Invalid_Argument, "SDL input state invalid."}
	}
	state^ = Sdl_Input_State{window_handle = window_handle}
	if !sdl.AddEventWatch(sdl_wheel_watch_proc, state) {
		state^ = Sdl_Input_State{}
		return fo.Engine_Error{.Platform, "SDL could not register the wheel event watch."}
	}
	state.is_initialized = true
	return fo.NO_ERROR
}

// sdl_input_deinit removes the wheel event watch and marks the value
// uninitialized. The borrowed platform window is untouched.
//
// Preconditions: state is initialized and no source borrows it after this
// call.
// Postconditions: state is zeroed/uninitialized.
// Ownership/lifetime: caller-owned window storage is untouched.
// Failure: none.
// Thread: main engine thread in 0.1; not internally synchronized.
sdl_input_deinit :: proc(state: ^Sdl_Input_State) {
	assert(state != nil && state.is_initialized, "Invalid SDL input state.")
	sdl.RemoveEventWatch(sdl_wheel_watch_proc, state)
	state^ = Sdl_Input_State{}
}

// sdl_input_set_window replaces the borrowed platform window sampled for
// focus and mouse state. Pass nil to sample without a window.
//
// Preconditions: state is initialized.
// Postconditions: the next sample reads focus/mouse against the new window.
// Ownership/lifetime: the window stays owned by the caller.
// Failure: an invalid state is a programmer error.
// Thread: main engine thread in 0.1; not internally synchronized.
sdl_input_set_window :: proc(state: ^Sdl_Input_State, window_handle: rawptr) {
	assert(state != nil && state.is_initialized, "Invalid SDL input state.")
	state.window_handle = window_handle
}

// sdl_wheel_watch_proc observes every pushed SDL event and sums vertical
// wheel motion into the borrowed adapter state. All other events,
// including keyboard, mouse button/motion, and unknown device events, are
// kept deliberately without interpretation: buttons and keys are read via
// polled device state, so event traffic never leaks through the seam.
// FLIPPED wheel direction is normalized by negating, per SDL convention.
@(private = "package")
sdl_wheel_watch_proc :: proc "c" (userdata: rawptr, event: ^sdl.Event) -> bool {
	if userdata == nil || event == nil {
		return true
	}
	if event.type != .MOUSE_WHEEL {
		return true
	}
	state := cast(^Sdl_Input_State)userdata
	delta := event.wheel.y
	if event.wheel.direction == .FLIPPED {
		delta = -delta
	}
	state.wheel_accum += delta
	return true
}

// sdl_key_scancode maps one engine key to its SDL physical scancode.
// Left_Shift maps to LSHIFT; the sampler ORs RSHIFT in separately so
// either shift key drives the action. Unknown maps to UNKNOWN.
@(private = "package")
sdl_key_scancode :: proc(key: Key_Code) -> sdl.Scancode {
	switch key {
	case .Unknown:
		return .UNKNOWN
	case .A:
		return .A
	case .D:
		return .D
	case .W:
		return .W
	case .S:
		return .S
	case .Q:
		return .Q
	case .E:
		return .E
	case .Z:
		return .Z
	case .X:
		return .X
	case .C:
		return .C
	case .Left:
		return .LEFT
	case .Right:
		return .RIGHT
	case .Up:
		return .UP
	case .Down:
		return .DOWN
	case .Space:
		return .SPACE
	case .Enter:
		return .RETURN
	case .Escape:
		return .ESCAPE
	case .Tab:
		return .TAB
	case .Left_Shift:
		return .LSHIFT
	case .P:
		return .P
	case .M:
		return .M
	}
	return .UNKNOWN
}

// sdl_keyboard_held reports whether an engine key is down in the polled
// SDL keyboard array. Out-of-range scancodes read as released.
@(private = "package")
sdl_keyboard_held :: proc(keys: [^]bool, numkeys: c.int, key: Key_Code) -> bool {
	if key == .Unknown {
		return false
	}
	if key == .Left_Shift {
		// Either physical shift drives the engine shift control.
		left_code := int(sdl.Scancode.LSHIFT)
		right_code := int(sdl.Scancode.RSHIFT)
		left_down := left_code >= 0 && left_code < int(numkeys) && keys[left_code]
		right_down := right_code >= 0 && right_code < int(numkeys) && keys[right_code]
		return left_down || right_down
	}
	code := int(sdl_key_scancode(key))
	if code < 0 || code >= int(numkeys) {
		return false
	}
	return keys[code]
}

// sdl_input_sample_proc implements the Input_Sample_Proc seam over live
// devices. It pumps pending OS input, reads the full keyboard array and
// window-relative mouse state, drains the watch-accumulated wheel delta,
// and reports window focus. Only held levels, position, wheel, and focus
// are written; edges are derived by the input context.
@(private = "package")
sdl_input_sample_proc :: proc(data: rawptr, snapshot: ^Raw_Input_Snapshot) {
	assert(data != nil, "Invalid SDL input state.")
	assert(snapshot != nil, "Invalid input snapshot.")
	state := cast(^Sdl_Input_State)data
	assert(state.is_initialized, "Invalid SDL input state.")

	sdl.PumpEvents()

	numkeys: c.int
	keys := sdl.GetKeyboardState(&numkeys)
	if keys != nil {
		for key in Key_Code {
			if key == .Unknown {
				snapshot.keys[key].held = false
				continue
			}
			snapshot.keys[key].held = sdl_keyboard_held(keys, numkeys, key)
			snapshot.keys[key].pressed = false
			snapshot.keys[key].released = false
		}
	}

	mouse_x, mouse_y: f32
	buttons := sdl.GetMouseState(&mouse_x, &mouse_y)
	snapshot.mouse_position = Mouse_Position{mouse_x, mouse_y}
	snapshot.mouse_buttons[.Left].held = .LEFT in buttons
	snapshot.mouse_buttons[.Right].held = .RIGHT in buttons
	snapshot.mouse_buttons[.Middle].held = .MIDDLE in buttons
	snapshot.mouse_buttons[.Extra_1].held = .X1 in buttons
	snapshot.mouse_buttons[.Extra_2].held = .X2 in buttons
	for button in Mouse_Button {
		if button == .Unknown {
			snapshot.mouse_buttons[button] = Button_State{}
			continue
		}
		snapshot.mouse_buttons[button].pressed = false
		snapshot.mouse_buttons[button].released = false
	}

	snapshot.mouse_wheel_delta = state.wheel_accum
	state.wheel_accum = 0

	if state.window_handle != nil {
		window := cast(^sdl.Window)state.window_handle
		flags := sdl.GetWindowFlags(window)
		snapshot.is_focused = .INPUT_FOCUS in flags
	} else {
		snapshot.is_focused = true
	}
}

// sdl_input_source exposes live devices through the common input seam.
// The returned adapter borrows state and becomes invalid when state is
// deinitialized or moved.
//
// Preconditions: state is initialized and remains at a stable address.
// Postconditions: sampling through the adapter polls live devices once
// per input frame.
// Ownership/lifetime: the adapter owns no device state.
// Failure: an invalid state is a programmer error.
// Thread: main engine thread in 0.1; not internally synchronized.
sdl_input_source :: proc(state: ^Sdl_Input_State) -> Input_Source {
	assert(state != nil && state.is_initialized, "Invalid SDL input state.")
	return Input_Source{sample_proc = sdl_input_sample_proc, data = state}
}
