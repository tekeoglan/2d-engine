package foundation_tests

import "core:mem"
import "core:testing"

import fo "../../engine/foundation"

@(test)
frame_arena_uses_caller_owned_storage :: proc(t: ^testing.T) {
	storage := []byte{'h', 'e', 'l', 'l', 'o'}
	fa: fo.Frame_Arena

	err := fo.frame_arena_init(&fa, storage)
	testing.expect(t, err.kind == .None, "frame arena initialization should succeed")
	testing.expect(t, fa.is_initialized, "frame arena should be initialized")
	testing.expect(
		t,
		raw_data(storage) == raw_data(fa.storage),
		"frame arena should retain the caller's backing storage",
	)

	fo.frame_arena_deinit(&fa)
	testing.expect(t, !fa.is_initialized, "frame arena should be uninitialized after deinit")
	testing.expect(t, len(fa.storage) == 0, "deinit should clear the borrowed storage view")
	testing.expect(t, storage[0] == 'h', "deinit must not free caller-owned storage")
}

@(test)
frame_arena_init_rejects_nil_storage :: proc(t: ^testing.T) {
	fa: fo.Frame_Arena

	err := fo.frame_arena_init(&fa, nil)
	testing.expect(t, err.kind == .Invalid_Argument, "nil frame storage should be rejected")
	testing.expect(t, !fa.is_initialized, "failed initialization must leave the arena inactive")
}

@(test)
frame_arena_allocator_allocates_from_storage :: proc(t: ^testing.T) {
	storage := [128]byte{}
	fa: fo.Frame_Arena
	err := fo.frame_arena_init(&fa, storage[:])
	testing.expect(t, err.kind == .None, "frame arena initialization should succeed")

	allocator := fo.frame_arena_allocator(&fa)
	allocation, alloc_err := mem.alloc_bytes(24, allocator=allocator)
	testing.expect(
		t,
		alloc_err == .None && allocation != nil,
		"frame allocator should allocate while the arena has capacity",
	)
	if allocation != nil {
		testing.expect(
			t,
			&allocation[0] == &storage[0],
			"frame allocation should begin in the caller-provided buffer",
		)
	}

	fo.frame_arena_deinit(&fa)
}

@(test)
frame_arena_reset_reuses_capacity :: proc(t: ^testing.T) {
	storage := [128]byte{}
	fa: fo.Frame_Arena
	err := fo.frame_arena_init(&fa, storage[:])
	testing.expect(t, err.kind == .None, "frame arena initialization should succeed")

	allocator := fo.frame_arena_allocator(&fa)
	first, first_err := mem.alloc_bytes(24, allocator=allocator)
	testing.expect(t, first_err == .None && first != nil, "first frame allocation should succeed")
	if first == nil {
		fo.frame_arena_deinit(&fa)
		return
	}
	first_address := &first[0]

	fo.frame_arena_reset(&fa)
	testing.expect(t, fa.is_initialized, "reset should keep the arena initialized")

	second, second_err := mem.alloc_bytes(24, allocator=allocator)
	testing.expect(t, second_err == .None && second != nil, "arena should be reusable after reset")
	if second != nil {
		testing.expect(
			t,
			&second[0] == first_address,
			"reset should release the previous allocation for reuse",
		)
	}

	fo.frame_arena_deinit(&fa)
}

@(test)
frame_arena_allocator_reports_out_of_memory :: proc(t: ^testing.T) {
	storage := [16]byte{}
	fa: fo.Frame_Arena
	err := fo.frame_arena_init(&fa, storage[:])
	testing.expect(t, err.kind == .None, "frame arena initialization should succeed")

	allocation, alloc_err := mem.alloc_bytes(128, allocator=fo.frame_arena_allocator(&fa))
	testing.expect(t, allocation == nil, "an oversized frame allocation should return no memory")
	testing.expect(t, alloc_err == .Out_Of_Memory, "an oversized frame allocation should report out of memory")

	fo.frame_arena_deinit(&fa)
}

@(test)
memory_context_rejects_invalid_initialization_arguments :: proc(t: ^testing.T) {
	storage := [128]byte{}
	memory_context: fo.Memory_Context

	err := fo.memory_context_init(&memory_context, mem.Allocator{}, context.allocator, storage[:])
	testing.expect(t, err.kind == .Invalid_Argument, "a missing backing allocator should be rejected")
	testing.expect(t, !memory_context.is_initialized, "failed context initialization must not activate the context")

	err = fo.memory_context_init(&memory_context, context.allocator, mem.Allocator{}, storage[:])
	testing.expect(t, err.kind == .Invalid_Argument, "a missing tracker allocator should be rejected")
	testing.expect(t, !memory_context.is_initialized, "failed context initialization must not activate the context")

	err = fo.memory_context_init(&memory_context, context.allocator, context.allocator, []byte{})
	testing.expect(t, err.kind == .Invalid_Argument, "empty frame storage should be rejected")
	testing.expect(t, !memory_context.is_initialized, "failed context initialization must not activate the context")
}

