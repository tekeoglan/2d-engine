package engine_runtime

import ip "../input"
import pl "../platform"

// FIXED_UPDATE_RATE_HZ is the single simulation rate every game shares.
// Rendering is paced independently and receives an interpolation value.
FIXED_UPDATE_RATE_HZ :: 60

// FIXED_DT_SECONDS is exactly one simulation step: 1/60 second. Fixed
// updates receive this delta and must never read a clock directly.
FIXED_DT_SECONDS :: f64(1.0 / 60.0)

// RUNTIME_MAX_FIXED_STEPS_PER_FRAME caps catch-up work after a hitch so one
// slow frame can never freeze the engine in an unbounded update burst.
RUNTIME_MAX_FIXED_STEPS_PER_FRAME :: 5

// RUNTIME_MAX_FRAME_TIME_SECONDS caps how much raw clock time one runtime
// frame may consume. Larger gaps are carried only up to this bound; the rest
// is dropped under the documented spiral-of-death guard.
RUNTIME_MAX_FRAME_TIME_SECONDS :: f64(0.25)

// RUNTIME_MAX_PLATFORM_EVENTS_PER_FRAME bounds the caller-owned event storage
// the runtime drains from the platform queue each frame. A terminal quit
// event is preserved even when the buffer fills.
RUNTIME_MAX_PLATFORM_EVENTS_PER_FRAME :: 32

// RUNTIME_STEP_EPSILON absorbs binary floating-point residue when exact
// multiples of FIXED_DT_SECONDS are accumulated and subtracted. It is far
// smaller than any real frame-time fraction tests assert, so genuine
// leftovers (for example, half a step) are never snapped away.
RUNTIME_STEP_EPSILON :: f64(1e-9)

// Runtime_Fixed_Update_Proc advances game simulation by one fixed delta.
// snapshot is the shared per-frame input every update in the frame observes;
// data is the borrowed game state supplied during initialization.
Runtime_Fixed_Update_Proc :: proc(data: rawptr, dt: f64, snapshot: ^ip.Raw_Input_Snapshot)

// Runtime_Render_Proc observes the latest simulation state for one rendered
// frame. alpha in [0, 1) is the accumulator leftover expressed as a fraction
// of one fixed step; GPU work behind this seam belongs to milestone 4.
Runtime_Render_Proc :: proc(data: rawptr, alpha: f64)

// Runtime_Config carries the callbacks and pacing policy needed to create
// the runtime context. Callbacks and borrowed data stay owned by the caller.
Runtime_Config :: struct {
	fixed_update_proc:      Runtime_Fixed_Update_Proc,
	fixed_update_data:      rawptr,
	render_proc:            Runtime_Render_Proc,
	render_data:            rawptr,
	mapping:                ip.Input_Mapping,
	max_fixed_steps:        int,
	max_frame_time_seconds: f64,
}

// Runtime_Frame_Result reports what one advanced frame did. quit_requested
// mirrors the platform quit observation so callers shut down through the
// normal deinit path rather than process termination.
Runtime_Frame_Result :: struct {
	fixed_updates_run:    int,
	interpolation_alpha:  f64,
	quit_requested:       bool,
}

// Runtime_Context owns the outer-loop state: pacing accumulator, frame
// counters, game callbacks, and borrowed handles to the clock, input, and
// platform contexts. It never opens devices itself.
Runtime_Context :: struct {
	fixed_update_proc:      Runtime_Fixed_Update_Proc,
	fixed_update_data:      rawptr,
	render_proc:            Runtime_Render_Proc,
	render_data:            rawptr,
	mapping:                ip.Input_Mapping,
	max_fixed_steps:        int,
	max_frame_time_seconds: f64,
	// clock, input, and platform_ctx are borrowed for the context lifetime
	// and must remain at stable addresses until runtime_deinit.
	clock:                  pl.Clock_Adapter,
	input:                  ^ip.Input_Context,
	platform_ctx:           ^pl.Platform_Context,
	accumulator_seconds:    f64,
	last_time_seconds:      f64,
	frame_count:            u64,
	fixed_update_total:     u64,
	quit_requested:         bool,
	is_initialized:         bool,
}
