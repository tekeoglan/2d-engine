package input

import fo "../foundation"

// input_config_default returns the first-run device tuning: stuck-input
// clearing on focus loss.
//
// Preconditions: none.
// Postconditions: the value is safe to pass to input_context_init.
// Ownership/lifetime: the returned value is copied and allocates no memory.
// Failure: none.
// Thread: safe on any thread because no shared state is used.
// Research: `focus loss clear input stuck keys game`.
input_config_default :: proc() -> Input_Config {
	return {true}
}

// input_context_init prepares sampled input state from an explicit config.
// No device is opened here; the source is selected with
// input_context_set_source and defaults to sampling nothing.
//
// Preconditions: context points to zeroed, stable storage and is not already
// initialized.
// Postconditions: on success, input_begin_frame, input_snapshot, and
// input_context_deinit may be called.
// Ownership/lifetime: context must remain at a stable address until deinit;
// values are copied and no memory is allocated.
// Failure: an invalid context returns Invalid_Argument.
// Thread: main engine thread in 0.1; not internally synchronized.
// Research: `opaque input context resource ownership`.
input_context_init :: proc(ctx: ^Input_Context, config: Input_Config) -> fo.Engine_Error {
	if ctx == nil || ctx.is_initialized {
		return fo.Engine_Error{.Invalid_Argument, "Input context invalid."}
	}
	ctx^ = Input_Context {
		config   = config,
		source   = Input_Source{},
		current  = Raw_Input_Snapshot{},
		previous = Raw_Input_Snapshot{},
	}
	ctx.current.is_focused = true
	ctx.previous.is_focused = true
	ctx.is_initialized = true

	return fo.NO_ERROR
}

// input_context_deinit releases input ownership and marks the context
// uninitialized. Borrowed sources and script frames stay owned by the caller.
//
// Preconditions: context is initialized and no caller retains its snapshot
// after this call.
// Postconditions: context is zeroed/uninitialized.
// Ownership/lifetime: caller-owned sources are untouched.
// Failure: none; cleanup diagnostics must not skip later cleanup.
// Thread: main engine thread in 0.1; not internally synchronized.
// Research: `resource acquisition initialization reverse order cleanup`.
input_context_deinit :: proc(ctx: ^Input_Context) {
	assert(ctx != nil && ctx.is_initialized, "Invalid input context.")

	ctx^ = Input_Context{}
	ctx.is_initialized = false
}

// input_source_none returns a source that samples nothing. Tests that drive
// snapshots directly use it to keep the sampling seam total.
//
// Preconditions: none.
// Postconditions: sampling through the result leaves the snapshot unchanged.
// Ownership/lifetime: the returned value is copied and owns nothing.
// Failure: none.
// Thread: safe on any thread because no shared state is used.
// Research: `null input source test seam deterministic`.
input_source_none :: proc() -> Input_Source {
	return Input_Source{sample_proc = input_none_sample_proc, data = nil}
}

@(private = "package")
input_none_sample_proc :: proc(data: rawptr, snapshot: ^Raw_Input_Snapshot) {
	// Deliberately samples nothing so the caller's preserved held state
	// flows into edge derivation unchanged. Snapshot is untouched.
	_ = data
	_ = snapshot
}

// input_context_set_source selects the SDL keyboard/mouse or scripted adapter
// sampled by later frames. The SDL adapter is private to this package;
// callers only see the seam.
//
// Preconditions: context is initialized and source callbacks are valid for
// the borrowed data's lifetime, or source is the none value.
// Postconditions: the next input_begin_frame samples through source.
// Ownership/lifetime: source data stays owned by the caller and must outlive
// the context or be replaced before its lifetime ends.
// Failure: an invalid context is a programmer error.
// Thread: main engine thread in 0.1; not internally synchronized.
// Research: `function pointer adapter borrowed context lifetime`.
input_context_set_source :: proc(ctx: ^Input_Context, source: Input_Source) {
	assert(ctx != nil && ctx.is_initialized, "Invalid input context.")
	ctx.source = source
}

