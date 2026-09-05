package platform

import fo "../foundation"
import "core:c"
import "core:strings"
import sdl "vendor:sdl3"
import gl "vendor:OpenGL"

PLATFORM_DEFAULT_TITLE :: "2D Engine"
PLATFORM_DEFAULT_SETTINGS_PATH :: "settings.json"
PLATFORM_DEFAULT_WINDOW_WIDTH :: 1280
PLATFORM_DEFAULT_WINDOW_HEIGHT :: 720

platform_error :: proc(message: string) -> fo.Engine_Error {
	return fo.Engine_Error{kind = .Platform, message = message}
}

invalid_platform_handle_error :: proc() -> fo.Engine_Error {
	return fo.Engine_Error{kind = .Invalid_Handle, message = "Platform context is not initialized."}
}

platform_default_window_settings :: proc() -> Window_Settings {
	return Window_Settings{
		width = PLATFORM_DEFAULT_WINDOW_WIDTH,
		height = PLATFORM_DEFAULT_WINDOW_HEIGHT,
		mode = .Windowed,
		vsync_enabled = true,
	}
}

platform_window_mode_is_supported :: proc(mode: Window_Mode) -> bool {
	return mode == .Windowed || mode == .Borderless_Fullscreen
}

platform_context_is_valid :: proc(ctx: ^Platform_Context) -> bool {
	return ctx != nil && ctx.is_initialized && ctx.window_handle != nil && ctx.gl_context_handle != nil
}

platform_window_from_context :: proc(ctx: ^Platform_Context) -> ^sdl.Window {
	return cast(^sdl.Window)ctx.window_handle
}

platform_gl_context_from_context :: proc(ctx: ^Platform_Context) -> sdl.GLContext {
	return cast(sdl.GLContext)ctx.gl_context_handle
}

platform_refresh_window_sizes :: proc(ctx: ^Platform_Context) -> bool {
	window := platform_window_from_context(ctx)
	logical_width, logical_height, drawable_width, drawable_height: c.int
	if !sdl.GetWindowSize(window, &logical_width, &logical_height) {
		return false
	}
	if !sdl.GetWindowSizeInPixels(window, &drawable_width, &drawable_height) {
		return false
	}

	ctx.window_state.logical_size = Window_Size{i32(logical_width), i32(logical_height)}
	ctx.window_state.drawable_size = Window_Size{i32(drawable_width), i32(drawable_height)}
	ctx.window_state.is_high_dpi = logical_width != drawable_width || logical_height != drawable_height ||
		sdl.GetWindowPixelDensity(window) > 1.0
	return true
}

platform_refresh_window_flags :: proc(ctx: ^Platform_Context) {
	window := platform_window_from_context(ctx)
	flags := sdl.GetWindowFlags(window)
	ctx.window_state.is_focused = .INPUT_FOCUS in flags
	ctx.window_state.is_minimized = .MINIMIZED in flags
	ctx.window_state.mode = .FULLSCREEN in flags ? .Borderless_Fullscreen : .Windowed
}

platform_refresh_window_state :: proc(ctx: ^Platform_Context) -> bool {
	if !platform_refresh_window_sizes(ctx) {
		return false
	}
	platform_refresh_window_flags(ctx)
	return true
}

platform_set_event_state :: proc(
	ctx: ^Platform_Context,
	kind: Platform_Event_Kind,
) -> Platform_Event {
	return Platform_Event{kind = kind, state = ctx.window_state}
}

platform_update_high_dpi_state :: proc(ctx: ^Platform_Context) {
	ctx.window_state.is_high_dpi = ctx.window_state.logical_size.width != ctx.window_state.drawable_size.width ||
		ctx.window_state.logical_size.height != ctx.window_state.drawable_size.height
}

