package input

// INPUT_MAX_DIGITAL_BINDINGS_PER_ACTION bounds how many physical sources may
// drive one digital action. The bound keeps binding storage fixed-size so
// rebinding never allocates during the frame.
INPUT_MAX_DIGITAL_BINDINGS_PER_ACTION :: 4

// INPUT_MAX_ANALOG_BINDINGS_PER_ACTION bounds how many physical sources may
// drive one analog action, for the same fixed-storage reason.
INPUT_MAX_ANALOG_BINDINGS_PER_ACTION :: 4

// INPUT_MAX_DIGITAL_ACTIONS bounds the game-owned digital action set.
// INPUT_MAX_ANALOG_ACTIONS bounds the game-owned analog action set.
INPUT_MAX_DIGITAL_ACTIONS :: 64
INPUT_MAX_ANALOG_ACTIONS :: 32

// Key_Code identifies an engine-facing keyboard control. Values are engine
// vocabulary, never SDL scancodes; translation happens inside this package so
// callers never import SDL.
Key_Code :: enum u16 {
	Unknown,
	A,
	D,
	W,
	S,
	Q,
	E,
	Z,
	X,
	C,
	Left,
	Right,
	Up,
	Down,
	Space,
	Enter,
	Escape,
	Tab,
	Left_Shift,
	P,
	M,
}

// Mouse_Button identifies an engine-facing mouse button.
Mouse_Button :: enum {
	Unknown,
	Left,
	Right,
	Middle,
	Extra_1,
	Extra_2,
}

// Digital_Source_Kind selects which physical control a Digital_Binding reads.
Digital_Source_Kind :: enum {
	None,
	Key,
	Mouse_Button,
}

// Analog_Source_Kind selects which physical control an Analog_Binding reads.
Analog_Source_Kind :: enum {
	None,
	Key_Pair,
	Mouse_Wheel,
}

// Script_End_Policy decides what the scripted test adapter reports after its
// last script frame. Hold_Last_Frame repeats the final frame; Release_All
// reports every control released.
Script_End_Policy :: enum {
	Hold_Last_Frame,
	Release_All,
}

// Button_State carries the pressed/held/released triple for one control.
// Pressed is true for exactly the input frame of an up-to-down transition.
// Held is true while down, including the pressed frame. Released is true for
// exactly the input frame of a down-to-up transition.
Button_State :: struct {
	pressed:  bool,
	held:     bool,
	released: bool,
}

// Mouse_Position stores the cursor in window logical coordinates.
Mouse_Position :: struct {
	x: f32,
	y: f32,
}

// Raw_Input_Snapshot is one sampled input frame shared by every fixed update
// inside the same runtime frame. Values are copied out of device state and
// own no external memory.
Raw_Input_Snapshot :: struct {
	keys:              [Key_Code]Button_State,
	mouse_position:    Mouse_Position,
	mouse_buttons:     [Mouse_Button]Button_State,
	mouse_wheel_delta: f32,
	is_focused:        bool,
}

// Input_Config tunes device sampling without changing its shape.
// clear_on_focus_loss selects the stuck-input policy applied when the
// platform reports focus loss.
Input_Config :: struct {
	clear_on_focus_loss: bool,
}

// Digital_Binding connects one physical control to a digital action. Only
// the fields selected by kind are read.
Digital_Binding :: struct {
	kind:         Digital_Source_Kind,
	key:          Key_Code,
	mouse_button: Mouse_Button,
}

// Digital_Action_Bindings owns every physical source driving one digital
// action. Combination of several active sources follows the documented
// deterministic rule.
Digital_Action_Bindings :: struct {
	bindings: [INPUT_MAX_DIGITAL_BINDINGS_PER_ACTION]Digital_Binding,
	count:    int,
}

// Analog_Binding connects one physical control to an analog action. A key
// pair contributes -1, 0, or +1 before scale.
Analog_Binding :: struct {
	kind:         Analog_Source_Kind,
	negative_key: Key_Code,
	positive_key: Key_Code,
	scale:        f32,
}

// Analog_Action_Bindings owns every physical source driving one analog
// action in the normalized range [-1, 1].
Analog_Action_Bindings :: struct {
	bindings: [INPUT_MAX_ANALOG_BINDINGS_PER_ACTION]Analog_Binding,
	count:    int,
}

// Input_Mapping is the game-owned action configuration. Games own the action
// indices; this package owns the mechanism that reads them. The value is
// fixed-size so rebinding never allocates during the frame.
Input_Mapping :: struct {
	digitals:      [INPUT_MAX_DIGITAL_ACTIONS]Digital_Action_Bindings,
	digital_count: int,
	analogs:       [INPUT_MAX_ANALOG_ACTIONS]Analog_Action_Bindings,
	analog_count:  int,
}

// Digital_Action_State is the resolved pressed/held/released triple for one
// mapped action, using the same single-frame edge policy as Button_State.
Digital_Action_State :: struct {
	pressed:  bool,
	held:     bool,
	released: bool,
}

// Input_Sample_Proc writes one raw device frame into snapshot. The data
// pointer is borrowed and remains valid for the source's lifetime.
Input_Sample_Proc :: proc(data: rawptr, snapshot: ^Raw_Input_Snapshot)

// Input_Source is the narrow input seam consumed by the runtime. The SDL
// keyboard/mouse adapter and scripted playback implement the same operations.
Input_Source :: struct {
	sample_proc: Input_Sample_Proc,
	data:        rawptr,
}

// Scripted_Input is the deterministic test adapter. frames is borrowed for
// the adapter's lifetime; the cursor advances only when the runtime samples.
Scripted_Input :: struct {
	frames:         []Raw_Input_Snapshot,
	cursor:         int,
	end_policy:     Script_End_Policy,
	is_initialized: bool,
}

// Input_Context owns sampled input state. current is the snapshot shared
// with fixed updates; previous is the retained history edges are derived
// from. source selects the SDL keyboard/mouse adapter or scripted playback.
Input_Context :: struct {
	config:         Input_Config,
	current:        Raw_Input_Snapshot,
	previous:       Raw_Input_Snapshot,
	source:         Input_Source,
	is_initialized: bool,
}
