package platform

import "core:mem"

import fo "../foundation"

// Settings_Read_Proc reads one complete settings file into allocator-owned
// bytes. The returned bytes belong to the caller and remain valid until freed
// through allocator.
Settings_Read_Proc :: proc(
	data: rawptr,
	path: string,
	allocator: mem.Allocator,
) -> (
	[]byte,
	fo.Engine_Error,
)

// Settings_Write_Proc writes one complete settings file. path and bytes are
// borrowed for the duration of the call.
Settings_Write_Proc :: proc(data: rawptr, path: string, bytes: []byte) -> fo.Engine_Error

// Settings_File_Access is the file seam used by settings serialization. The
// native adapter and an in-memory test adapter implement the same operations.
Settings_File_Access :: struct {
	data:      rawptr,
	read_all:  Settings_Read_Proc,
	write_all: Settings_Write_Proc,
}

// display_settings_validate checks the schema version and all user-provided
// ranges before settings are applied to a platform context.
//
// Preconditions: settings is a value copied from the caller.
// Postconditions: settings is unchanged; success means every field satisfies
// the documented validation policy.
// Ownership/lifetime: no allocation occurs.
// Failure: invalid versions, dimensions, enum values, or volume gains return
// Invalid_Argument.
// Thread: safe on any thread because no shared state is used.
// Research: `configuration validation before applying settings`.
display_settings_validate :: proc(settings: Display_Settings) -> fo.Engine_Error {
	is_version_valid := settings.version == DISPLAY_SETTINGS_VERSION
	has_valid_sized := settings.window.height > 0 && settings.window.width > 0
	if !is_version_valid || !has_valid_sized {
		return {.Invalid_Argument, "Invalid setting arguments."}
	}
	return fo.NO_ERROR
}

// settings_file_access_native returns the production file adapter.
//
// Preconditions: none.
// Postconditions: returned callbacks use the platform's documented
// user-writable settings path behavior.
// Ownership/lifetime: callbacks own no caller data; the adapter value is
// copied by value.
// Failure: filesystem failures are reported when callbacks are invoked.
// Thread: main engine thread in 0.1; not internally synchronized.
// Research: `Linux user configuration file native filesystem adapter`.
settings_file_access_native :: proc() -> Settings_File_Access {
	panic("TODO(milestone 2): build native settings file adapter")
}

// display_settings_load decodes and validates one versioned JSON settings
// file. Missing files use defaults; malformed or unsupported data returns an
// error without partially changing a caller's existing settings.
//
// Preconditions: file_access callbacks are valid; path is borrowed; allocator
// remains valid for the duration of the call.
// Postconditions: on success, returned settings are fully validated. The
// returned byte buffers, if any, are owned by allocator and must be released
// according to the implementation contract.
// Ownership/lifetime: file_access borrows path and owns its own adapter state;
// settings is returned by value.
// Failure: read, parse, version, and validation failures return explicit
// Engine_Error values.
// Thread: main engine thread in 0.1; not internally synchronized.
// Research: `Odin encoding json versioned settings decode allocator`.
display_settings_load :: proc(
	file_access: Settings_File_Access,
	path: string,
	allocator: mem.Allocator,
) -> (
	Display_Settings,
	fo.Engine_Error,
) {
	panic("TODO(milestone 2): load and decode display settings")
}

// display_settings_save validates and serializes settings as versioned JSON.
// A production writer should replace the destination atomically when the
// filesystem supports it.
//
// Preconditions: file_access callbacks are valid and settings is a complete
// value.
// Postconditions: on success, path contains exactly one valid schema version.
// Ownership/lifetime: path and settings are borrowed for the duration of the
// call; temporary serialization memory is released before return.
// Failure: validation, serialization, and write failures return explicit
// Engine_Error values.
// Thread: main engine thread in 0.1; not internally synchronized.
// Research: `atomic JSON settings save replace file`.
display_settings_save :: proc(
	file_access: Settings_File_Access,
	path: string,
	settings: Display_Settings,
) -> fo.Engine_Error {
	panic("TODO(milestone 2): validate and save display settings")
}