platform_translate_sdl_event :: proc(
	ctx: ^Platform_Context,
	event: ^sdl.Event,
	translated: ^Platform_Event,
) -> bool {
	if ctx == nil || event == nil || translated == nil {
		return false
	}

	kind := Platform_Event_Kind.None
	#partial switch event.type {
	case .QUIT:
		kind = .Quit
	case .WINDOW_FOCUS_GAINED:
		ctx.window_state.is_focused = true
		kind = .Focus_Changed
	case .WINDOW_FOCUS_LOST:
		ctx.window_state.is_focused = false
		kind = .Focus_Changed
	case .WINDOW_MINIMIZED:
		ctx.window_state.is_minimized = true
		kind = .Minimized
	case .WINDOW_RESTORED:
		ctx.window_state.is_minimized = false
		kind = .Restored
	case .WINDOW_RESIZED:
		ctx.window_state.logical_size = Window_Size{event.window.data1, event.window.data2}
		if ctx.window_state.mode == .Windowed {
			ctx.windowed_size = ctx.window_state.logical_size
		}
		platform_update_high_dpi_state(ctx)
		kind = .Resized
	case .WINDOW_PIXEL_SIZE_CHANGED:
		ctx.window_state.drawable_size = Window_Size{event.window.data1, event.window.data2}
		platform_update_high_dpi_state(ctx)
		kind = .Resized
	case .WINDOW_ENTER_FULLSCREEN:
		ctx.window_state.mode = .Borderless_Fullscreen
		kind = .Fullscreen_Changed
	case .WINDOW_LEAVE_FULLSCREEN:
		ctx.window_state.mode = .Windowed
		kind = .Fullscreen_Changed
	case .WINDOW_CLOSE_REQUESTED, .WINDOW_DESTROYED:
		kind = .Quit
	case .WINDOW_DISPLAY_SCALE_CHANGED:
		kind = .Resized
	case:
		return false
	}

	translated^ = platform_set_event_state(ctx, kind)
	return true
}

platform_required_gl_functions_are_available :: proc() -> bool {
	return sdl.GL_GetProcAddress("glGetIntegerv") != nil &&
		sdl.GL_GetProcAddress("glGetString") != nil &&
		sdl.GL_GetProcAddress("glClear") != nil &&
		sdl.GL_GetProcAddress("glBindVertexArray") != nil &&
		sdl.GL_GetProcAddress("glGenVertexArrays") != nil
}

platform_gl_loader_is_ready :: proc() -> bool {
	return gl.impl_GetIntegerv != nil &&
		gl.impl_GetString != nil &&
		gl.impl_Clear != nil &&
		gl.impl_ClearColor != nil &&
		gl.impl_Flush != nil &&
		gl.impl_Viewport != nil &&
		gl.impl_BindVertexArray != nil &&
		gl.impl_GenVertexArrays != nil &&
		gl.impl_DeleteVertexArrays != nil &&
		gl.impl_CreateShader != nil &&
		gl.impl_ShaderSource != nil &&
		gl.impl_CompileShader != nil &&
		gl.impl_CreateProgram != nil &&
		gl.impl_AttachShader != nil &&
		gl.impl_LinkProgram != nil &&
		gl.impl_UseProgram != nil &&
		gl.impl_DeleteProgram != nil &&
		gl.impl_DeleteShader != nil &&
		gl.impl_GenBuffers != nil &&
		gl.impl_DeleteBuffers != nil &&
		gl.impl_BindBuffer != nil &&
		gl.impl_BufferData != nil &&
		gl.impl_VertexAttribPointer != nil &&
		gl.impl_EnableVertexAttribArray != nil &&
		gl.impl_DrawArrays != nil
}

platform_event_updates_window_size :: proc(event_type: sdl.EventType) -> bool {
	return event_type == .WINDOW_RESIZED || event_type == .WINDOW_PIXEL_SIZE_CHANGED ||
		event_type == .WINDOW_DISPLAY_SCALE_CHANGED
}

platform_append_event :: proc(events: []Platform_Event, count: ^int, event: Platform_Event) {
	if count^ < len(events) {
		events[count^] = event
		count^ += 1
		return
	}
	if event.kind != .Quit || len(events) == 0 {
		return
	}
	for existing in events[:count^] {
		if existing.kind == .Quit {
			return
		}
	}
	// A caller-provided full buffer cannot hold every event. Preserve Quit by
	// replacing the newest non-quit event so shutdown remains observable.
	events[len(events)-1] = event
}

platform_gl_version_satisfies_request :: proc(major, minor: i32) -> bool {
	return major > OPENGL_REQUESTED_MAJOR || major == OPENGL_REQUESTED_MAJOR && minor >= OPENGL_REQUESTED_MINOR
}

