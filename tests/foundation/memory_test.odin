package foundation_tests

import "core:testing"
import foundation "../../engine/foundation"

_ :: foundation

frame_arena_uses_caller_owned_storage :: proc(t: ^testing.T) {
	panic("TODO(milestone 1 test): prove the wrapper borrows its storage")
}

frame_arena_reset_reuses_capacity :: proc(t: ^testing.T) {
	panic("TODO(milestone 1 test): specify reset and capacity behavior")
}

persistent_allocator_reports_live_allocation :: proc(t: ^testing.T) {
	panic("TODO(milestone 1 test): allocate and inspect the tracking report")
}

persistent_allocator_reports_no_leak_after_free :: proc(t: ^testing.T) {
	panic("TODO(milestone 1 test): free owned memory and verify zero live state")
}
