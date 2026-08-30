package foundation_tests

import "core:testing"
import foundation "../../engine/foundation"

_ :: foundation

zero_generation_is_invalid :: proc(t: ^testing.T) {
	panic("TODO(milestone 1 test): specify the reserved-zero invariant")
}

invalid_slot_index_is_invalid :: proc(t: ^testing.T) {
	panic("TODO(milestone 1 test): specify the sentinel-index invariant")
}

generation_wrap_skips_reserved_zero :: proc(t: ^testing.T) {
	panic("TODO(milestone 1 test): specify wrapping generation behavior")
}
