package input_tests

import "core:testing"

import ip "../../engine/input"

make_snapshot :: proc() -> ip.Raw_Input_Snapshot {
	return ip.Raw_Input_Snapshot{is_focused = true}
}

set_key :: proc(snap: ^ip.Raw_Input_Snapshot, key: ip.Key_Code, state: ip.Button_State) {
	snap.keys[key] = state
}

set_button :: proc(snap: ^ip.Raw_Input_Snapshot, button: ip.Mouse_Button, state: ip.Button_State) {
	snap.mouse_buttons[button] = state
}

DOWN :: ip.Button_State{pressed = true, held = true, released = false}
HELD :: ip.Button_State{pressed = false, held = true, released = false}
UP :: ip.Button_State{pressed = false, held = false, released = true}
REST :: ip.Button_State{}

@(test)
digital_action_combines_multiple_sources_deterministically :: proc(t: ^testing.T) {
	mapping: ip.Input_Mapping
	err := ip.input_mapping_init(&mapping, 1, 0)
	testing.expect(t, err.kind == .None, "mapping init should succeed")
	testing.expect(t, mapping.is_initialized, "mapping should be initialized")

	err = ip.input_mapping_bind_digital(&mapping, 0, ip.Digital_Binding{kind = .Key, key = .Space})
	testing.expect(t, err.kind == .None, "first digital bind should succeed")
	err = ip.input_mapping_bind_digital(
		&mapping,
		0,
		ip.Digital_Binding{kind = .Mouse_Button, mouse_button = .Left},
	)
	testing.expect(t, err.kind == .None, "second digital bind should succeed")

	// Neither source: fully released.
	snap := make_snapshot()
	state := ip.input_digital_state(&mapping, &snap, 0)
	testing.expect(t, state == ip.Digital_Action_State{}, "no source should read released")

	// Key pressed alone drives pressed + held.
	snap = make_snapshot()
	set_key(&snap, .Space, DOWN)
	state = ip.input_digital_state(&mapping, &snap, 0)
	testing.expect(t, state.pressed && state.held && !state.released, "key press should drive action")

	// Second source pressing while the first is held keeps pressed + held.
	snap = make_snapshot()
	set_key(&snap, .Space, HELD)
	set_button(&snap, .Left, DOWN)
	state = ip.input_digital_state(&mapping, &snap, 0)
	testing.expect(t, state.pressed && state.held && !state.released, "second press should re-press action")

	// Releasing one of two held sources leaves the action held with no edge.
	snap = make_snapshot()
	set_key(&snap, .Space, UP)
	set_button(&snap, .Left, HELD)
	state = ip.input_digital_state(&mapping, &snap, 0)
	testing.expect(t, state.held, "one remaining hold should keep action held")
	testing.expect(t, !state.pressed && !state.released, "partial release should report no edge")

	// Releasing the last held source reports exactly one released edge.
	snap = make_snapshot()
	set_key(&snap, .Space, UP)
	set_button(&snap, .Left, UP)
	// Only one released source with none held still reports released once.
	snap2 := make_snapshot()
	set_key(&snap2, .Space, REST)
	set_button(&snap2, .Left, UP)
	state = ip.input_digital_state(&mapping, &snap2, 0)
	testing.expect(t, !state.held && state.released && !state.pressed, "last release should report released")

	// Invalid binds leave the mapping unchanged.
	bad := ip.input_mapping_bind_digital(&mapping, 5, ip.Digital_Binding{kind = .Key, key = .Space})
	testing.expect(t, bad.kind == .Invalid_Argument, "out-of-range action should fail")
	bad = ip.input_mapping_bind_digital(&mapping, 0, ip.Digital_Binding{kind = .None})
	testing.expect(t, bad.kind == .Invalid_Argument, "None source should fail")
}

