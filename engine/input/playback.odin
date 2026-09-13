package input

import fo "../foundation"

// scripted_input_init prepares the deterministic test adapter over a
// caller-owned frame script. The runtime consumes exactly one script frame
// per runtime frame and advances only when the runtime samples.
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
	panic("TODO(milestone 3): initialize scripted input")
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
	panic("TODO(milestone 3): deinitialize scripted input")
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
	panic("TODO(milestone 3): reset scripted input cursor")
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
	panic("TODO(milestone 3): build scripted input source")
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
	panic("TODO(milestone 3): report scripted frame count")
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
	panic("TODO(milestone 3): report scripted input cursor")
}