// platform_config_default returns validated first-run configuration.
//
// Preconditions: none.
// Postconditions: the returned configuration contains safe positive window
// dimensions, a supported mode, and normalized volume defaults when converted
// to Display_Settings.
// Ownership/lifetime: returned values are copied and allocate no memory.
// Failure: none.
// Thread: safe before platform initialization.
// Research: `configuration defaults immutable value object`.
platform_config_default :: proc() -> Platform_Config {
	return Platform_Config{
		title = PLATFORM_DEFAULT_TITLE,
		window = platform_default_window_settings(),
		request_high_dpi = true,
		settings_path = PLATFORM_DEFAULT_SETTINGS_PATH,
	}
}

// display_settings_defaults returns the settings used when no settings file
// exists or when the caller deliberately starts from a clean configuration.
//
// Preconditions: none.
// Postconditions: version equals DISPLAY_SETTINGS_VERSION and all values are
// within the validation policy chosen for this milestone.
// Ownership/lifetime: returned values are copied and allocate no memory.
// Failure: none.
// Thread: safe on any thread because no shared state is used.
// Research: `configuration defaults versioned schema`.
display_settings_defaults :: proc() -> Display_Settings {
	return Display_Settings{
		version = DISPLAY_SETTINGS_VERSION,
		window = platform_default_window_settings(),
		volume = Volume_Settings{
			master = 1.0,
			music = 1.0,
			effects = 1.0,
		},
	}
}

// platform_init initializes SDL, creates the window, creates an OpenGL 3.3
// core-profile context, and loads the OpenGL functions.
//
// Preconditions: context points to zeroed, stable storage and is not already
// initialized. config contains validated values and borrowed strings remain
// valid for the duration of this call.
// Postconditions: on success, platform_poll_events, platform_window_state,
// platform_opengl_context_info, platform_swap_buffers, and platform_deinit may
// be called. The context owns all native resources acquired during the call.
// Ownership/lifetime: context must remain at a stable address until deinit;
// native resources are owned by context and are released by deinit.
// Failure: expected SDL, window, context, and loader failures return a
// foundation Engine_Error and clean up every resource acquired so far.
// Thread: main engine thread in 0.1; not internally synchronized.
// Research: `SDL3 OpenGL initialization reverse cleanup order`.
platform_init :: proc(ctx: ^Platform_Context, config: Platform_Config) -> fo.Engine_Error {
	if ctx == nil {
		return fo.Engine_Error{kind = .Invalid_Argument, message = "Platform context cannot be nil."}
	}
	if ctx.is_initialized {
		return fo.Engine_Error{kind = .Invalid_Argument, message = "Platform context is already initialized."}
	}
	if config.window.width <= 0 || config.window.height <= 0 {
		return fo.Engine_Error{kind = .Invalid_Argument, message = "Window dimensions must be positive."}
	}
	if !platform_window_mode_is_supported(config.window.mode) {
		return fo.Engine_Error{kind = .Invalid_Argument, message = "Window mode is not supported."}
	}

	if !sdl.Init(sdl.INIT_VIDEO) {
		return platform_error("SDL video initialization failed.")
	}
	ctx.sdl_is_initialized = true

	sdl.GL_ResetAttributes()
	if !sdl.GL_SetAttribute(sdl.GL_CONTEXT_MAJOR_VERSION, c.int(OPENGL_REQUESTED_MAJOR)) {
		platform_deinit(ctx)
		return platform_error("SDL could not set the OpenGL major version.")
	}
	if !sdl.GL_SetAttribute(sdl.GL_CONTEXT_MINOR_VERSION, c.int(OPENGL_REQUESTED_MINOR)) {
		platform_deinit(ctx)
		return platform_error("SDL could not set the OpenGL minor version.")
	}
	if !sdl.GL_SetAttribute(sdl.GL_CONTEXT_PROFILE_MASK, c.int(sdl.GL_CONTEXT_PROFILE_CORE)) {
		platform_deinit(ctx)
		return platform_error("SDL could not request an OpenGL core profile.")
	}

	window_flags := sdl.WindowFlags{.OPENGL, .RESIZABLE}
	if config.request_high_dpi {
		window_flags += {.HIGH_PIXEL_DENSITY}
	}
	if config.window.mode == .Borderless_Fullscreen {
		window_flags += {.FULLSCREEN}
	}

	title, title_err := strings.clone_to_cstring(config.title, context.temp_allocator)
	if title_err != nil {
		platform_deinit(ctx)
		return fo.Engine_Error{kind = .Out_Of_Memory, message = "Could not prepare the window title."}
	}
	defer delete(title, context.temp_allocator)

	window := sdl.CreateWindow(
		title,
		c.int(config.window.width),
		c.int(config.window.height),
		window_flags,
	)
	if window == nil {
		platform_deinit(ctx)
		return platform_error("SDL window creation failed.")
	}
	ctx.window_handle = rawptr(window)
	ctx.window_id = u32(sdl.GetWindowID(window))
	if ctx.window_id == 0 {
		platform_deinit(ctx)
		return platform_error("SDL could not identify the created window.")
	}
	ctx.windowed_size = Window_Size{config.window.width, config.window.height}

	gl_context := sdl.GL_CreateContext(window)
	if gl_context == nil {
		platform_deinit(ctx)
		return platform_error("OpenGL context creation failed.")
	}
	ctx.gl_context_handle = rawptr(gl_context)

	if !sdl.GL_MakeCurrent(window, gl_context) {
		platform_deinit(ctx)
		return platform_error("OpenGL context could not be made current.")
	}
	if !platform_required_gl_functions_are_available() {
		platform_deinit(ctx)
		return platform_error("Required OpenGL functions are unavailable.")
	}
	gl.load_up_to(int(OPENGL_REQUESTED_MAJOR), int(OPENGL_REQUESTED_MINOR), sdl.gl_set_proc_address)
	if !platform_gl_loader_is_ready() {
		platform_deinit(ctx)
		return platform_error("The OpenGL loader could not load required functions.")
	}

	major, minor, profile: i32
	gl.GetIntegerv(gl.MAJOR_VERSION, &major)
	gl.GetIntegerv(gl.MINOR_VERSION, &minor)
	gl.GetIntegerv(gl.CONTEXT_PROFILE_MASK, &profile)
	if !platform_gl_version_satisfies_request(major, minor) || profile & gl.CONTEXT_CORE_PROFILE_BIT == 0 {
		platform_deinit(ctx)
		return platform_error("The OpenGL context does not satisfy the 3.3 core contract.")
	}

	ctx.gl_info = OpenGL_Context_Info{
		major_version = major,
		minor_version = minor,
		is_core_profile = profile & gl.CONTEXT_CORE_PROFILE_BIT != 0,
		loader_is_ready = true,
	}
	ctx.window_state = Window_State{
		mode = config.window.mode,
		vsync_enabled = config.window.vsync_enabled,
	}
	if !platform_refresh_window_state(ctx) {
		platform_deinit(ctx)
		return platform_error("SDL could not query the initial window state.")
	}
	// SDL may report the initial fullscreen mode asynchronously; the requested
	// mode is authoritative until the first matching window event arrives.
	ctx.window_state.mode = config.window.mode
	ctx.is_initialized = true

	if err := platform_set_vsync(ctx, config.window.vsync_enabled); err.kind != .None {
		platform_deinit(ctx)
		return err
	}

	return fo.NO_ERROR
}

