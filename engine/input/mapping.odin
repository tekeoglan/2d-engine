package input

import fo "../foundation"
import "core:math"

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
	if mapping == nil || mapping.is_initialized {
		return fo.Engine_Error{.Invalid_Argument, "Input mapping invalid."}
	}
	if digital_count < 0 ||
	   digital_count > INPUT_MAX_DIGITAL_ACTIONS ||
	   analog_count < 0 ||
	   analog_count > INPUT_MAX_ANALOG_ACTIONS {
		return fo.Engine_Error{.Invalid_Argument, "Input mapping counts out of range."}
	}
	mapping^ = Input_Mapping{
		digital_count = digital_count,
		analog_count  = analog_count,
	}
	mapping.is_initialized = true
	return fo.NO_ERROR
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
	assert(mapping != nil && mapping.is_initialized, "Invalid input mapping.")
	for i in 0 ..< mapping.digital_count {
		mapping.digitals[i] = Digital_Action_Bindings{}
	}
	for i in 0 ..< mapping.analog_count {
		mapping.analogs[i] = Analog_Action_Bindings{}
	}
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
	if mapping == nil || !mapping.is_initialized {
		return fo.Engine_Error{.Invalid_Argument, "Input mapping invalid."}
	}
	if action < 0 || action >= mapping.digital_count {
		return fo.Engine_Error{.Invalid_Argument, "Digital action out of range."}
	}
	#partial switch binding.kind {
	case .Key:
		if binding.key == .Unknown {
			return fo.Engine_Error{.Invalid_Argument, "Digital key binding needs a real key."}
		}
	case .Mouse_Button:
		if binding.mouse_button == .Unknown {
			return fo.Engine_Error{.Invalid_Argument, "Digital mouse binding needs a real button."}
		}
	case:
		return fo.Engine_Error{.Invalid_Argument, "Digital binding needs a real source."}
	}
	slot := &mapping.digitals[action]
	if slot.count >= INPUT_MAX_DIGITAL_BINDINGS_PER_ACTION {
		return fo.Engine_Error{.Invalid_Argument, "Digital action binding list is full."}
	}
	slot.bindings[slot.count] = binding
	slot.count += 1
	return fo.NO_ERROR
}

// input_analog_scale_is_finite reports whether a scale may be stored.
// NaN and infinite scales are rejected so later combination never produces
// a non-finite action value from a finite snapshot.
@(private = "package")
input_analog_scale_is_finite :: proc(scale: f32) -> bool {
	return !math.is_nan(scale) && !math.is_inf(scale)
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
	if mapping == nil || !mapping.is_initialized {
		return fo.Engine_Error{.Invalid_Argument, "Input mapping invalid."}
	}
	if action < 0 || action >= mapping.analog_count {
		return fo.Engine_Error{.Invalid_Argument, "Analog action out of range."}
	}
	#partial switch binding.kind {
	case .Key_Pair:
		if binding.negative_key == .Unknown && binding.positive_key == .Unknown {
			return fo.Engine_Error{.Invalid_Argument, "Analog key pair needs a real key."}
		}
	case .Mouse_Wheel:
		// No key fields are read for wheel bindings.
	case:
		return fo.Engine_Error{.Invalid_Argument, "Analog binding needs a real source."}
	}
	if !input_analog_scale_is_finite(binding.scale) {
		return fo.Engine_Error{.Invalid_Argument, "Analog scale must be finite."}
	}
	slot := &mapping.analogs[action]
	if slot.count >= INPUT_MAX_ANALOG_BINDINGS_PER_ACTION {
		return fo.Engine_Error{.Invalid_Argument, "Analog action binding list is full."}
	}
	slot.bindings[slot.count] = binding
	slot.count += 1
	return fo.NO_ERROR
}

// input_digital_binding_state reads one physical source triple from a
// snapshot. Unknown controls read as fully released so a partially Unknown
// binding can never drive an action.
@(private = "package")
input_digital_binding_state :: proc(
	snapshot: ^Raw_Input_Snapshot,
	binding: Digital_Binding,
) -> Button_State {
	switch binding.kind {
	case .Key:
		if binding.key == .Unknown {
			return Button_State{}
		}
		return snapshot.keys[binding.key]
	case .Mouse_Button:
		if binding.mouse_button == .Unknown {
			return Button_State{}
		}
		return snapshot.mouse_buttons[binding.mouse_button]
	case .None:
		return Button_State{}
	}
	return Button_State{}
}

// input_digital_state resolves one mapped action against a snapshot using
// the same single-frame edge policy as raw controls. Unbound actions read as
// fully released.
//
// Combination rule: held is the OR of every source held; pressed is the OR
// of every source pressed; released holds only when some source released
// and none remains held. Releasing one of two held sources therefore leaves
// the action held with no released edge; releasing the last held source
// reports exactly one released edge.
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
	assert(mapping != nil && mapping.is_initialized, "Invalid input mapping.")
	assert(snapshot != nil, "Invalid input snapshot.")
	assert(action >= 0 && action < mapping.digital_count, "Digital action out of range.")
	slot := &mapping.digitals[action]
	pressed, held, released := false, false, false
	for i in 0 ..< slot.count {
		state := input_digital_binding_state(snapshot, slot.bindings[i])
		pressed = pressed || state.pressed
		held = held || state.held
		released = released || state.released
	}
	if held {
		released = false
	}
	return Digital_Action_State{pressed = pressed, held = held, released = released}
}

// input_analog_binding_value resolves one physical analog source against a
// snapshot before combination. Key pairs yield -1, 0, or +1 times scale;
// wheel yields wheel delta times scale.
@(private = "package")
input_analog_binding_value :: proc(
	snapshot: ^Raw_Input_Snapshot,
	binding: Analog_Binding,
) -> f32 {
	switch binding.kind {
	case .Key_Pair:
		negative_held, positive_held := false, false
		if binding.negative_key != .Unknown {
			negative_held = snapshot.keys[binding.negative_key].held
		}
		if binding.positive_key != .Unknown {
			positive_held = snapshot.keys[binding.positive_key].held
		}
		raw := f32(0)
		if positive_held && !negative_held {
			raw = 1
		} else if negative_held && !positive_held {
			raw = -1
		}
		return raw * binding.scale
	case .Mouse_Wheel:
		return snapshot.mouse_wheel_delta * binding.scale
	case .None:
		return 0
	}
	return 0
}

// input_analog_value resolves one mapped action against a snapshot to a
// single value in [-1, 1]. Unbound actions read as zero.
//
// Combination rule: sum every binding value in binding order, then clamp
// to [-1, 1]. Summation is commutative, so binding order is unobservable
// and conflicting full-deflection inputs saturate deterministically at
// the clamp instead of overshooting.
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
	assert(mapping != nil && mapping.is_initialized, "Invalid input mapping.")
	assert(snapshot != nil, "Invalid input snapshot.")
	assert(action >= 0 && action < mapping.analog_count, "Analog action out of range.")
	slot := &mapping.analogs[action]
	total := f32(0)
	for i in 0 ..< slot.count {
		total += input_analog_binding_value(snapshot, slot.bindings[i])
	}
	return math.clamp(total, -1, 1)
}
