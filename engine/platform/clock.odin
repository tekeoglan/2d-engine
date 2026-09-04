package platform

import fo "../foundation"

// Clock_Now_Proc reads elapsed seconds from an adapter-owned clock value.
// The data pointer is borrowed and remains valid for the adapter's lifetime.
Clock_Now_Proc :: proc(data: rawptr) -> f64

// Clock_Adapter is the narrow clock seam consumed by the later runtime.
// Implementations must not expose wall-clock calendar time through this
// interface.
Clock_Adapter :: struct {
	now_proc: Clock_Now_Proc,
	data:     rawptr,
}

// System_Clock stores the state needed by a monotonic production timer. The
// platform implementation chooses the supported OS/SDL counter source.
System_Clock :: struct {
	start_ticks:  u64,
	frequency_hz: u64,
	is_initialized: bool,
}

// Deterministic_Clock advances only through deterministic_clock_advance.
// Tests can therefore reproduce timestamps without sleeping or consulting the
// host clock.
Deterministic_Clock :: struct {
	current_seconds: f64,
	is_initialized:  bool,
}

// system_clock_init captures the starting point and frequency of a monotonic
// production timer.
//
// Preconditions: clock points to stable, zeroed storage and is not initialized.
// Postconditions: on success, system_clock_now can return elapsed seconds.
// Ownership/lifetime: clock owns only its copied counter values.
// Failure: unavailable timer facilities return Platform errors.
// Thread: main engine thread in 0.1; not internally synchronized.
// Research: `SDL3 performance counter frequency monotonic timer`.
system_clock_init :: proc(clock: ^System_Clock) -> fo.Engine_Error {
	panic("TODO(milestone 2): initialize monotonic system clock")
}

// system_clock_now returns elapsed seconds since system_clock_init.
//
// Preconditions: clock is initialized.
// Postconditions: clock is unchanged and returned time is nondecreasing for a
// functioning monotonic counter.
// Ownership/lifetime: no allocation occurs.
// Failure: an invalid clock is a programmer error.
// Thread: main engine thread in 0.1; not internally synchronized.
// Research: `monotonic elapsed time no wall clock adjustments`.
system_clock_now :: proc(clock: ^System_Clock) -> f64 {
	panic("TODO(milestone 2): read monotonic clock")
}

// deterministic_clock_init prepares a clock at an explicit timestamp.
//
// Preconditions: clock is zeroed/uninitialized and initial_seconds is finite
// under the chosen numeric policy.
// Postconditions: deterministic_clock_now returns initial_seconds until an
// explicit advance changes it.
// Ownership/lifetime: values are copied; no allocation occurs.
// Failure: invalid initial time returns Invalid_Argument.
// Thread: safe only on the owning test thread.
// Research: `deterministic fake clock explicit time advancement`.
deterministic_clock_init :: proc(
	clock: ^Deterministic_Clock,
	initial_seconds: f64,
) -> fo.Engine_Error {
	panic("TODO(milestone 2): initialize deterministic clock")
}

// deterministic_clock_now returns the current explicitly controlled timestamp.
//
// Preconditions: clock is initialized.
// Postconditions: clock is unchanged.
// Ownership/lifetime: returned scalar is copied; no allocation occurs.
// Failure: an invalid clock is a programmer error.
// Thread: safe only on the owning test thread.
// Research: `fake clock now deterministic test seam`.
deterministic_clock_now :: proc(clock: ^Deterministic_Clock) -> f64 {
	panic("TODO(milestone 2): read deterministic clock")
}

// deterministic_clock_advance moves the test clock forward by an explicit
// nonnegative amount.
//
// Preconditions: clock is initialized and seconds is finite and nonnegative.
// Postconditions: on success, now equals its prior value plus seconds.
// Ownership/lifetime: no allocation occurs.
// Failure: invalid or negative advances return Invalid_Argument.
// Thread: safe only on the owning test thread.
// Research: `deterministic clock reject negative time travel`.
deterministic_clock_advance :: proc(
	clock: ^Deterministic_Clock,
	seconds: f64,
) -> fo.Engine_Error {
	panic("TODO(milestone 2): advance deterministic clock")
}

// system_clock_adapter exposes a production clock through the common clock
// seam. The returned adapter borrows clock and becomes invalid when clock is
// deinitialized or moved.
//
// Preconditions: clock is initialized and remains at a stable address.
// Postconditions: returned adapter reads the same clock.
// Ownership/lifetime: adapter owns no clock state.
// Failure: none.
// Thread: main engine thread in 0.1; not internally synchronized.
// Research: `function pointer adapter borrowed context lifetime`.
system_clock_adapter :: proc(clock: ^System_Clock) -> Clock_Adapter {
	panic("TODO(milestone 2): build system clock adapter")
}

// deterministic_clock_adapter exposes a deterministic clock through the common
// clock seam. The returned adapter borrows clock.
//
// Preconditions: clock is initialized and remains at a stable address.
// Postconditions: returned adapter reads the same clock.
// Ownership/lifetime: adapter owns no clock state.
// Failure: none.
// Thread: safe only on the owning test thread.
// Research: `function pointer deterministic clock adapter`.
deterministic_clock_adapter :: proc(clock: ^Deterministic_Clock) -> Clock_Adapter {
	panic("TODO(milestone 2): build deterministic clock adapter")
}

// clock_adapter_now reads any valid clock adapter.
//
// Preconditions: adapter and its borrowed data are initialized and stable.
// Postconditions: adapter state is unchanged.
// Ownership/lifetime: no allocation occurs.
// Failure: an invalid adapter is a programmer error.
// Thread: follows the selected adapter's thread contract.
// Research: `Odin procedure pointer callback data rawptr`.
clock_adapter_now :: proc(adapter: ^Clock_Adapter) -> f64 {
	panic("TODO(milestone 2): dispatch clock adapter")
}