// platform_poll_events drains the native event queue into caller-owned event
// storage and updates the context's current window state.
//
// Preconditions: context is initialized and events has enough capacity for
// the event policy documented by the implementation. The output count is a
// valid pointer.
// Postconditions: at most len(events) translated events are written, the
// returned count is in [0, len(events)], and current window state reflects all
// translated state changes observed during the call.
// Ownership/lifetime: events storage and all values written into it are owned
// by the caller; no event retains a pointer into SDL memory.
// Failure: an invalid context or output pointer is a programmer error;
// backend polling failures return Platform errors if the backend exposes one.
// Thread: main engine thread in 0.1; not internally synchronized.
// Research: `SDL3 event polling bounded output buffer translation`.
platform_poll_events :: proc(
	ctx: ^Platform_Context,
	events: []Platform_Event,
) -> (int, fo.Engine_Error) {
	if !platform_context_is_valid(ctx) {
		return 0, invalid_platform_handle_error()
	}

	count := 0
	window_destroyed := false
	native_event: sdl.Event
	for sdl.PollEvent(&native_event) {
		if native_event.type >= .WINDOW_SHOWN && native_event.type <= .WINDOW_DESTROYED {
			if event_window_id := native_event.window.windowID; u32(event_window_id) != ctx.window_id {
				continue
			}
			if window_destroyed {
				continue
			}
		}
		translated: Platform_Event
		if !platform_translate_sdl_event(ctx, &native_event, &translated) {
			continue
		}
		if platform_event_updates_window_size(native_event.type) && ctx.window_handle != nil {
			// Resize events carry one dimension pair; querying both values keeps
			// the logical/drawable distinction correct for high-DPI displays.
			if !platform_refresh_window_sizes(ctx) {
				return count, platform_error("SDL could not query the resized window state.")
			}
			translated.state = ctx.window_state
		}
		platform_append_event(events, &count, translated)
		if native_event.type == .WINDOW_DESTROYED {
			// SDL documents all resources associated with this window as invalid
			// by the time this event is observed. Keep SDL ownership so deinit can
			// still shut the subsystem down, but never destroy stale handles.
			ctx.window_handle = nil
			ctx.gl_context_handle = nil
			ctx.is_initialized = false
			window_destroyed = true
		}
	}

	return count, fo.NO_ERROR
}

