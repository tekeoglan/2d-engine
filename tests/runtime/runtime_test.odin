package runtime_tests

import "core:testing"

import ru "../../engine/runtime"

// These tests describe public runtime seams. Keep the expected values
// independent from the implementation and activate one tracer bullet at a
// time as each exercise is completed. Drive every timestamp through the
// deterministic clock; fixed updates must never read wall-clock time.

@(test)
accumulator_runs_zero_one_and_many_fixed_updates :: proc(t: ^testing.T) {
	panic("TODO(milestone 3 test): specify step counts for zero, exact, and fractional frame times")
}

frame_hitch_is_bounded_by_step_cap :: proc(t: ^testing.T) {
	panic("TODO(milestone 3 test): specify bounded catch-up for a pathological time gap")
}

render_callback_is_paced_independently_with_bounded_alpha :: proc(t: ^testing.T) {
	panic("TODO(milestone 3 test): specify one render call per frame with alpha in [0, 1)")
}

quit_event_is_observable_without_termination :: proc(t: ^testing.T) {
	panic("TODO(milestone 3 test): specify quit ordering alongside input and resize events")
}

shutdown_releases_owned_runtime_state :: proc(t: ^testing.T) {
	panic("TODO(milestone 3 test): add the lifecycle and leak assertions")
}

// Keep the import and package vocabulary visible while this file is a
// scaffold; the first test should choose concrete values before using it.
_ :: ru.Runtime_Context{}