// input_begin_frame samples the selected source once and derives the
// pressed/held/released edges from the retained previous frame. Focus loss
// applies the configured stuck-input policy before edges are derived.
//
// Edge policy: pressed is true exactly when new held is down and old held
// was up; released is true exactly when new held is up and old held was
// down; held mirrors new held. A key tapped and released between two
// samples is invisible to edges by design: sampling observes held levels,
// not inter-sample transitions. A key held across three frames reports
// pressed once, then held-only, then released on the matching release
// sample. All fixed updates in the same runtime frame share this snapshot.
//
// Focus policy: the pending platform observation (if any) overrides the
// sampled focus for this frame. When the effective frame is unfocused and
// clear_on_focus_loss is set, every sampled held state is forced released
// and the wheel reads as zero before edges are derived, so held controls
// report one released edge and can never stick.
//
// Preconditions: context is initialized and remains at a stable address.
// Postconditions: input_snapshot returns the shared frame every fixed update
// in this runtime frame observes until input_end_frame.
// Ownership/lifetime: sampled values are owned by context and stay valid
// until the next begin or deinit.
// Failure: an invalid context is a programmer error; backend sampling
// failures are reported when the backend exposes them.
// Thread: main engine thread in 0.1; not internally synchronized.
// Research: `input edge pressed held released frame state`.
input_begin_frame :: proc(ctx: ^Input_Context) {
	assert(ctx != nil && ctx.is_initialized, "Invalid input context.")

	// Start from preserved held state so the none source (which writes
	// nothing) flows through unchanged.
	sampled := ctx.current
	// Clear stale edges from the preserved copy; sources only write held.
	for key in Key_Code {
		sampled.keys[key].pressed = false
		sampled.keys[key].released = false
	}
	for button in Mouse_Button {
		sampled.mouse_buttons[button].pressed = false
		sampled.mouse_buttons[button].released = false
	}
	if ctx.source.sample_proc != nil {
		ctx.source.sample_proc(ctx.source.data, &sampled)
	}

	// Resolve effective focus: a pending platform observation wins over
	// whatever the device sampled, and is consumed exactly once.
	effective_focused := sampled.is_focused
	if ctx.has_pending_focus {
		effective_focused = ctx.pending_focused
		ctx.has_pending_focus = false
	}
	sampled.is_focused = effective_focused

	// Apply the stuck-input guard before edge derivation.
	if !effective_focused && ctx.config.clear_on_focus_loss {
		for key in Key_Code {
			sampled.keys[key].held = false
		}
		for button in Mouse_Button {
			sampled.mouse_buttons[button].held = false
		}
		sampled.mouse_wheel_delta = 0
	}

	// Derive single-frame edges against retained history.
	derived := sampled
	for key in Key_Code {
		new_held := sampled.keys[key].held
		old_held := ctx.previous.keys[key].held
		derived.keys[key] = Button_State {
			pressed  = new_held && !old_held,
			held     = new_held,
			released = !new_held && old_held,
		}
	}
	for button in Mouse_Button {
		new_held := sampled.mouse_buttons[button].held
		old_held := ctx.previous.mouse_buttons[button].held
		derived.mouse_buttons[button] = Button_State {
			pressed  = new_held && !old_held,
			held     = new_held,
			released = !new_held && old_held,
		}
	}
	ctx.current = derived
	ctx.previous = derived
}