// platform_window_state returns a copy of the latest observed window state.
//
// Preconditions: context is initialized.
// Postconditions: context and its native resources are unchanged.
// Ownership/lifetime: the returned value is copied and owns no memory.
// Failure: an invalid context is a programmer error.
// Thread: main engine thread in 0.1; not internally synchronized.
// Research: `SDL3 window logical size drawable size state snapshot`.
platform_window_state :: proc(ctx: ^Platform_Context) -> Window_State {
	if !platform_context_is_valid(ctx) {
		return Window_State{}
	}
	return ctx.window_state
}

// platform_opengl_context_info returns the actual context and loader status.
//
// Preconditions: context is initialized.
// Postconditions: the returned value is a copy and context is unchanged.
// Ownership/lifetime: no allocation occurs.
// Failure: an invalid context is a programmer error.
// Thread: main engine thread in 0.1; not internally synchronized.
// Research: `OpenGL context version query loader readiness`.
platform_opengl_context_info :: proc(ctx: ^Platform_Context) -> OpenGL_Context_Info {
	if !platform_context_is_valid(ctx) {
		return OpenGL_Context_Info{}
	}
	return ctx.gl_info
}

// platform_set_window_mode applies a requested window mode and updates the
// state used by subsequent callers.
//
// Preconditions: context is initialized and mode is a defined Window_Mode.
// Postconditions: on success, the native window and reported state agree with
// mode; windowed size is preserved when entering borderless fullscreen.
// Ownership/lifetime: no caller ownership changes.
// Failure: backend mode changes return Platform errors and leave the previous
// known-good state intact.
// Thread: main engine thread in 0.1; not internally synchronized.
// Research: `SDL3 borderless fullscreen restore windowed size`.
platform_set_window_mode :: proc(
	ctx: ^Platform_Context,
	mode: Window_Mode,
) -> fo.Engine_Error {
	if !platform_context_is_valid(ctx) {
		return invalid_platform_handle_error()
	}
	if !platform_window_mode_is_supported(mode) {
		return fo.Engine_Error{kind = .Invalid_Argument, message = "Window mode is not supported."}
	}
	if mode == ctx.window_state.mode {
		return fo.NO_ERROR
	}

	window := platform_window_from_context(ctx)
	previous_state := ctx.window_state
	previous_windowed_size := ctx.windowed_size
	if mode == .Borderless_Fullscreen {
		ctx.windowed_size = ctx.window_state.logical_size
		if !sdl.SetWindowFullscreen(window, true) {
			ctx.windowed_size = previous_windowed_size
			return platform_error("SDL could not enter borderless fullscreen.")
		}
		if !sdl.SyncWindow(window) {
			_ = sdl.SetWindowFullscreen(window, false)
			ctx.windowed_size = previous_windowed_size
			return platform_error("SDL could not synchronize fullscreen mode.")
		}
	} else {
		if !sdl.SetWindowFullscreen(window, false) {
			return platform_error("SDL could not leave borderless fullscreen.")
		}
		if !sdl.SyncWindow(window) {
			_ = sdl.SetWindowFullscreen(window, true)
			ctx.window_state = previous_state
			ctx.windowed_size = previous_windowed_size
			return platform_error("SDL could not synchronize the restored window mode.")
		}
		if !sdl.SetWindowSize(window, c.int(ctx.windowed_size.width), c.int(ctx.windowed_size.height)) {
			// Restore the previous mode if the size restoration failed.
			_ = sdl.SetWindowFullscreen(window, true)
			_ = sdl.SyncWindow(window)
			ctx.window_state = previous_state
			ctx.windowed_size = previous_windowed_size
			return platform_error("SDL could not restore the windowed size.")
		}
		if !sdl.SyncWindow(window) {
			_ = sdl.SetWindowFullscreen(window, true)
			_ = sdl.SyncWindow(window)
			ctx.window_state = previous_state
			ctx.windowed_size = previous_windowed_size
			return platform_error("SDL could not synchronize the restored window.")
		}
	}

	ctx.window_state.mode = mode
	if !platform_refresh_window_state(ctx) {
		// Best effort rollback. The context state remains the last known-good
		// snapshot if SDL cannot provide a fresh one.
		_ = sdl.SetWindowFullscreen(window, previous_state.mode == .Borderless_Fullscreen)
		ctx.window_state = previous_state
		ctx.windowed_size = previous_windowed_size
		return platform_error("SDL could not query the changed window state.")
	}
	if ctx.window_state.mode != mode {
		_ = sdl.SetWindowFullscreen(window, previous_state.mode == .Borderless_Fullscreen)
		_ = sdl.SyncWindow(window)
		ctx.window_state = previous_state
		ctx.windowed_size = previous_windowed_size
		return platform_error("SDL did not apply the requested window mode.")
	}
	if mode == .Windowed {
		// Keep the restore target in sync with the actual size accepted by the
		// window manager, which may clamp the requested dimensions.
		ctx.windowed_size = ctx.window_state.logical_size
	}
	return fo.NO_ERROR
}

