package platform_tests

import "core:testing"

import pl "../../engine/platform"
import sdl "vendor:sdl3"

// These tests describe public platform seams. Keep the expected values
// independent from the implementation and activate one tracer bullet at a
// time as each exercise is completed.

@(test)
default_display_settings_are_valid :: proc(t: ^testing.T) {
	settings := pl.display_settings_defaults()
	testing.expect(
		t,
		settings.version == pl.DISPLAY_SETTINGS_VERSION,
		"display defaults should use the current schema version",
	)
	testing.expect(
		t,
		settings.window.width == 1280,
		"display defaults should use the documented width",
	)
	testing.expect(
		t,
		settings.window.height == 720,
		"display defaults should use the documented height",
	)
	testing.expect(t, settings.window.mode == .Windowed, "display defaults should start windowed")
	testing.expect(t, settings.window.vsync_enabled, "display defaults should enable VSync")
	testing.expect(
		t,
		settings.volume.master == 1.0,
		"display defaults should set master volume to unity",
	)
	testing.expect(
		t,
		settings.volume.music == 1.0,
		"display defaults should set music volume to unity",
	)
	testing.expect(
		t,
		settings.volume.effects == 1.0,
		"display defaults should set effects volume to unity",
	)

	config := pl.platform_config_default()
	testing.expect(t, config.title == "2D Engine", "platform defaults should use the engine title")
	testing.expect(
		t,
		config.window == settings.window,
		"platform and display defaults should agree on window settings",
	)
	testing.expect(
		t,
		config.request_high_dpi,
		"platform defaults should request high-DPI back buffers",
	)
	testing.expect(
		t,
		config.settings_path == "settings.json",
		"platform defaults should provide a settings path",
	)
}

@(test)
platform_init_rejects_invalid_values :: proc(t: ^testing.T) {
	ctx: pl.Platform_Context
	err := pl.platform_init(
		&ctx,
		pl.Platform_Config{window = pl.Window_Settings{width = 0, height = 720}},
	)
	testing.expect(
		t,
		err.kind == .Invalid_Argument,
		"platform initialization should reject invalid dimensions",
	)
	testing.expect(
		t,
		!ctx.is_initialized,
		"invalid platform configuration must not initialize the context",
	)
}

@(test)
event_translation_reports_quit_and_window_changes :: proc(t: ^testing.T) {
	ctx := pl.Platform_Context {
		window_state = pl.Window_State {
			logical_size = pl.Window_Size{1280, 720},
			drawable_size = pl.Window_Size{2560, 1440},
			mode = .Windowed,
			is_high_dpi = true,
		},
	}

	resize := sdl.Event {
		window = sdl.WindowEvent {
			commonEvent = sdl.CommonEvent{type = .WINDOW_RESIZED},
			data1 = 1024,
			data2 = 576,
		},
	}
	translated: pl.Platform_Event
	ok := pl.platform_translate_sdl_event(&ctx, &resize, &translated)
	testing.expect(t, ok, "window resize should translate to a platform event")
	testing.expect(t, translated.kind == .Resized, "window resize should report Resized")
	testing.expect(
		t,
		translated.state.logical_size == pl.Window_Size{1024, 576},
		"resize should update logical size",
	)
	testing.expect(
		t,
		translated.state.drawable_size == pl.Window_Size{2560, 1440},
		"resize should preserve drawable size",
	)

	pixel_resize := sdl.Event {
		window = sdl.WindowEvent {
			commonEvent = sdl.CommonEvent{type = .WINDOW_PIXEL_SIZE_CHANGED},
			data1 = 2048,
			data2 = 1152,
		},
	}
	ok = pl.platform_translate_sdl_event(&ctx, &pixel_resize, &translated)
	testing.expect(t, ok && translated.kind == .Resized, "pixel resize should report Resized")
	testing.expect(
		t,
		translated.state.drawable_size == pl.Window_Size{2048, 1152},
		"pixel resize should update drawable size",
	)
	testing.expect(
		t,
		translated.state.is_high_dpi,
		"different logical and drawable sizes should remain high-DPI",
	)

	pixel_resize = sdl.Event {
		window = sdl.WindowEvent {
			commonEvent = sdl.CommonEvent{type = .WINDOW_PIXEL_SIZE_CHANGED},
			data1 = 1024,
			data2 = 576,
		},
	}
	ok = pl.platform_translate_sdl_event(&ctx, &pixel_resize, &translated)
	testing.expect(
		t,
		ok && !translated.state.is_high_dpi,
		"matching logical and drawable sizes should clear high-DPI state",
	)

	quit := sdl.Event {
		type = .QUIT,
	}
	ok = pl.platform_translate_sdl_event(&ctx, &quit, &translated)
	testing.expect(t, ok && translated.kind == .Quit, "SDL quit should translate to Quit")
}

@(test)
bounded_event_storage_preserves_quit :: proc(t: ^testing.T) {
	events := [1]pl.Platform_Event{}
	count := 0
	pl.platform_append_event(events[:], &count, pl.Platform_Event{kind = .Resized})
	pl.platform_append_event(events[:], &count, pl.Platform_Event{kind = .Quit})
	testing.expect(t, count == 1, "bounded event storage should never exceed its capacity")
	testing.expect(
		t,
		events[0].kind == .Quit,
		"bounded event storage should preserve a terminal Quit event",
	)
}

@(test)
logical_and_drawable_sizes_remain_distinct :: proc(t: ^testing.T) {
	ctx := pl.Platform_Context {
		window_handle = cast(rawptr)uintptr(1),
		is_initialized = true,
		window_state = pl.Window_State {
			logical_size = pl.Window_Size{1280, 720},
			drawable_size = pl.Window_Size{2560, 1440},
			is_high_dpi = true,
		},
	}
	state := pl.platform_window_state(&ctx)
	testing.expect(
		t,
		state.logical_size != state.drawable_size,
		"logical and drawable sizes must be separate values",
	)
	testing.expect(t, state.is_high_dpi, "a larger drawable size should report high-DPI state")
}

@(test)
platform_shutdown_releases_owned_resources :: proc(t: ^testing.T) {
	ctx := pl.Platform_Context {
		is_initialized = true,
	}
	pl.platform_deinit(&ctx)
	testing.expect(t, !ctx.is_initialized, "platform deinit should clear initialized state")
	testing.expect(t, ctx.window_handle == nil, "platform deinit should clear the window handle")
}
