package input_tests

import "core:testing"

import ip "../../engine/input"

// Test_Driver_State is a minimal deterministic device behind the input seam.
// Each frame the test assigns the desired held levels; the sampler writes
// the complete held state so edges are derived exactly like live devices.
Test_Driver_State :: struct {
	space_held:      bool,
	left_held:       bool,
	wheel_delta:     f32,
	focused:         bool,
	mouse_x, mouse_y: f32,
}

test_driver_sample :: proc(data: rawptr, snapshot: ^ip.Raw_Input_Snapshot) {
	state := cast(^Test_Driver_State)data
	// Write a complete device level each sample: every unmentioned control
	// reads released, mirroring a full keyboard/mouse poll.
	for key in ip.Key_Code {
		snapshot.keys[key].held = false
		snapshot.keys[key].pressed = false
		snapshot.keys[key].released = false
	}
	for button in ip.Mouse_Button {
		snapshot.mouse_buttons[button].held = false
		snapshot.mouse_buttons[button].pressed = false
		snapshot.mouse_buttons[button].released = false
	}
	snapshot.keys[.Space].held = state.space_held
	snapshot.mouse_buttons[.Left].held = state.left_held
	snapshot.mouse_position = ip.Mouse_Position{state.mouse_x, state.mouse_y}
	snapshot.mouse_wheel_delta = state.wheel_delta
	snapshot.is_focused = state.focused
}

make_test_context :: proc(
	ctx: ^ip.Input_Context,
	driver: ^Test_Driver_State,
	clear_on_focus_loss: bool,
	t: ^testing.T,
) {
	driver^ = Test_Driver_State{focused = true}
	err := ip.input_context_init(ctx, ip.Input_Config{clear_on_focus_loss = clear_on_focus_loss})
	testing.expect(t, err.kind == .None, "input context init should succeed")
	ip.input_context_set_source(ctx, ip.Input_Source{sample_proc = test_driver_sample, data = driver})
}

@(test)
raw_edges_report_pressed_held_released_across_frames :: proc(t: ^testing.T) {
	ctx: ip.Input_Context
	driver: Test_Driver_State
	make_test_context(&ctx, &driver, true, t)
	defer ip.input_context_deinit(&ctx)

	// Frame 1: press Space (up -> down).
	driver.space_held = true
	ip.input_begin_frame(&ctx)
	snap := ip.input_snapshot(&ctx)
	space := ip.input_key_state(&snap, .Space)
	testing.expect(t, space.pressed, "press frame should report pressed")
	testing.expect(t, space.held, "press frame should report held")
	testing.expect(t, !space.released, "press frame should not report released")
	// The shared snapshot is stable until the frame ends.
	snap2 := ip.input_snapshot(&ctx)
	space2 := ip.input_key_state(&snap2, .Space)
	testing.expect(
		t,
		space2 == space,
		"every fixed update in one frame should observe identical edges",
	)
	ip.input_end_frame(&ctx)
	// Edges clear at the boundary but holding persists.
	snap_cleared := ip.input_snapshot(&ctx)
	cleared := ip.input_key_state(&snap_cleared, .Space)
	testing.expect(t, !cleared.pressed, "end of frame should clear pressed")
	testing.expect(t, cleared.held, "end of frame should preserve held")
	testing.expect(t, !cleared.released, "end of frame should clear released")

	// Frames 2-3: hold across two more frames (down -> down).
	for _ in 0 ..< 2 {
		ip.input_begin_frame(&ctx)
		snap = ip.input_snapshot(&ctx)
		space = ip.input_key_state(&snap, .Space)
		testing.expect(t, !space.pressed, "held frame should not repeat pressed")
		testing.expect(t, space.held, "held frame should report held")
		testing.expect(t, !space.released, "held frame should not report released")
		ip.input_end_frame(&ctx)
	}

	// Frame 4: release Space (down -> up).
	driver.space_held = false
	ip.input_begin_frame(&ctx)
	snap = ip.input_snapshot(&ctx)
	space = ip.input_key_state(&snap, .Space)
	testing.expect(t, !space.pressed, "release frame should not report pressed")
	testing.expect(t, !space.held, "release frame should not report held")
	testing.expect(t, space.released, "release frame should report released exactly once")
	ip.input_end_frame(&ctx)

	// Frame 5: rest (up -> up) reports fully released.
	ip.input_begin_frame(&ctx)
	snap = ip.input_snapshot(&ctx)
	space = ip.input_key_state(&snap, .Space)
	testing.expect(t, !space.pressed && !space.held && !space.released, "rest frame should be fully released")
	ip.input_end_frame(&ctx)

	// Unknown controls are total and never drive edges.
	unknown := ip.input_key_state(&snap, .Unknown)
	testing.expect(
		t,
		!unknown.pressed && !unknown.held && !unknown.released,
		"unknown keys should read as fully released",
	)
	unknown_button := ip.input_mouse_button_state(&snap, .Unknown)
	testing.expect(
		t,
		!unknown_button.pressed && !unknown_button.held && !unknown_button.released,
		"unknown buttons should read as fully released",
	)
}

