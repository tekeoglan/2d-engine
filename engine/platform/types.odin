package platform

// DISPLAY_SETTINGS_VERSION identifies the JSON shape written by this
// milestone. A future incompatible shape must use a new version rather than
// being decoded as if it were this one.
DISPLAY_SETTINGS_VERSION :: u32(1)

// Window_Mode describes the two window modes owned by the platform adapter.
// Borderless_Fullscreen uses the desktop display size; it is not exclusive
// fullscreen.
Window_Mode :: enum {
	Windowed,
	Borderless_Fullscreen,
}

// Window_Size stores a logical window or drawable size in pixels.
Window_Size :: struct {
	width:  i32,
	height: i32,
}

// Window_Settings contains user-requested display values. It intentionally
// does not contain focus, minimized state, or the current drawable size.
Window_Settings :: struct {
	width:         i32,
	height:        i32,
	mode:          Window_Mode,
	vsync_enabled: bool,
}

// Volume_Settings stores preferences for the buses introduced by the audio
// milestone. Values are normalized gains in the inclusive range [0, 1].
Volume_Settings :: struct {
	master:  f32,
	music:   f32,
	effects: f32,
}

// Display_Settings is the versioned, user-persisted settings record.
// Transient platform observations do not belong here.
Display_Settings :: struct {
	version: u32,
	window:  Window_Settings,
	volume:  Volume_Settings,
}

// Platform_Config contains values needed to create the first platform
// context. title and settings_path are borrowed for the duration of the call
// that consumes this configuration unless the implementation documents a
// longer copy.
Platform_Config :: struct {
	title:            string,
	window:           Window_Settings,
	request_high_dpi: bool,
	settings_path:    string,
}

// Window_State contains the latest observed state of the native window.
// logical_size and drawable_size may differ on a high-DPI display.
Window_State :: struct {
	logical_size:  Window_Size,
	drawable_size: Window_Size,
	mode:          Window_Mode,
	vsync_enabled: bool,
	is_focused:    bool,
	is_minimized:  bool,
	is_high_dpi:   bool,
}

// Platform_Event_Kind contains only events that affect platform state. Input
// device events are intentionally deferred to the runtime/input milestone.
Platform_Event_Kind :: enum {
	None,
	Quit,
	Focus_Changed,
	Minimized,
	Restored,
	Resized,
	Fullscreen_Changed,
}

// Platform_Event is a value copied out of the event queue. The state snapshot
// is valid for the value's lifetime and owns no external memory.
Platform_Event :: struct {
	kind:  Platform_Event_Kind,
	state: Window_State,
}

// Platform_Context owns SDL initialization and the native window.
// The raw pointers are opaque
// implementation storage; callers must use platform procedures instead of
// reading or destroying them.
Platform_Context :: struct {
	window_handle:      rawptr,
	window_id:          u32,
	// The last windowed logical size is retained while fullscreen changes the
	// native window's reported size to the desktop size.
	windowed_size:      Window_Size,
	window_state:       Window_State,
	is_sdl_initialized: bool,
	is_initialized:     bool,
}
