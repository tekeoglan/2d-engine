package foundation

// ENGINE_NAME is the human-readable name used by logs, windows, and release
// metadata. Keeping it in the foundation module prevents unrelated modules
// from inventing inconsistent names.
ENGINE_NAME :: "Ground-Up 2D Engine"

// ENGINE_VERSION_* form a semantic version. Major changes may break callers;
// minor changes add capability; patch changes correct behavior.
ENGINE_VERSION_MAJOR :: 0
ENGINE_VERSION_MINOR :: 1
ENGINE_VERSION_PATCH :: 0

// FIXED_UPDATE_HZ is the number of simulation steps requested per second.
// Rendering is deliberately not required to run at this frequency.
FIXED_UPDATE_HZ :: 60

// FIXED_DELTA_SECONDS is the duration presented to each fixed update.
FIXED_DELTA_SECONDS :: 1.0 / f64(FIXED_UPDATE_HZ)

// INVALID_SLOT_INDEX is a sentinel: a reserved value that can never identify
// a live slot. It makes invalid identifiers explicit instead of ambiguous.
INVALID_SLOT_INDEX :: ~u32(0)

// FIRST_LIVE_GENERATION reserves generation zero for invalid identifiers.
FIRST_LIVE_GENERATION :: u32(1)

// DEFAULT_FRAME_ARENA_SIZE is the initial learning-sized backing buffer for
// short-lived allocations. It is a default, not a performance target.
DEFAULT_FRAME_ARENA_SIZE :: 1024 * 1024
