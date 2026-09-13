package input_tests

import "core:testing"

import ip "../../engine/input"

make_script_frame :: proc(
	space_held: bool,
	wheel: f32 = 0,
	focused: bool = true,
	left_held: bool = false,
) -> ip.Raw_Input_Snapshot {
	frame := ip.Raw_Input_Snapshot{is_focused = focused}
	frame.keys[.Space].held = space_held
	frame.mouse_buttons[.Left].held = left_held
	frame.mouse_wheel_delta = wheel
	return frame
}

collect_action_sequence :: proc(
	t: ^testing.T,
	script: ^ip.Scripted_Input,
	mapping: ^ip.Input_Mapping,
	count: int,
	out: []ip.Digital_Action_State,
) {
	ctx: ip.Input_Context
	err := ip.input_context_init(&ctx, ip.input_config_default())
	testing.expect(t, err.kind == .None, "input init should succeed")
	defer ip.input_context_deinit(&ctx)
	ip.input_context_set_source(&ctx, ip.scripted_input_source(script))
	for i in 0 ..< count {
		ip.input_begin_frame(&ctx)
		snap := ip.input_snapshot(&ctx)
		out[i] = ip.input_digital_state(mapping, &snap, 0)
		ip.input_end_frame(&ctx)
	}
}

@(test)
scripted_playback_reproduces_exact_sequence_twice :: proc(t: ^testing.T) {
	frames := []ip.Raw_Input_Snapshot {
		make_script_frame(false),
		make_script_frame(true),
		make_script_frame(true, 1.0),
		make_script_frame(false),
	}
	script: ip.Scripted_Input
	err := ip.scripted_input_init(&script, frames, .Hold_Last_Frame)
	testing.expect(t, err.kind == .None, "script init should succeed")
	defer ip.scripted_input_deinit(&script)

	mapping: ip.Input_Mapping
	err = ip.input_mapping_init(&mapping, 1, 0)
	testing.expect(t, err.kind == .None, "mapping init should succeed")
	err = ip.input_mapping_bind_digital(&mapping, 0, ip.Digital_Binding{kind = .Key, key = .Space})
	testing.expect(t, err.kind == .None, "bind should succeed")

	first := make([]ip.Digital_Action_State, len(frames))
	defer delete(first)
	collect_action_sequence(t, &script, &mapping, len(frames), first)

	// Rewind and replay without a window, without sleeping, and without
	// reading wall-clock time.
	ip.scripted_input_reset(&script)
	second := make([]ip.Digital_Action_State, len(frames))
	defer delete(second)
	collect_action_sequence(t, &script, &mapping, len(frames), second)

	for i in 0 ..< len(frames) {
		testing.expect(
			t,
			second[i] == first[i],
			"replayed script should produce byte-identical actions",
		)
	}
	// Spot-check the derived edges: press once, hold, release once.
	testing.expect(t, first[0] == ip.Digital_Action_State{}, "frame 0 should be released")
	testing.expect(
		t,
		first[1].pressed && first[1].held,
		"frame 1 should press",
	)
	testing.expect(t, first[2].held && !first[2].pressed, "frame 2 should hold")
	testing.expect(t, first[3].released && !first[3].held, "frame 3 should release")
}

