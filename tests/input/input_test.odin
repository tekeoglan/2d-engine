package input_tests

import "core:testing"

import ip "../../engine/input"

// These tests describe public raw-input seams. Keep the expected values
// independent from the implementation and activate one tracer bullet at a
// time as each exercise is completed.

@(test)
raw_edges_report_pressed_held_released_across_frames :: proc(t: ^testing.T) {
	panic("TODO(milestone 3 test): specify pressed/held/released transitions across sampled frames")
}

focus_loss_applies_configured_stuck_input_policy :: proc(t: ^testing.T) {
	panic("TODO(milestone 3 test): specify focus-loss clearing and the configured policy")
}

mouse_wheel_delta_clears_at_frame_boundary :: proc(t: ^testing.T) {
	panic("TODO(milestone 3 test): specify per-frame wheel delta lifetime")
}

// Keep the import and package vocabulary visible while this file is a
// scaffold; the first test should choose concrete values before using it.
_ :: ip.Input_Context{}
