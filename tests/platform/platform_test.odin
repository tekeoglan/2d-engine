package platform_tests

import "core:testing"

import pl "../../engine/platform"

// These tests describe public platform seams. Keep the expected values
// independent from the implementation and activate one tracer bullet at a
// time as each exercise is completed.

@(test)
default_display_settings_are_valid :: proc(t: ^testing.T) {
	panic("TODO(milestone 2 test): choose independent default settings assertions")
}

display_settings_reject_invalid_values :: proc(t: ^testing.T) {
	panic("TODO(milestone 2 test): specify invalid settings and error assertions")
}

display_settings_round_trip_through_file_seam :: proc(t: ^testing.T) {
	panic("TODO(milestone 2 test): build an in-memory file adapter and round-trip settings")
}

malformed_settings_do_not_partially_apply :: proc(t: ^testing.T) {
	panic("TODO(milestone 2 test): specify malformed and unsupported JSON behavior")
}

event_translation_reports_quit_and_window_changes :: proc(t: ^testing.T) {
	panic("TODO(milestone 2 test): specify platform event translation expectations")
}

logical_and_drawable_sizes_remain_distinct :: proc(t: ^testing.T) {
	panic("TODO(milestone 2 test): specify a high-DPI state snapshot")
}

platform_opengl_context_reports_loader_state :: proc(t: ^testing.T) {
	panic("TODO(milestone 2 test): add the Linux OpenGL context smoke-test assertions")
}

platform_shutdown_releases_owned_resources :: proc(t: ^testing.T) {
	panic("TODO(milestone 2 test): add the integration lifecycle and leak assertions")
}

// Keep the import and package vocabulary visible while this file is a
// scaffold; the first test should choose concrete values before using it.
_ :: pl.Display_Settings{}
