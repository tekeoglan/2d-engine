package foundation_tests

import "core:testing"

import fo "../../engine/foundation"

@(test)
zero_generation_is_invalid :: proc(t: ^testing.T) {
	zero_id := fo.Generation_Id{}

	testing.expect(
		t,
		!fo.generation_id_is_valid(zero_id),
		"a zero generation must not identify a live slot",
	)
}

@(test)
invalid_slot_index_is_invalid :: proc(t: ^testing.T) {
	testing.expect(
		t,
		!fo.generation_id_is_valid(fo.INVALID_GENERATION_ID),
		"the canonical invalid identifier must not be valid",
	)
}

@(test)
generation_wrap_skips_reserved_zero :: proc(t: ^testing.T) {
	testing.expect_value(
		t,
		fo.generation_next(fo.INVALID_SLOT_INDEX),
		fo.FIRST_LIVE_GENERATION,
	)
}