@(test)
memory_context_persistent_allocator_tracks_live_allocation :: proc(t: ^testing.T) {
	frame_storage := [256]byte{}
	memory_context: fo.Memory_Context
	err := fo.memory_context_init(
		&memory_context,
		context.allocator,
		context.allocator,
		frame_storage[:],
	)
	testing.expect(t, err.kind == .None, "memory context initialization should succeed")
	if err.kind != .None {
		return
	}

	persistent_allocator := fo.memory_context_persistent_allocator(&memory_context)
	allocation, alloc_err := mem.alloc_bytes(32, allocator=persistent_allocator)
	testing.expect(
		t,
		alloc_err == .None && allocation != nil,
		"persistent allocator should allocate requested memory",
	)
	if allocation == nil {
		fo.memory_context_deinit(&memory_context)
		return
	}

	report := fo.memory_context_allocation_report(&memory_context)
	testing.expect(t, report.live_allocation_count == 1, "report should contain one live allocation")
	testing.expect(t, report.live_byte_count == 32, "report should contain the live allocation size")
	testing.expect(t, report.peak_byte_count == 32, "report should record the allocation peak")
	testing.expect(t, report.bad_free_count == 0, "a valid allocation should not record a bad free")

	free_err := mem.free(raw_data(allocation), allocator=persistent_allocator)
	testing.expect(t, free_err == .None, "freeing a tracked allocation should succeed")

	report = fo.memory_context_allocation_report(&memory_context)
	testing.expect(t, report.live_allocation_count == 0, "free should remove the live allocation")
	testing.expect(t, report.live_byte_count == 0, "free should return live bytes to zero")
	testing.expect(t, report.peak_byte_count == 32, "free should preserve the allocation peak")
	testing.expect(t, report.bad_free_count == 0, "valid frees should not record a bad free")

	deinit_report := fo.memory_context_deinit(&memory_context)
	testing.expect(t, deinit_report.live_allocation_count == 0, "deinit should report no live allocations")
	testing.expect(t, !memory_context.is_initialized, "deinit should invalidate the memory context")
}

@(test)
memory_context_reports_bad_free_and_can_reinitialize :: proc(t: ^testing.T) {
	frame_storage := [256]byte{}
	memory_context: fo.Memory_Context
	err := fo.memory_context_init(
		&memory_context,
		context.allocator,
		context.allocator,
		frame_storage[:],
	)
	testing.expect(t, err.kind == .None, "memory context initialization should succeed")
	if err.kind != .None {
		return
	}

	persistent_allocator := fo.memory_context_persistent_allocator(&memory_context)
	allocation, alloc_err := mem.alloc_bytes(16, allocator=persistent_allocator)
	testing.expect(t, alloc_err == .None && allocation != nil, "persistent allocation should succeed")
	if allocation == nil {
		fo.memory_context_deinit(&memory_context)
		return
	}

	free_err := mem.free(raw_data(allocation), allocator=persistent_allocator)
	testing.expect(t, free_err == .None, "the first free should succeed")
	free_err = mem.free(raw_data(allocation), allocator=persistent_allocator)
	testing.expect(t, free_err == .None, "tracking allocator should report bad frees without freeing again")

	report := fo.memory_context_allocation_report(&memory_context)
	testing.expect(t, report.live_allocation_count == 0, "a bad free must not create a live allocation")
	testing.expect(t, report.bad_free_count == 1, "a repeated free should be recorded")

	deinit_report := fo.memory_context_deinit(&memory_context)
	testing.expect(t, deinit_report.bad_free_count == 1, "deinit should preserve the bad-free report")
	testing.expect(t, !memory_context.is_initialized, "deinit should invalidate the memory context")

	reinit_err := fo.memory_context_init(
		&memory_context,
		context.allocator,
		context.allocator,
		frame_storage[:],
	)
	testing.expect(t, reinit_err.kind == .None, "a deinitialized context should be reusable")
	if reinit_err.kind == .None {
		reinit_report := fo.memory_context_deinit(&memory_context)
		testing.expect(t, reinit_report.live_allocation_count == 0, "reinitialized context should start empty")
	}
}
