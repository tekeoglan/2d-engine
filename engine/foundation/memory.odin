package foundation

import "core:mem"

// Memory_Lifetime names the conceptual lifetime of an allocation. It is
// documentation data, not an automatic garbage collector.
Memory_Lifetime :: enum {
	Frame,
	Scene,
	Engine,
}

// Allocation_Ownership records whether a caller or module is responsible for
// releasing a value. It is intended for diagnostic and teaching structures.
Allocation_Ownership :: enum {
	Caller,
	Module,
}

// Frame_Arena wraps Odin's arena with the borrowed buffer that establishes its
// lifetime.
//
// Ownership: storage is borrowed and must outlive this value. Frame_Arena never
// frees storage. Moving this value after callers retain its allocator is unsafe
// because that allocator refers to the arena's address.
Frame_Arena :: struct {
	storage:        []byte,
	arena:          mem.Arena,
	is_initialized: bool,
}

// Allocation_Report captures tracking totals without exposing the tracking
// allocator's internal map to other modules.
Allocation_Report :: struct {
	live_allocation_count: i64,
	live_byte_count:       i64,
	peak_byte_count:       i64,
	bad_free_count:        i64,
}

// Memory_Context owns tracking metadata and borrows the frame buffer and
// backing allocators provided during initialization.
//
// Ownership: backing_allocator and tracker_internals_allocator must remain
// valid until memory_context_deinit returns. This context must stay at a stable
// address after initialization because allocators can point into it.
Memory_Context :: struct {
	backing_allocator:           mem.Allocator,
	tracker_internals_allocator: mem.Allocator,
	persistent_tracker:          mem.Tracking_Allocator,
	frame:                       Frame_Arena,
	is_initialized:              bool,
}

// frame_arena_init prepares arena to allocate from caller-owned storage.
//
// Preconditions: arena is not initialized and storage is nonempty.
// Postconditions: frame_arena_allocator may be requested until deinit.
// Ownership: storage remains owned by the caller.
// Research: `Odin mem arena_init borrowed buffer`.
frame_arena_init :: proc(arena: ^Frame_Arena, storage: []byte) -> Engine_Error {
	panic("TODO(milestone 1): implement frame_arena_init")
}

// frame_arena_allocator returns an allocator that points into arena.
//
// Preconditions: arena is initialized and remains at a stable address.
// Lifetime: the returned allocator is invalid after frame_arena_deinit.
// Research: `Odin mem arena_allocator allocator data pointer`.
frame_arena_allocator :: proc(arena: ^Frame_Arena) -> mem.Allocator {
	panic("TODO(milestone 1): implement frame_arena_allocator")
}

// frame_arena_reset releases all arena allocations together for reuse.
//
// Postcondition: every pointer, slice, and string previously allocated from the
// arena is invalid and must not be read or retained.
// Research: `arena allocator reset invalidates allocations`.
frame_arena_reset :: proc(arena: ^Frame_Arena) {
	panic("TODO(milestone 1): implement frame_arena_reset")
}

// frame_arena_deinit invalidates the wrapper without freeing caller-owned
// storage.
//
// Postcondition: allocator access and reset are invalid until reinitialized.
frame_arena_deinit :: proc(arena: ^Frame_Arena) {
	panic("TODO(milestone 1): implement frame_arena_deinit")
}

// memory_context_init prepares tracked persistent allocation and frame
// allocation.
//
// Preconditions: context is zeroed, allocators are valid, frame_storage is
// nonempty, and context will remain at a stable address.
// Ownership: all allocator arguments and frame_storage are borrowed.
// Research: `Odin tracking_allocator_init internals allocator lifetime`.
memory_context_init :: proc(
	memory_context:             ^Memory_Context,
	backing_allocator:          mem.Allocator,
	tracker_internals_allocator: mem.Allocator,
	frame_storage:              []byte,
) -> Engine_Error {
	panic("TODO(milestone 1): implement memory_context_init")
}

// memory_context_persistent_allocator returns the allocator through which
// engine-lifetime allocations must pass for tracking.
//
// Preconditions: memory_context is initialized and remains at a stable address.
// Lifetime: the result is invalid after memory_context_deinit.
memory_context_persistent_allocator :: proc(memory_context: ^Memory_Context) -> mem.Allocator {
	panic("TODO(milestone 1): implement memory_context_persistent_allocator")
}

// memory_context_allocation_report snapshots tracked allocation totals.
//
// Preconditions: memory_context is initialized.
// Allocation: none; the report is returned by value.
memory_context_allocation_report :: proc(memory_context: ^Memory_Context) -> Allocation_Report {
	panic("TODO(milestone 1): implement memory_context_allocation_report")
}

// memory_context_deinit reports remaining allocations, destroys tracker
// metadata, and invalidates both allocators owned by this context.
//
// Preconditions: callers have already freed every persistent allocation.
// Postcondition: memory_context is uninitialized and may be initialized again.
// Failure: live allocations remain visible in the returned report.
memory_context_deinit :: proc(memory_context: ^Memory_Context) -> Allocation_Report {
	panic("TODO(milestone 1): implement memory_context_deinit")
}
