package engine_runtime

import fo "../foundation"
import ip "../input"
import pl "../platform"

// runtime_config_default returns the first-run pacing policy: the milestone
// fixed rate, the bounded catch-up cap, and an empty action mapping the game
// fills through the input mapping procedures.
//
// Preconditions: none.
// Postconditions: max steps and frame-time cap are positive and safe to pass
// to runtime_init; callbacks are nil until the game assigns them.
// Ownership/lifetime: the returned value is copied and allocates no memory.
// Failure: none.
// Thread: safe before runtime initialization.
// Research: `fixed timestep default pacing policy configuration`.
runtime_config_default :: proc() -> Runtime_Config {
	mapping := ip.Input_Mapping{
		digital_count  = 0,
		analog_count   = 0,
		is_initialized = true,
	}
	return Runtime_Config{
		fixed_update_proc      = nil,
		fixed_update_data      = nil,
		render_proc            = nil,
		render_data            = nil,
		mapping                = mapping,
		max_fixed_steps        = RUNTIME_MAX_FIXED_STEPS_PER_FRAME,
		max_frame_time_seconds = RUNTIME_MAX_FRAME_TIME_SECONDS,
	}
}

// runtime_init composes the outer loop from its borrowed subsystems. The
// platform clock is consumed raw; all clamping lives in this runtime.
//
// Configuration is validated before anything is acquired: callbacks must be
// present, pacing caps must be positive, the clock adapter must carry a
// procedure and borrowed data, input must be initialized, the mapping must
// be initialized, and a non-nil platform handle must be valid. Headless
// deterministic tests pass a nil platform handle to skip window event
// draining; production passes its initialized platform context.
//
// Preconditions: context points to zeroed, stable storage and is not already
// initialized. config carries validated pacing caps and the game callbacks.
// clock, input, and platform_ctx are initialized and remain at stable
// addresses until deinit. Borrowed callback data outlives the context.
// Postconditions: on success, runtime_advance_frame and runtime_deinit may
// be called. The context owns only its accumulator and counters.
// Ownership/lifetime: context must remain at a stable address until deinit;
// subsystem handles stay owned by their callers.
// Failure: invalid handles, missing callbacks, or non-positive pacing caps
// return Invalid_Argument and acquire nothing.
// Thread: main engine thread in 0.1; not internally synchronized.
// Research: `game engine runtime composition root lifecycle init shutdown`.
runtime_init :: proc(
	ctx: ^Runtime_Context,
	config: Runtime_Config,
	clock: ^pl.Clock_Adapter,
	input: ^ip.Input_Context,
	platform_ctx: ^pl.Platform_Context,
) -> fo.Engine_Error {
	if ctx == nil || ctx.is_initialized {
		return fo.Engine_Error{.Invalid_Argument, "Runtime context invalid."}
	}
	if config.fixed_update_proc == nil || config.render_proc == nil {
		return fo.Engine_Error{.Invalid_Argument, "Runtime callbacks must be present."}
	}
	if config.max_fixed_steps <= 0 || config.max_frame_time_seconds <= 0 {
		return fo.Engine_Error{.Invalid_Argument, "Runtime pacing caps must be positive."}
	}
	if clock == nil || clock.now_proc == nil || clock.data == nil {
		return fo.Engine_Error{.Invalid_Argument, "Runtime clock invalid."}
	}
	if input == nil || !input.is_initialized {
		return fo.Engine_Error{.Invalid_Argument, "Runtime input invalid."}
	}
	if !config.mapping.is_initialized {
		return fo.Engine_Error{.Invalid_Argument, "Runtime input mapping invalid."}
	}
	if platform_ctx != nil && !pl.platform_context_is_valid(platform_ctx) {
		return fo.Engine_Error{.Invalid_Argument, "Runtime platform handle invalid."}
	}
	// Consume the raw clock once to anchor elapsed-time measurement.
	// clock_adapter_now asserts on valid adapters; inputs above guarantee it.
	start := pl.clock_adapter_now(clock)
	ctx^ = Runtime_Context{
		fixed_update_proc      = config.fixed_update_proc,
		fixed_update_data      = config.fixed_update_data,
		render_proc            = config.render_proc,
		render_data            = config.render_data,
		mapping                = config.mapping,
		max_fixed_steps        = config.max_fixed_steps,
		max_frame_time_seconds = config.max_frame_time_seconds,
		clock                  = clock^,
		input                  = input,
		platform_ctx           = platform_ctx,
		accumulator_seconds    = 0,
		last_time_seconds      = start,
		frame_count            = 0,
		fixed_update_total     = 0,
		quit_requested         = false,
		is_initialized         = true,
	}
	return fo.NO_ERROR
}

