package foundation

import "core:mem"

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
// Preconditions: arena is not initialized and remains at a stable address.
// Postcondition: on success, frame_arena_allocator may be requested until deinit.
// Ownership: storage remains owned by the caller.
// Lifetime: storage must remain valid until frame_arena_deinit returns.
// Failure: empty storage returns Invalid_Argument; an already initialized arena
// is a programmer error checked by assertion.
// Thread: main engine thread in 0.1; this value is not internally synchronized.
// Research: `Odin mem arena_init borrowed buffer`.
frame_arena_init :: proc(arena: ^Frame_Arena, storage: []byte) -> Engine_Error {
	panic("TODO(milestone 1): implement frame_arena_init")
}

// frame_arena_allocator returns an allocator that points into arena.
//
// Preconditions: arena is initialized and remains at a stable address.
// Postcondition: arena and storage are unchanged.
// Ownership: the result is a borrowed view; it owns no memory.
// Lifetime: the returned allocator is invalid after frame_arena_deinit.
// Failure: an invalid arena is a programmer error checked by assertion.
// Thread: main engine thread in 0.1; this value is not internally synchronized.
// Research: `Odin mem arena_allocator allocator data pointer`.
frame_arena_allocator :: proc(arena: ^Frame_Arena) -> mem.Allocator {
	panic("TODO(milestone 1): implement frame_arena_allocator")
}

// frame_arena_reset releases all arena allocations together for reuse.
//
// Preconditions: arena is initialized and no retained value will be used again.
// Postcondition: every pointer, slice, and string previously allocated from the
// arena is invalid and must not be read or retained.
// Ownership/lifetime: caller-owned storage remains valid and reusable.
// Failure: an invalid arena is a programmer error checked by assertion.
// Thread: main engine thread in 0.1; this value is not internally synchronized.
// Research: `arena allocator reset invalidates allocations`.
frame_arena_reset :: proc(arena: ^Frame_Arena) {
	panic("TODO(milestone 1): implement frame_arena_reset")
}

// frame_arena_deinit invalidates the wrapper without freeing caller-owned
// storage.
//
// Preconditions: arena is initialized and no arena allocation remains in use.
// Postcondition: allocator access and reset are invalid until reinitialized.
// Ownership/lifetime: caller keeps ownership of storage; borrows end here.
// Failure: an invalid arena is a programmer error checked by assertion.
// Thread: main engine thread in 0.1; this value is not internally synchronized.
// Research: `arena deinitialize borrowed backing storage ownership`.
frame_arena_deinit :: proc(arena: ^Frame_Arena) {
	panic("TODO(milestone 1): implement frame_arena_deinit")
}

// memory_context_init prepares tracked persistent allocation and frame
// allocation.
//
// Preconditions: context is zeroed and will remain at a stable address.
// Postcondition: on success, persistent and frame allocators may be requested.
// Ownership: all allocator arguments and frame_storage are borrowed.
// Lifetime: borrowed arguments must remain valid until deinit returns.
// Failure: invalid allocators or empty frame_storage return Invalid_Argument;
// allocator setup failure returns Out_Of_Memory. A nonzero or already
// initialized context is a programmer error checked by assertion.
// Thread: main engine thread in 0.1; this context is not internally synchronized.
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
// Postcondition: tracking state and context are unchanged.
// Ownership: the result is a borrowed wrapper over caller-owned backing memory.
// Lifetime: the result is invalid after memory_context_deinit.
// Failure: an invalid context is a programmer error checked by assertion.
// Thread: main engine thread in 0.1; this context is not internally synchronized.
// Research: `Odin tracking_allocator wrapper allocator data pointer`.
memory_context_persistent_allocator :: proc(memory_context: ^Memory_Context) -> mem.Allocator {
	panic("TODO(milestone 1): implement memory_context_persistent_allocator")
}

// memory_context_allocation_report snapshots tracked allocation totals.
//
// Preconditions: memory_context is initialized.
// Postcondition: tracking state is unchanged.
// Ownership/lifetime: the report is copied by value; no allocation occurs.
// Failure: an invalid context is a programmer error checked by assertion.
// Thread: main engine thread in 0.1; this context is not internally synchronized.
// Research: `Odin Tracking_Allocator current_memory_allocated allocation_map`.
memory_context_allocation_report :: proc(memory_context: ^Memory_Context) -> Allocation_Report {
	panic("TODO(milestone 1): implement memory_context_allocation_report")
}

// memory_context_deinit reports remaining allocations, destroys tracker
// metadata, and invalidates the wrapper allocators returned by this context. It
// does not destroy either caller-owned backing allocator.
//
// Preconditions: memory_context is initialized and no allocation will be used
// through its wrapper allocator after this call.
// Postcondition: memory_context is uninitialized and may be initialized again.
// Ownership/lifetime: caller-owned allocators and frame storage remain owned by
// the caller; wrapper allocator borrows end when this procedure returns.
// Failure: this procedure always returns a report; a nonzero live count is a
// diagnostic failure for the milestone gate, not a reason to skip cleanup.
// Thread: main engine thread in 0.1; this context is not internally synchronized.
// Research: `tracking allocator destroy metadata live allocation report order`.
memory_context_deinit :: proc(memory_context: ^Memory_Context) -> Allocation_Report {
	panic("TODO(milestone 1): implement memory_context_deinit")
}