@(test)
focus_loss_applies_configured_stuck_input_policy :: proc(t: ^testing.T) {
	// With clearing enabled, focus loss forces a released edge and can
	// never leave a stuck held state.
	ctx: ip.Input_Context
	driver: Test_Driver_State
	make_test_context(&ctx, &driver, true, t)
	defer ip.input_context_deinit(&ctx)

	driver.space_held = true
	ip.input_begin_frame(&ctx)
	snap := ip.input_snapshot(&ctx)
	testing.expect(t, ip.input_key_state(&snap, .Space).held, "setup frame should hold space")
	ip.input_end_frame(&ctx)

	// Platform reports focus loss; the device still reads down.
	ip.input_notify_focus_changed(&ctx, false)
	ip.input_begin_frame(&ctx)
	snap = ip.input_snapshot(&ctx)
	lost := ip.input_key_state(&snap, .Space)
	testing.expect(t, !lost.held, "focus loss with clearing should force release")
	testing.expect(t, lost.released, "focus loss should report one released edge")
	testing.expect(t, !lost.pressed, "focus loss should not report pressed")
	testing.expect(t, !snap.is_focused, "sampled frame should report unfocused")
	testing.expect(t, snap.mouse_wheel_delta == 0, "unfocused frame should clear wheel")
	ip.input_end_frame(&ctx)

	// Next unfocused frame stays released with no repeated edge.
	ip.input_notify_focus_changed(&ctx, false)
	driver.space_held = true
	ip.input_begin_frame(&ctx)
	snap = ip.input_snapshot(&ctx)
	still := ip.input_key_state(&snap, .Space)
	testing.expect(
		t,
		!still.held && !still.pressed && !still.released,
		"held-down input during focus loss should stay released without edges",
	)
	ip.input_end_frame(&ctx)

	// Focus regained with the device still down re-presses exactly once.
	ip.input_notify_focus_changed(&ctx, true)
	driver.space_held = true
	ip.input_begin_frame(&ctx)
	snap = ip.input_snapshot(&ctx)
	regained := ip.input_key_state(&snap, .Space)
	testing.expect(t, regained.pressed && regained.held, "regained focus with device down should press again")
	ip.input_end_frame(&ctx)

	// With clearing disabled, focus loss preserves held state verbatim.
	ctx2: ip.Input_Context
	driver2: Test_Driver_State
	make_test_context(&ctx2, &driver2, false, t)
	defer ip.input_context_deinit(&ctx2)
	driver2.space_held = true
	ip.input_begin_frame(&ctx2)
	ip.input_end_frame(&ctx2)
	ip.input_notify_focus_changed(&ctx2, false)
	ip.input_begin_frame(&ctx2)
	snap2 := ip.input_snapshot(&ctx2)
	kept := ip.input_key_state(&snap2, .Space)
	testing.expect(t, kept.held, "clearing disabled should preserve held across focus loss")
	testing.expect(t, !kept.released, "clearing disabled should not synthesize release")
	ip.input_end_frame(&ctx2)
}

@(test)
mouse_wheel_delta_clears_at_frame_boundary :: proc(t: ^testing.T) {
	ctx: ip.Input_Context
	driver: Test_Driver_State
	make_test_context(&ctx, &driver, true, t)
	defer ip.input_context_deinit(&ctx)

	driver.wheel_delta = 1.5
	driver.mouse_x, driver.mouse_y = 320, 240
	ip.input_begin_frame(&ctx)
	snap := ip.input_snapshot(&ctx)
	testing.expect(t, snap.mouse_wheel_delta == 1.5, "sampled frame should carry wheel delta")
	testing.expect(
		t,
		snap.mouse_position == ip.Mouse_Position{320, 240},
		"sampled frame should carry mouse position",
	)
	// Mouse buttons share the same edge policy as keys.
	driver.left_held = true
	ip.input_end_frame(&ctx)
	snap = ip.input_snapshot(&ctx)
	testing.expect(t, snap.mouse_wheel_delta == 0, "end of frame should clear wheel delta")
	// Wheel never holds: a zero delta next frame reads cleared even when
	// the test driver stops writing it.
	driver.wheel_delta = 0
	ip.input_begin_frame(&ctx)
	snap = ip.input_snapshot(&ctx)
	testing.expect(t, snap.mouse_wheel_delta == 0, "wheel delta should not persist across frames")
	testing.expect(
		t,
		snap.mouse_position == ip.Mouse_Position{320, 240},
		"mouse position should persist until the next sample moves it",
	)
	ip.input_end_frame(&ctx)
}