// runtime_deinit releases runtime ownership and marks the context
// uninitialized. Borrowed clock, input, and platform handles stay owned by
// their callers and shut down through their own deinit paths.
//
// Preconditions: context is initialized and no caller will use a borrowed
// runtime value after this call.
// Postconditions: context is zeroed/uninitialized.
// Ownership/lifetime: caller-owned subsystem handles are untouched.
// Failure: cleanup is attempted for every owned value; diagnostics must not
// skip later cleanup.
// Thread: main engine thread in 0.1; not internally synchronized.
// Research: `reverse order cleanup composition root borrowed handles`.
runtime_deinit :: proc(ctx: ^Runtime_Context) {
	assert(ctx != nil && ctx.is_initialized, "Invalid runtime context.")
	ctx^ = Runtime_Context{}
}

// runtime_advance_frame runs exactly one outer-loop frame in the documented
// phase order:
//
//  1. Drain platform events (skipped when the platform handle is nil for
//     headless tests) and forward focus/minimize observations to input.
//  2. Sample input once; every fixed update in this frame shares it.
//  3. Read the raw clock, clamp the frame time, and accumulate.
//  4. Run zero or more fixed updates with FIXED_DT_SECONDS.
//  5. Invoke the render callback exactly once with alpha in [0, 1).
//  6. End the input frame, clearing edges and wheel deltas.
//
// Quit ordering rule: quit is sticky. When quit arrives alongside input,
// resize, or focus events in the same drain, the frame still completes all
// phases above (input sampled, fixed updates run, render invoked once)
// and the result reports quit_requested. The caller then shuts down
// through runtime_deinit; process termination is never used as cleanup.
//
// Spiral-of-death guard: raw frame time is clamped to
// max_frame_time_seconds before accumulation. At most max_fixed_steps run
// per frame; any accumulator remainder at or above one step after the cap
// is dropped so a multi-second hitch causes bounded catch-up, never an
// unbounded burst. Leftover below one step is carried to the next frame.
// Alpha is leftover / FIXED_DT_SECONDS in [0, 1).
//
// Preconditions: context is initialized and remains at a stable address.
// Postconditions: frame and fixed-update counters advance by the work done;
// the render callback ran exactly once; input edges for the frame cleared.
// Ownership/lifetime: no caller ownership changes; snapshots passed to game
// callbacks are borrowed for the callback duration only.
// Failure: an invalid context is a programmer error; backend polling
// failures return Platform errors when the backend exposes them.
// Thread: main engine thread in 0.1; not internally synchronized.
// Research: `fixed timestep game loop accumulator spiral of death`.
runtime_advance_frame :: proc(ctx: ^Runtime_Context) -> (Runtime_Frame_Result, fo.Engine_Error) {
	assert(ctx != nil && ctx.is_initialized, "Invalid runtime context.")

	// Phase 1: drain platform events.
	quit_this_frame := false
	if ctx.platform_ctx != nil {
		events: [RUNTIME_MAX_PLATFORM_EVENTS_PER_FRAME]pl.Platform_Event
		count, poll_err := pl.platform_poll_events(ctx.platform_ctx, events[:])
		if poll_err.kind != .None {
			return Runtime_Frame_Result{}, poll_err
		}
		for i in 0 ..< count {
			event := &events[i]
			#partial switch event.kind {
			case .Quit:
				quit_this_frame = true
			case .Focus_Changed:
				ip.input_notify_focus_changed(ctx.input, event.state.is_focused)
			case .Minimized:
				ip.input_notify_focus_changed(ctx.input, false)
			case .Restored:
				ip.input_notify_focus_changed(ctx.input, true)
			}
		}
	}

	// Phase 2: sample input once for the whole frame.
	ip.input_begin_frame(ctx.input)

	// Phase 3: raw clock with runtime-side clamping only.
	now := pl.clock_adapter_now(&ctx.clock)
	elapsed := now - ctx.last_time_seconds
	ctx.last_time_seconds = now
	if elapsed < 0 {
		elapsed = 0
	}
	if elapsed > ctx.max_frame_time_seconds {
		elapsed = ctx.max_frame_time_seconds
	}
	ctx.accumulator_seconds += elapsed

	// Phase 4: bounded fixed updates sharing one snapshot.
	// A small epsilon keeps exact multiples of FIXED_DT_SECONDS stable
	// against binary floating-point residue (for example, 3*DT minus
	// three DT subtractions leaving +/-1e-18). Steps still derive from
	// the clamped accumulator, never from wall-clock time.
	steps := 0
	snapshot := ip.input_snapshot(ctx.input)
	for ctx.accumulator_seconds + RUNTIME_STEP_EPSILON >= FIXED_DT_SECONDS &&
	    steps < ctx.max_fixed_steps {
		ctx.fixed_update_proc(ctx.fixed_update_data, FIXED_DT_SECONDS, &snapshot)
		ctx.accumulator_seconds -= FIXED_DT_SECONDS
		steps += 1
	}
	// Snap near-zero residue to zero so exact multiples report alpha 0.
	// Genuine fractional leftovers (for example, half a step) are far
	// larger than the epsilon and are preserved for interpolation.
	if ctx.accumulator_seconds < 0 || ctx.accumulator_seconds < RUNTIME_STEP_EPSILON {
		ctx.accumulator_seconds = 0
	}
	if steps == ctx.max_fixed_steps && ctx.accumulator_seconds >= FIXED_DT_SECONDS {
		ctx.accumulator_seconds = 0
	}
	alpha := ctx.accumulator_seconds / FIXED_DT_SECONDS
	if alpha < 0 {
		alpha = 0
	}
	if alpha >= 1 {
		alpha = 0
	}

	// Phase 5: exactly one render observation per frame.
	ctx.render_proc(ctx.render_data, alpha)

	// Phase 6: clear per-frame input edges.
	ip.input_end_frame(ctx.input)

	ctx.frame_count += 1
	ctx.fixed_update_total += u64(steps)
	if quit_this_frame {
		ctx.quit_requested = true
	}
	return Runtime_Frame_Result{
			fixed_updates_run   = steps,
			interpolation_alpha = alpha,
			quit_requested      = ctx.quit_requested,
		},
		fo.NO_ERROR
}

