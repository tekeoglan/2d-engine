package input

import fo "../foundation"

// scripted_input_init prepares the deterministic test adapter over a
// caller-owned frame script. The runtime consumes exactly one script frame
// per runtime frame and advances only when the runtime samples.
//
// Only held states, mouse position, wheel delta, and focus in each script
// frame are meaningful; pressed/released stored in script frames are
// ignored and re-derived by the input context so scripted and live sources
// share one edge policy. Tests therefore write held patterns and assert
// derived edges.
//
// Preconditions: script points to zeroed, stable storage and is not already
// initialized. frames is borrowed and stays valid until deinit.
// Postconditions: on success, scripted_input_source may be called and the
// cursor reads the first frame.
// Ownership/lifetime: frames stays owned by the caller; the adapter copies
// nothing. script must remain at a stable address while sources borrow it.
// Failure: an empty script returns Invalid_Argument.
// Thread: safe only on the owning test thread.
// Research: `deterministic input playback scripted test adapter game`.
scripted_input_init :: proc(
	script: ^Scripted_Input,
	frames: []Raw_Input_Snapshot,
	end_policy: Script_End_Policy,
) -> fo.Engine_Error {
	if script == nil || script.is_initialized {
		return fo.Engine_Error{.Invalid_Argument, "Scripted input invalid."}
	}
	if len(frames) == 0 {
		return fo.Engine_Error{.Invalid_Argument, "Scripted input needs at least one frame."}
	}
	script^ = Scripted_Input{
		frames         = frames,
		cursor         = 0,
		end_policy     = end_policy,
		is_initialized = true,
	}
	return fo.NO_ERROR
}

// scripted_input_deinit releases adapter ownership without freeing the
// caller-owned frame script.
//
// Preconditions: script is initialized and no source borrows it after this
// call.
// Postconditions: script is zeroed/uninitialized.
// Ownership/lifetime: caller-owned frames are untouched.
// Failure: none.
// Thread: safe only on the owning test thread.
// Research: `test adapter deinit borrowed script lifetime`.
scripted_input_deinit :: proc(script: ^Scripted_Input) {
	assert(script != nil && script.is_initialized, "Invalid scripted input.")
	script^ = Scripted_Input{}
}

// scripted_input_reset rewinds the cursor to the first frame so a test can
// replay the same script and observe an identical action sequence.
//
// Preconditions: script is initialized.
// Postconditions: the next sample reads the first frame.
// Ownership/lifetime: no caller ownership changes.
// Failure: an invalid script is a programmer error.
// Thread: safe only on the owning test thread.
// Research: `input script replay reset deterministic test`.
scripted_input_reset :: proc(script: ^Scripted_Input) {
	assert(script != nil && script.is_initialized, "Invalid scripted input.")
	script.cursor = 0
}

// scripted_input_copy_held copies only the sampled device levels from src
// to dst: held states, mouse position, wheel delta, and focus. Edges in
// src are ignored because the context re-derives them.
@(private = "package")
scripted_input_copy_held :: proc(dst: ^Raw_Input_Snapshot, src: ^Raw_Input_Snapshot) {
	for key in Key_Code {
		dst.keys[key].held = src.keys[key].held
		dst.keys[key].pressed = false
		dst.keys[key].released = false
	}
	for button in Mouse_Button {
		dst.mouse_buttons[button].held = src.mouse_buttons[button].held
		dst.mouse_buttons[button].pressed = false
		dst.mouse_buttons[button].released = false
	}
	dst.mouse_position = src.mouse_position
	dst.mouse_wheel_delta = src.mouse_wheel_delta
	dst.is_focused = src.is_focused
}

// scripted_input_sample_proc implements the Input_Sample_Proc seam. It
// writes exactly one script frame per call and advances the cursor, so the
// script moves only when the runtime samples. Past the final frame the
// configured end policy applies: Hold_Last_Frame repeats the final held
// levels/position/focus with a zero wheel delta; Release_All reports every
// control released with a zero wheel, the final mouse position, and
// focused.
@(private = "package")
scripted_input_sample_proc :: proc(data: rawptr, snapshot: ^Raw_Input_Snapshot) {
	assert(data != nil, "Invalid scripted input.")
	assert(snapshot != nil, "Invalid input snapshot.")
	script := cast(^Scripted_Input)data
	assert(script.is_initialized, "Invalid scripted input.")
	if script.cursor < len(script.frames) {
		frame := &script.frames[script.cursor]
		scripted_input_copy_held(snapshot, frame)
		script.cursor += 1
		return
	}
	// Past the end: total behavior, never a crash.
	last := &script.frames[len(script.frames) - 1]
	#partial switch script.end_policy {
	case .Hold_Last_Frame:
		scripted_input_copy_held(snapshot, last)
		snapshot.mouse_wheel_delta = 0
	case .Release_All:
		for key in Key_Code {
			snapshot.keys[key] = Button_State{}
		}
		for button in Mouse_Button {
			snapshot.mouse_buttons[button] = Button_State{}
		}
		snapshot.mouse_position = last.mouse_position
		snapshot.mouse_wheel_delta = 0
		snapshot.is_focused = true
	}
}

// scripted_input_source exposes the script through the common input seam.
// The returned adapter borrows script and becomes invalid when script is
// deinitialized or moved.
//
// Preconditions: script is initialized and remains at a stable address.
// Postconditions: sampling through the adapter advances the cursor one frame
// per sample under the configured end policy.
// Ownership/lifetime: the adapter owns no script state.
// Failure: an invalid script is a programmer error.
// Thread: safe only on the owning test thread.
// Research: `function pointer deterministic input adapter`.
scripted_input_source :: proc(script: ^Scripted_Input) -> Input_Source {
	assert(script != nil && script.is_initialized, "Invalid scripted input.")
	return Input_Source{sample_proc = scripted_input_sample_proc, data = script}
}

// scripted_input_frame_count reports how many scripted frames the adapter
// holds. The script is unchanged.
//
// Preconditions: script is initialized.
// Postconditions: script is unchanged.
// Ownership/lifetime: no allocation occurs.
// Failure: an invalid script is a programmer error.
// Thread: safe only on the owning test thread.
// Research: `frame indexed input script length query`.
scripted_input_frame_count :: proc(script: ^Scripted_Input) -> int {
	assert(script != nil && script.is_initialized, "Invalid scripted input.")
	return len(script.frames)
}

// scripted_input_current_frame reports the zero-based cursor of the next
// frame the adapter will sample.
//
// Preconditions: script is initialized.
// Postconditions: script is unchanged.
// Ownership/lifetime: no allocation occurs.
// Failure: an invalid script is a programmer error.
// Thread: safe only on the owning test thread.
// Research: `scripted input cursor explicit advancement test`.
scripted_input_current_frame :: proc(script: ^Scripted_Input) -> int {
	assert(script != nil && script.is_initialized, "Invalid scripted input.")
	return script.cursor
}
