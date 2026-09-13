package input

import fo "../foundation"

// input_mapping_init prepares a game-owned action configuration with room
// for digital_count digital and analog_count analog actions. Counts of zero
// are valid and simply resolve every query to released or zero.
//
// Preconditions: mapping points to zeroed storage and both counts are within
// [0, INPUT_MAX_DIGITAL_ACTIONS] and [0, INPUT_MAX_ANALOG_ACTIONS].
// Postconditions: on success, bind and query procedures may be called and
// every action starts unbound.
// Ownership/lifetime: mapping must remain valid while queries borrow it; no
// memory is allocated and rebinding never allocates.
// Failure: invalid counts return Invalid_Argument.
// Thread: safe on any thread because no shared state is used.
// Research: `game input action mapping fixed storage no allocation`.
input_mapping_init :: proc(
	mapping: ^Input_Mapping,
	digital_count, analog_count: int,
) -> fo.Engine_Error {
	panic("TODO(milestone 3): initialize action mapping")
}

// input_mapping_clear removes every binding while keeping the configured
// action counts, so a game can rebuild its bindings without reallocating.
//
// Preconditions: mapping is initialized.
// Postconditions: every action is unbound; counts are unchanged.
// Ownership/lifetime: no caller ownership changes.
// Failure: an invalid mapping is a programmer error.
// Thread: safe on any thread because no shared state is used.
// Research: `input rebinding clear bindings retain action set`.
input_mapping_clear :: proc(mapping: ^Input_Mapping) {
	panic("TODO(milestone 3): clear action bindings")
}

// input_mapping_bind_digital attaches one physical source to a digital
// action. Several sources may share one action; their combination follows
// the documented deterministic rule.
//
// Preconditions: mapping is initialized, action is in [0, digital_count),
// and binding selects a real source rather than a None kind.
// Postconditions: on success, the action gains one source; on failure the
// mapping is unchanged.
// Ownership/lifetime: binding is copied; no allocation occurs.
// Failure: out-of-range actions, None sources, and a full per-action binding
// list return Invalid_Argument.
// Thread: safe on any thread because no shared state is used.
// Research: `multiple bindings same action combine rule deterministic`.
input_mapping_bind_digital :: proc(
	mapping: ^Input_Mapping,
	action: int,
	binding: Digital_Binding,
) -> fo.Engine_Error {
	panic("TODO(milestone 3): bind digital action source")
}

// input_mapping_bind_analog attaches one physical source to an analog action
// with an explicit scale.
//
// Preconditions: mapping is initialized, action is in [0, analog_count),
// binding selects a real source, and scale is finite.
// Postconditions: on success, the action gains one source; on failure the
// mapping is unchanged.
// Ownership/lifetime: binding is copied; no allocation occurs.
// Failure: out-of-range actions, None sources, non-finite scales, and a full
// per-action binding list return Invalid_Argument.
// Thread: safe on any thread because no shared state is used.
// Research: `analog action normalization key pair mouse wheel`.
input_mapping_bind_analog :: proc(
	mapping: ^Input_Mapping,
	action: int,
	binding: Analog_Binding,
) -> fo.Engine_Error {
	panic("TODO(milestone 3): bind analog action source")
}

// input_digital_state resolves one mapped action against a snapshot using
// the same single-frame edge policy as raw controls. Unbound actions read as
// fully released.
//
// Preconditions: mapping is initialized and action is in [0, digital_count).
// Postconditions: mapping and snapshot are unchanged.
// Ownership/lifetime: inputs are borrowed; no allocation occurs.
// Failure: an out-of-range action is a programmer error.
// Thread: safe on any thread because no shared state is used.
// Research: `game input action mapping digital pressed held released`.
input_digital_state :: proc(
	mapping: ^Input_Mapping,
	snapshot: ^Raw_Input_Snapshot,
	action: int,
) -> Digital_Action_State {
	panic("TODO(milestone 3): resolve digital action state")
}

// input_analog_value resolves one mapped action against a snapshot to a
// single value in [-1, 1]. Unbound actions read as zero.
//
// Preconditions: mapping is initialized and action is in [0, analog_count).
// Postconditions: mapping and snapshot are unchanged.
// Ownership/lifetime: inputs are borrowed; no allocation occurs.
// Failure: an out-of-range action is a programmer error.
// Thread: safe on any thread because no shared state is used.
// Research: `analog action combine scale clamp deterministic`.
input_analog_value :: proc(
	mapping: ^Input_Mapping,
	snapshot: ^Raw_Input_Snapshot,
	action: int,
) -> f32 {
	panic("TODO(milestone 3): resolve analog action value")
}
