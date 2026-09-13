package input_tests

import "core:testing"

import ip "../../engine/input"

// These tests describe the action-mapping seam. Keep the expected values
// independent from the implementation and activate one tracer bullet at a
// time as each exercise is completed.

@(test)
digital_action_combines_multiple_sources_deterministically :: proc(t: ^testing.T) {
	panic("TODO(milestone 3 test): specify multi-source digital combination and edges")
}

analog_action_combines_key_pair_and_wheel :: proc(t: ^testing.T) {
	panic("TODO(milestone 3 test): specify analog key-pair and wheel combination with scale and clamp")
}

rebinding_replaces_documented_combination_result :: proc(t: ^testing.T) {
	panic("TODO(milestone 3 test): specify rebinding and clearing behavior")
}

unbound_actions_read_as_released_and_zero :: proc(t: ^testing.T) {
	panic("TODO(milestone 3 test): specify total queries for unbound actions")
}

// Keep the import and package vocabulary visible while this file is a
// scaffold; the first test should choose concrete values before using it.
_ :: ip.Input_Mapping{}
