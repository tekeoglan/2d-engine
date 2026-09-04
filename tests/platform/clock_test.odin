package platform_tests

import "core:testing"

import pl "../../engine/platform"

deterministic_clock_starts_at_requested_time :: proc(t: ^testing.T) {
	panic("TODO(milestone 2 test): specify deterministic clock initialization")
}

deterministic_clock_advances_only_when_told :: proc(t: ^testing.T) {
	panic("TODO(milestone 2 test): specify explicit clock advancement")
}

deterministic_clock_rejects_negative_advance :: proc(t: ^testing.T) {
	panic("TODO(milestone 2 test): specify negative-time error behavior")
}

clock_adapter_reads_deterministic_clock :: proc(t: ^testing.T) {
	panic("TODO(milestone 2 test): specify the common clock seam")
}

system_clock_is_non_decreasing :: proc(t: ^testing.T) {
	panic("TODO(milestone 2 test): add the supported-host monotonic clock check")
}

_ :: pl.Deterministic_Clock{}