// input_end_frame clears single-frame edges and the mouse wheel delta while
// preserving held state for the next sampled release.
//
// Preconditions: context is initialized.
// Postconditions: pressed, released, and wheel values read as cleared until
// the next input_begin_frame; held values are unchanged.
// Ownership/lifetime: no caller ownership changes.
// Failure: an invalid context is a programmer error.
// Thread: main engine thread in 0.1; not internally synchronized.
// Research: `input frame boundary clear edge wheel delta`.
input_end_frame :: proc(ctx: ^Input_Context) {
	assert(ctx != nil && ctx.is_initialized, "Invalid input context.")
	for key in Key_Code {
		ctx.current.keys[key].pressed = false
		ctx.current.keys[key].released = false
	}
	for button in Mouse_Button {
		ctx.current.mouse_buttons[button].pressed = false
		ctx.current.mouse_buttons[button].released = false
	}
	ctx.current.mouse_wheel_delta = 0
	// Keep previous.held aligned with current.held so the next begin
	// compares against the preserved hold, not against cleared edges.
	for key in Key_Code {
		ctx.previous.keys[key].pressed = false
		ctx.previous.keys[key].released = false
		ctx.previous.keys[key].held = ctx.current.keys[key].held
	}
	for button in Mouse_Button {
		ctx.previous.mouse_buttons[button].pressed = false
		ctx.previous.mouse_buttons[button].released = false
		ctx.previous.mouse_buttons[button].held = ctx.current.mouse_buttons[button].held
	}
	ctx.previous.mouse_wheel_delta = 0
	ctx.previous.mouse_position = ctx.current.mouse_position
	ctx.previous.is_focused = ctx.current.is_focused
}

// input_snapshot returns a copy of the current sampled frame for fixed
// updates and mapping queries.
//
// Preconditions: context is initialized.
// Postconditions: context is unchanged.
// Ownership/lifetime: the returned value is copied and owns no memory.
// Failure: an invalid context is a programmer error.
// Thread: main engine thread in 0.1; not internally synchronized.
// Research: `input snapshot shared fixed updates single sample per frame`.
input_snapshot :: proc(ctx: ^Input_Context) -> Raw_Input_Snapshot {
	assert(ctx != nil && ctx.is_initialized, "Invalid input context.")
	return ctx.current
}

// input_notify_focus_changed records the platform focus observation consumed
// by the next input_begin_frame under the configured stuck-input policy.
//
// Preconditions: context is initialized.
// Postconditions: the next sampled frame reflects the recorded focus.
// Ownership/lifetime: no allocation occurs.
// Failure: an invalid context is a programmer error.
// Thread: main engine thread in 0.1; not internally synchronized.
// Research: `focus loss clear input stuck keys game`.
input_notify_focus_changed :: proc(ctx: ^Input_Context, focused: bool) {
	assert(ctx != nil && ctx.is_initialized, "Invalid input context.")
	ctx.has_pending_focus = true
	ctx.pending_focused = focused
}

// input_key_state reads one key triple from a snapshot. The snapshot is
// borrowed for the duration of the call.
//
// Preconditions: none; Unknown keys read as fully released.
// Postconditions: snapshot is unchanged.
// Ownership/lifetime: inputs are borrowed; no allocation occurs.
// Failure: none.
// Thread: safe on any thread because no shared state is used.
// Research: `input snapshot accessor borrowed query total function`.
input_key_state :: proc(snapshot: ^Raw_Input_Snapshot, key: Key_Code) -> Button_State {
	assert(snapshot != nil, "Invalid input snapshot.")
	if key == .Unknown {
		return Button_State{}
	}
	return snapshot.keys[key]
}

// input_mouse_button_state reads one mouse button triple from a snapshot.
//
// Preconditions: none; Unknown buttons read as fully released.
// Postconditions: snapshot is unchanged.
// Ownership/lifetime: inputs are borrowed; no allocation occurs.
// Failure: none.
// Thread: safe on any thread because no shared state is used.
// Research: `mouse button state snapshot accessor`.
input_mouse_button_state :: proc(
	snapshot: ^Raw_Input_Snapshot,
	button: Mouse_Button,
) -> Button_State {
	assert(snapshot != nil, "Invalid input snapshot.")
	if button == .Unknown {
		return Button_State{}
	}
	return snapshot.mouse_buttons[button]
}
