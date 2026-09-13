package input_tests

import "core:testing"

import ip "../../engine/input"

// These tests describe the scripted-playback seam. Keep the expected values
// independent from the implementation and activate one tracer bullet at a
// time as each exercise is completed.

@(test)
scripted_playback_reproduces_exact_sequence_twice :: proc(t: ^testing.T) {
	panic("TODO(milestone 3 test): replay one script twice and compare action sequences")
}

script_advances_only_with_runtime_samples :: proc(t: ^testing.T) {
	panic("TODO(milestone 3 test): specify explicit cursor advancement without sleeping")
}

short_script_applies_configured_end_policy :: proc(t: ^testing.T) {
	panic("TODO(milestone 3 test): specify hold-last versus release-all after the final frame")
}

// Keep the import and package vocabulary visible while this file is a
// scaffold; the first test should choose concrete values before using it.
_ :: ip.Scripted_Input{}