@(test)
script_advances_only_with_runtime_samples :: proc(t: ^testing.T) {
	frames := []ip.Raw_Input_Snapshot{make_script_frame(false), make_script_frame(true)}
	script: ip.Scripted_Input
	err := ip.scripted_input_init(&script, frames, .Hold_Last_Frame)
	testing.expect(t, err.kind == .None, "script init should succeed")
	defer ip.scripted_input_deinit(&script)

	testing.expect(t, ip.scripted_input_frame_count(&script) == 2, "frame count should match script")
	testing.expect(t, ip.scripted_input_current_frame(&script) == 0, "cursor should start at zero")

	ctx: ip.Input_Context
	err = ip.input_context_init(&ctx, ip.input_config_default())
	testing.expect(t, err.kind == .None, "input init should succeed")
	defer ip.input_context_deinit(&ctx)
	ip.input_context_set_source(&ctx, ip.scripted_input_source(&script))

	// No sampling, no advancement.
	testing.expect(t, ip.scripted_input_current_frame(&script) == 0, "cursor should not advance alone")
	ip.input_end_frame(&ctx)
	testing.expect(t, ip.scripted_input_current_frame(&script) == 0, "end of frame should not advance cursor")

	ip.input_begin_frame(&ctx)
	testing.expect(t, ip.scripted_input_current_frame(&script) == 1, "one sample should advance one frame")
	ip.input_end_frame(&ctx)
	testing.expect(t, ip.scripted_input_current_frame(&script) == 1, "end should still not advance")

	ip.input_begin_frame(&ctx)
	testing.expect(t, ip.scripted_input_current_frame(&script) == 2, "second sample should reach the end")
	snap := ip.input_snapshot(&ctx)
	testing.expect(t, ip.input_key_state(&snap, .Space).held, "second frame should hold space")
	ip.input_end_frame(&ctx)

	// Empty scripts are rejected instead of crashing later sampling.
	empty_script: ip.Scripted_Input
	empty_frames := []ip.Raw_Input_Snapshot{}
	bad := ip.scripted_input_init(&empty_script, empty_frames, .Release_All)
	testing.expect(t, bad.kind == .Invalid_Argument, "empty script should be rejected")
}

@(test)
short_script_applies_configured_end_policy :: proc(t: ^testing.T) {
	// Hold-last repeats held levels with a zero wheel delta.
	hold_frames := []ip.Raw_Input_Snapshot{make_script_frame(true, 2.0)}
	hold_script: ip.Scripted_Input
	err := ip.scripted_input_init(&hold_script, hold_frames, .Hold_Last_Frame)
	testing.expect(t, err.kind == .None, "hold script init should succeed")
	defer ip.scripted_input_deinit(&hold_script)

	hold_ctx: ip.Input_Context
	err = ip.input_context_init(&hold_ctx, ip.input_config_default())
	testing.expect(t, err.kind == .None, "input init should succeed")
	defer ip.input_context_deinit(&hold_ctx)
	ip.input_context_set_source(&hold_ctx, ip.scripted_input_source(&hold_script))

	ip.input_begin_frame(&hold_ctx)
	snap := ip.input_snapshot(&hold_ctx)
	testing.expect(t, snap.mouse_wheel_delta == 2.0, "in-script wheel should pass through")
	ip.input_end_frame(&hold_ctx)
	ip.input_begin_frame(&hold_ctx)
	snap = ip.input_snapshot(&hold_ctx)
	testing.expect(t, ip.input_key_state(&snap, .Space).held, "hold-last should repeat held keys")
	testing.expect(t, snap.mouse_wheel_delta == 0, "hold-last should not repeat wheel deltas")
	ip.input_end_frame(&hold_ctx)

	// Release-all reports everything released past the end.
	release_frames := []ip.Raw_Input_Snapshot{make_script_frame(true, 2.0)}
	release_script: ip.Scripted_Input
	err = ip.scripted_input_init(&release_script, release_frames, .Release_All)
	testing.expect(t, err.kind == .None, "release script init should succeed")
	defer ip.scripted_input_deinit(&release_script)

	release_ctx: ip.Input_Context
	err = ip.input_context_init(&release_ctx, ip.input_config_default())
	testing.expect(t, err.kind == .None, "input init should succeed")
	defer ip.input_context_deinit(&release_ctx)
	ip.input_context_set_source(&release_ctx, ip.scripted_input_source(&release_script))

	ip.input_begin_frame(&release_ctx)
	ip.input_end_frame(&release_ctx)
	ip.input_begin_frame(&release_ctx)
	snap = ip.input_snapshot(&release_ctx)
	released := ip.input_key_state(&snap, .Space)
	testing.expect(t, !released.held, "release-all should release keys past the end")
	testing.expect(t, snap.mouse_wheel_delta == 0, "release-all should report zero wheel")
	ip.input_end_frame(&release_ctx)
}