// platform_set_vsync applies the requested swap interval.
//
// Preconditions: context is initialized and the GL context is current.
// Postconditions: on success, reported VSync state matches the applied request.
// Ownership/lifetime: no allocation occurs.
// Failure: unsupported or rejected swap intervals return Platform errors and
// do not claim that the request was applied.
// Thread: main engine thread in 0.1; not internally synchronized.
// Research: `SDL3 OpenGL swap interval VSync failure handling`.
platform_set_vsync :: proc(ctx: ^Platform_Context, enabled: bool) -> fo.Engine_Error {
	if !platform_context_is_valid(ctx) {
		return invalid_platform_handle_error()
	}
	interval := enabled ? c.int(1) : c.int(0)
	if !sdl.GL_SetSwapInterval(interval) {
		return platform_error("SDL rejected the requested VSync interval.")
	}
	ctx.window_state.vsync_enabled = enabled
	return fo.NO_ERROR
}

// platform_swap_buffers presents the current back buffer.
//
// Preconditions: context is initialized and owns a current OpenGL context.
// Postconditions: the platform has requested presentation of the current
// frame; no game or renderer state is interpreted here.
// Ownership/lifetime: no allocation occurs.
// Failure: presentation failures return Platform errors when observable.
// Thread: main engine thread in 0.1; not internally synchronized.
// Research: `SDL3 OpenGL swap window buffers`.
platform_swap_buffers :: proc(ctx: ^Platform_Context) -> fo.Engine_Error {
	if !platform_context_is_valid(ctx) {
		return invalid_platform_handle_error()
	}
	if !sdl.GL_SwapWindow(platform_window_from_context(ctx)) {
		return platform_error("SDL could not present the OpenGL back buffer.")
	}
	return fo.NO_ERROR
}

// platform_deinit releases the OpenGL context, window, and SDL subsystems in
// reverse ownership order.
//
// Preconditions: context is initialized and no caller will use a borrowed
// platform value after this call.
// Postconditions: context is zeroed/uninitialized and may be initialized again
// only if the implementation preserves that part of the contract.
// Ownership/lifetime: all native resources owned by context are released;
// caller-owned configuration strings and storage are untouched.
// Failure: cleanup is attempted for every owned resource; cleanup diagnostics
// must not skip later cleanup.
// Thread: main engine thread in 0.1; not internally synchronized.
// Research: `SDL3 GL context destroy window destroy SDL quit order`.
platform_deinit :: proc(ctx: ^Platform_Context) {
	if ctx == nil {
		return
	}
	if ctx.gl_context_handle != nil {
		_ = sdl.GL_DestroyContext(platform_gl_context_from_context(ctx))
	}
	if ctx.window_handle != nil {
		sdl.DestroyWindow(platform_window_from_context(ctx))
	}
	if ctx.sdl_is_initialized {
		sdl.Quit()
	}
	ctx^ = Platform_Context{}
}