@(test)
analog_action_combines_key_pair_and_wheel :: proc(t: ^testing.T) {
	mapping: ip.Input_Mapping
	err := ip.input_mapping_init(&mapping, 0, 1)
	testing.expect(t, err.kind == .None, "mapping init should succeed")

	err = ip.input_mapping_bind_analog(
		&mapping,
		0,
		ip.Analog_Binding{kind = .Key_Pair, negative_key = .A, positive_key = .D, scale = 1},
	)
	testing.expect(t, err.kind == .None, "key pair bind should succeed")
	err = ip.input_mapping_bind_analog(
		&mapping,
		0,
		ip.Analog_Binding{kind = .Mouse_Wheel, scale = 0.5},
	)
	testing.expect(t, err.kind == .None, "wheel bind should succeed")

	snap := make_snapshot()
	testing.expect(t, ip.input_analog_value(&mapping, &snap, 0) == 0, "neutral input should read zero")

	// Positive key alone reads +1.
	snap = make_snapshot()
	set_key(&snap, .D, HELD)
	testing.expect(t, ip.input_analog_value(&mapping, &snap, 0) == 1, "positive key should read +1")

	// Negative key alone reads -1.
	snap = make_snapshot()
	set_key(&snap, .A, HELD)
	testing.expect(t, ip.input_analog_value(&mapping, &snap, 0) == -1, "negative key should read -1")

	// Opposed keys cancel to zero before the wheel contributes.
	snap = make_snapshot()
	set_key(&snap, .A, HELD)
	set_key(&snap, .D, HELD)
	testing.expect(t, ip.input_analog_value(&mapping, &snap, 0) == 0, "opposed keys should cancel")

	// Wheel scales and sums, then clamps to [-1, 1].
	snap = make_snapshot()
	set_key(&snap, .D, HELD)
	snap.mouse_wheel_delta = 1.0
	// Keys contribute +1, wheel contributes +0.5, sum +1.5 clamps to +1.
	testing.expect(t, ip.input_analog_value(&mapping, &snap, 0) == 1, "overshoot should clamp to +1")

	snap = make_snapshot()
	set_key(&snap, .A, HELD)
	snap.mouse_wheel_delta = -4.0
	// Keys -1 plus wheel -2.0 clamps to -1.
	testing.expect(t, ip.input_analog_value(&mapping, &snap, 0) == -1, "undershoot should clamp to -1")

	snap = make_snapshot()
	snap.mouse_wheel_delta = 1.0
	testing.expect(t, ip.input_analog_value(&mapping, &snap, 0) == 0.5, "wheel alone should scale")

	// Non-finite scales are rejected and leave the mapping unchanged.
	before := ip.input_analog_value(&mapping, &snap, 0)
	inf_scale := transmute(f32)u32(0x7F800000)
	bad := ip.input_mapping_bind_analog(
		&mapping,
		0,
		ip.Analog_Binding{kind = .Mouse_Wheel, scale = inf_scale},
	)
	testing.expect(t, bad.kind == .Invalid_Argument, "infinite scale should fail")
	testing.expect(
		t,
		ip.input_analog_value(&mapping, &snap, 0) == before,
		"failed bind should leave mapping unchanged",
	)
}

@(test)
rebinding_replaces_documented_combination_result :: proc(t: ^testing.T) {
	mapping: ip.Input_Mapping
	err := ip.input_mapping_init(&mapping, 1, 0)
	testing.expect(t, err.kind == .None, "mapping init should succeed")
	err = ip.input_mapping_bind_digital(&mapping, 0, ip.Digital_Binding{kind = .Key, key = .Space})
	testing.expect(t, err.kind == .None, "bind space should succeed")

	snap := make_snapshot()
	set_key(&snap, .Space, DOWN)
	state := ip.input_digital_state(&mapping, &snap, 0)
	testing.expect(t, state.held, "space should drive action before rebinding")

	// Clearing removes every source while keeping the action count.
	ip.input_mapping_clear(&mapping)
	state = ip.input_digital_state(&mapping, &snap, 0)
	testing.expect(
		t,
		state == ip.Digital_Action_State{},
		"cleared mapping should read released even with device down",
	)

	// Rebinding to a new source predicts the new combination result.
	err = ip.input_mapping_bind_digital(&mapping, 0, ip.Digital_Binding{kind = .Key, key = .Enter})
	testing.expect(t, err.kind == .None, "rebind should succeed")
	state = ip.input_digital_state(&mapping, &snap, 0)
	testing.expect(t, !state.held, "old source should no longer drive action")
	snap2 := make_snapshot()
	set_key(&snap2, .Enter, DOWN)
	state = ip.input_digital_state(&mapping, &snap2, 0)
	testing.expect(t, state.pressed && state.held, "new source should drive action")

	// Storage is fixed-size: filling the per-action list rejects overflow.
	for _ in 0 ..< ip.INPUT_MAX_DIGITAL_BINDINGS_PER_ACTION - 1 {
		_ = ip.input_mapping_bind_digital(
			&mapping,
			0,
			ip.Digital_Binding{kind = .Key, key = .P},
		)
	}
	full := ip.input_mapping_bind_digital(
		&mapping,
		0,
		ip.Digital_Binding{kind = .Key, key = .M},
	)
	testing.expect(t, full.kind == .Invalid_Argument, "overflow bind should fail")
}

@(test)
unbound_actions_read_as_released_and_zero :: proc(t: ^testing.T) {
	mapping: ip.Input_Mapping
	err := ip.input_mapping_init(&mapping, 2, 1)
	testing.expect(t, err.kind == .None, "mapping init should succeed")

	snap := make_snapshot()
	set_key(&snap, .Space, DOWN)
	set_button(&snap, .Left, DOWN)
	snap.mouse_wheel_delta = 5.0

	for action in 0 ..< 2 {
		state := ip.input_digital_state(&mapping, &snap, action)
		testing.expect(
			t,
			state == ip.Digital_Action_State{},
			"unbound digital actions should read released",
		)
	}
	testing.expect(
		t,
		ip.input_analog_value(&mapping, &snap, 0) == 0,
		"unbound analog actions should read zero",
	)

	// Zero-count mappings are valid and simply bind nothing.
	empty: ip.Input_Mapping
	err = ip.input_mapping_init(&empty, 0, 0)
	testing.expect(t, err.kind == .None, "zero counts should be valid")
	bad := ip.input_mapping_init(&mapping, ip.INPUT_MAX_DIGITAL_ACTIONS + 1, 0)
	testing.expect(t, bad.kind == .Invalid_Argument, "oversize counts should fail")
}
