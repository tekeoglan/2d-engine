package foundation

// INVALID_SLOT_INDEX is a sentinel: a reserved value that can never identify
// a live slot. It makes invalid identifiers explicit instead of ambiguous.
INVALID_SLOT_INDEX :: ~u32(0)

// FIRST_LIVE_GENERATION reserves generation zero for invalid identifiers.
FIRST_LIVE_GENERATION :: u32(1)

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
INVALID_GENERATION_ID :: Generation_Id {
	index      = INVALID_SLOT_INDEX,
	generation = 0,
}

// generation_id_make constructs a live identifier from a slot and generation.
//
// Preconditions: index is not INVALID_SLOT_INDEX and generation is nonzero.
// Postcondition: the result satisfies generation_id_is_valid.
// Ownership/lifetime: inputs and result are copied; no allocation occurs.
// Failure: programmer-invalid inputs should trigger a development assertion.
// Thread: safe on any thread because no shared state is used.
// Research: `generational index handle invariants`.
generation_id_make :: proc(index, generation: u32) -> Generation_Id {
	assert(index != INVALID_GENERATION_ID.index || generation != INVALID_GENERATION_ID.generation)

	return Generation_Id{index, generation}
}

// generation_id_is_valid reports whether id has the shape of a live identifier.
// It does not prove that a particular slot table currently contains the id.
//
// Preconditions: none. Postcondition: id is unchanged.
// Ownership/lifetime: input is copied; no allocation occurs.
// Failure: none. Thread: safe on any thread because no shared state is used.
// Research: `generational identifier structural validity vs live lookup`.
generation_id_is_valid :: proc(id: Generation_Id) -> bool {
	return(
		!(id.index == INVALID_GENERATION_ID.index ||
			id.generation == INVALID_GENERATION_ID.generation) \
	)
}

// generation_next returns the next live generation and skips reserved zero if
// the unsigned counter wraps.
//
// Preconditions: none. Postcondition: result is never zero.
// Ownership/lifetime: input and result are copied; no allocation occurs.
// Failure: none. Thread: safe on any thread because no shared state is used.
// Research: `unsigned integer wrap generation counter skip zero`.
generation_next :: proc(current: u32) -> u32 {
	next := current + 1
	if next == 0 {
		return FIRST_LIVE_GENERATION
	}
	return next
}