// runtime_frame_count reports how many outer-loop frames have advanced.
// The context is unchanged.
//
// Preconditions: context is initialized.
// Postconditions: context is unchanged.
// Ownership/lifetime: no allocation occurs.
// Failure: an invalid context is a programmer error.
// Thread: main engine thread in 0.1; not internally synchronized.
// Research: `runtime frame counter monotonic diagnostic`.
runtime_frame_count :: proc(ctx: ^Runtime_Context) -> u64 {
	assert(ctx != nil && ctx.is_initialized, "Invalid runtime context.")
	return ctx.frame_count
}

// runtime_fixed_update_total reports how many fixed simulation steps have
// run since initialization. Tests use it to prove pacing without sleeping.
//
// Preconditions: context is initialized.
// Postconditions: context is unchanged.
// Ownership/lifetime: no allocation occurs.
// Failure: an invalid context is a programmer error.
// Thread: main engine thread in 0.1; not internally synchronized.
// Research: `fixed update counter deterministic pacing test`.
runtime_fixed_update_total :: proc(ctx: ^Runtime_Context) -> u64 {
	assert(ctx != nil && ctx.is_initialized, "Invalid runtime context.")
	return ctx.fixed_update_total
}

// runtime_quit_requested reports whether a platform quit event has been
// observed. Callers shut down through runtime_deinit when it reads true.
//
// Preconditions: context is initialized.
// Postconditions: context is unchanged.
// Ownership/lifetime: no allocation occurs.
// Failure: an invalid context is a programmer error.
// Thread: main engine thread in 0.1; not internally synchronized.
// Research: `quit event ordering game loop safe shutdown`.
runtime_quit_requested :: proc(ctx: ^Runtime_Context) -> bool {
	assert(ctx != nil && ctx.is_initialized, "Invalid runtime context.")
	return ctx.quit_requested
}
