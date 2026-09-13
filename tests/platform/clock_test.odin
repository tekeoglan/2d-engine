package platform_tests

import "core:testing"

import pl "../../engine/platform"

@(test)
deterministic_clock_starts_at_requested_time :: proc(t: ^testing.T) {
	clock: pl.Deterministic_Clock
	err := pl.deterministic_clock_init(&clock, 2.5)
	testing.expect(t, err.kind == .None, "deterministic clock initialization should succeed")
	testing.expect(t, clock.is_initialized, "deterministic clock should be initialized")
	testing.expect(
		t,
		pl.deterministic_clock_now(&clock) == 2.5,
		"deterministic clock should start at the requested time",
	)

	zero: pl.Deterministic_Clock
	err = pl.deterministic_clock_init(&zero, 0)
	testing.expect(t, err.kind == .None, "deterministic clock should accept zero elapsed time")
	testing.expect(
		t,
		pl.deterministic_clock_now(&zero) == 0,
		"deterministic clock starting at zero should read zero",
	)

	negative: pl.Deterministic_Clock
	err = pl.deterministic_clock_init(&negative, -1)
	testing.expect(
		t,
		err.kind == .Invalid_Argument,
		"deterministic clock should reject a negative start time",
	)
	testing.expect(
		t,
		!negative.is_initialized,
		"failed initialization must leave the clock uninitialized",
	)

	err = pl.deterministic_clock_init(&clock, 9)
	testing.expect(
		t,
		err.kind == .Invalid_Argument,
		"reinitializing a clock should be rejected",
	)
	testing.expect(
		t,
		pl.deterministic_clock_now(&clock) == 2.5,
		"failed reinit must not change the current time",
	)
}

@(test)
deterministic_clock_advances_only_when_told :: proc(t: ^testing.T) {
	clock: pl.Deterministic_Clock
	err := pl.deterministic_clock_init(&clock, 1.0)
	testing.expect(t, err.kind == .None, "deterministic clock initialization should succeed")

	testing.expect(
		t,
		pl.deterministic_clock_now(&clock) == 1.0,
		"clock should not advance without an explicit advance",
	)
	testing.expect(
		t,
		pl.deterministic_clock_now(&clock) == pl.deterministic_clock_now(&clock),
		"repeated reads without advance should be stable",
	)

	err = pl.deterministic_clock_advance(&clock, 0.5)
	testing.expect(t, err.kind == .None, "nonnegative advance should succeed")
	testing.expect(
		t,
		pl.deterministic_clock_now(&clock) == 1.5,
		"clock should add the advanced amount",
	)

	err = pl.deterministic_clock_advance(&clock, 0)
	testing.expect(t, err.kind == .None, "zero advance should succeed")
	testing.expect(
		t,
		pl.deterministic_clock_now(&clock) == 1.5,
		"zero advance should leave the timestamp unchanged",
	)

	err = pl.deterministic_clock_advance(&clock, 1.0e6)
	testing.expect(t, err.kind == .None, "large advance should succeed")
	testing.expect(
		t,
		pl.deterministic_clock_now(&clock) == 1000001.5,
		"large advances should accumulate exactly",
	)
}

@(test)
deterministic_clock_rejects_negative_advance :: proc(t: ^testing.T) {
	clock: pl.Deterministic_Clock
	err := pl.deterministic_clock_init(&clock, 5.0)
	testing.expect(t, err.kind == .None, "deterministic clock initialization should succeed")

	err = pl.deterministic_clock_advance(&clock, -1.0)
	testing.expect(
		t,
		err.kind == .Invalid_Argument,
		"negative advance should be rejected",
	)
	testing.expect(
		t,
		pl.deterministic_clock_now(&clock) == 5.0,
		"rejected advance must not change the timestamp",
	)

	uninitialized: pl.Deterministic_Clock
	err = pl.deterministic_clock_advance(&uninitialized, 1.0)
	testing.expect(
		t,
		err.kind == .Invalid_Argument,
		"advance on an uninitialized clock should be rejected",
	)
}

@(test)
clock_adapter_reads_deterministic_clock :: proc(t: ^testing.T) {
	clock: pl.Deterministic_Clock
	err := pl.deterministic_clock_init(&clock, 10.0)
	testing.expect(t, err.kind == .None, "deterministic clock initialization should succeed")

	adapter := pl.deterministic_clock_adapter(&clock)
	testing.expect(t, adapter.now_proc != nil, "adapter should carry a now procedure")
	testing.expect(t, adapter.data != nil, "adapter should borrow the clock storage")
	testing.expect(
		t,
		adapter.data == rawptr(&clock),
		"adapter should borrow the caller's clock without copying",
	)
	testing.expect(
		t,
		pl.clock_adapter_now(&adapter) == 10.0,
		"adapter should read the deterministic timestamp",
	)
	testing.expect(
		t,
		pl.clock_adapter_now(&adapter) == pl.deterministic_clock_now(&clock),
		"adapter and direct reads should agree",
	)

	err = pl.deterministic_clock_advance(&clock, 2.5)
	testing.expect(t, err.kind == .None, "nonnegative advance should succeed")
	testing.expect(
		t,
		pl.clock_adapter_now(&adapter) == 12.5,
		"adapter should observe explicit advances",
	)
}

@(test)
system_clock_is_non_decreasing :: proc(t: ^testing.T) {
	clock: pl.System_Clock
	err := pl.system_clock_init(&clock)
	testing.expect(t, err.kind == .None, "system clock initialization should succeed")
	if err.kind != .None {
		return
	}
	testing.expect(t, clock.is_initialized, "system clock should be initialized")
	testing.expect(t, clock.frequency_hz != 0, "system clock should report a nonzero frequency")

	first := pl.system_clock_now(&clock)
	testing.expect(t, first >= 0, "system clock should report nonnegative elapsed time")

	second := pl.system_clock_now(&clock)
	testing.expect(t, second >= first, "monotonic system clock should never go backwards")

	adapter := pl.system_clock_adapter(&clock)
	adapted := pl.clock_adapter_now(&adapter)
	testing.expect(t, adapted >= 0, "system adapter should report nonnegative elapsed time")
	testing.expect(
		t,
		adapted >= first,
		"system adapter should observe the same monotonic time",
	)
}
