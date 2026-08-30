package foundation

// Generation_Id identifies a reusable slot without confusing an old reference
// with a newer value that later occupies the same index.
//
// Invariant for a live identifier: index != INVALID_SLOT_INDEX and generation
// >= FIRST_LIVE_GENERATION.
Generation_Id :: struct {
	index:      u32,
	generation: u32,
}

// INVALID_GENERATION_ID is the canonical invalid identifier. Callers should
// compare through generation_id_is_valid rather than depending on its fields.
INVALID_GENERATION_ID :: Generation_Id{
	index = INVALID_SLOT_INDEX,
	generation = 0,
}

// generation_id_make constructs a live identifier from a slot and generation.
//
// Preconditions: index is not INVALID_SLOT_INDEX and generation is nonzero.
// Failure: programmer-invalid inputs should trigger a development assertion.
// Research: `generational index handle invariants`.
generation_id_make :: proc(index, generation: u32) -> Generation_Id {
	panic("TODO(milestone 1): implement generation_id_make")
}

// generation_id_is_valid reports whether id has the shape of a live identifier.
// It does not prove that a particular slot table currently contains the id.
//
// Allocation: none. Failure: none.
generation_id_is_valid :: proc(id: Generation_Id) -> bool {
	panic("TODO(milestone 1): implement generation_id_is_valid")
}

// generation_next returns the next live generation and skips reserved zero if
// the unsigned counter wraps.
//
// Allocation: none. Failure: none.
// Research: `unsigned integer wrap generation counter skip zero`.
generation_next :: proc(current: u32) -> u32 {
	panic("TODO(milestone 1): implement generation_next")
}
