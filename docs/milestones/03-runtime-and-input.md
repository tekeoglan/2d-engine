# Milestone 3: Runtime and Input

## Outcome

After this milestone, a small Linux program owns its outer loop: it polls
platform events, samples keyboard, mouse, and controller input once per
rendered frame, advances game simulation at a fixed 60 Hz through an
accumulator, and invokes an independently paced render callback. Game code
consumes named digital and analog actions rather than raw device codes, and
tests reproduce exact input sequences through scripted playback without a
window, without sleeping, and without reading wall-clock time.

This milestone introduces no GPU drawing, no asset loading, no audio, no
scenes, and no game rules. Pong rules belong to milestone 5; rendering
commands belong to milestone 4.

## Scaffold state

The scaffold provides engine-facing types, procedure contracts, and test
names in `engine/input`, `engine/runtime`, `tests/input`, and
`tests/runtime`. Procedure and test bodies are intentionally TODOs.
Implement the first registered test and its smallest supporting slice, then
activate the next test as you learn what the seams need.

## Read first

1. [Project contract](../PROJECT_CONTRACT.md)
2. [Architecture](../ARCHITECTURE.md) — especially engine-owned lifecycle,
   context and globals, coordinates and time, and determinism.
3. [Memory model](../MEMORY_MODEL.md)
4. [Roadmap](../ROADMAP.md) — milestone 3 section.
5. [Milestone 2](02-platform-adapter.md) — platform events, production and
   deterministic clocks, and the settings seam this runtime consumes.
6. The SDL3 keyboard, mouse, and gamepad binding comments in the pinned Odin
   distribution.

Before writing input code, run the dependency verifier and resolve any
compiler or native-library mismatch against the lock. Do not copy SDL
declarations into the repository to work around a version mismatch.

## Package boundary

Create `engine/input` and `engine/runtime` with a strict one-way dependency:

```text
foundation -> platform, input -> runtime -> game
```

- `engine/input` may depend on `engine/foundation`, SDL3, and the
  standard-library containers it needs for bindings. It must not depend on
  `engine/platform` or `engine/runtime`, so scripted tests never need a
  window. Callers outside the package must not need to import SDL3.
- `engine/runtime` may depend on `engine/foundation`, `engine/platform`,
  and `engine/input`. It must not depend on rendering, assets, audio, or
  game packages that do not exist yet.
- The runtime owns configure, initialize, frame advancement, fixed update
  dispatch, render-callback invocation, and shutdown. It decides when input
  is sampled and when simulation runs. It does not decide what an action
  means to a game, issue GPU commands, mix audio, or decode files.
- Game callbacks receive only the narrow state they require (input snapshot,
  fixed delta, render interpolation value), never the whole engine context
  and never SDL handles or event codes.
- The runtime directory is `engine/runtime` but its package clause is
  `engine_runtime`: Odin reserves the `runtime` package name for its core
  runtime.

## Implementation order

### Exercise 1 — Packages, seams, and dependency smoke test

Create the empty `engine/input` and `engine/runtime` packages with
strict-style checking. Prove the dependency direction: input compiles
without platform, runtime compiles against platform and input, and no SDL
symbol or event code is reachable from a caller that imports only engine
packages. Confirm there are no mutable engine globals; every subsystem
state lives in an explicitly initialized context value at a stable address.

Search:

- `Odin package dependency direction modular monolith`
- `opaque context stable address borrowed callback`
- `SDL3 symbol leak adapter boundary`

Stop when you can draw the import graph from the game entry point down to
SDL and point to the exact seam where each SDL type stops.

### Exercise 2 — Raw input state and edge semantics

Define the smallest raw device state the later mapping needs: keyboard keys,
mouse position and buttons plus per-frame wheel delta, and controller
buttons and axes. Define one pressed/held/released policy for the whole
package and document it in the interface:

- Pressed is true for exactly the input frame in which a control
  transitions from up to down.
- Held is true while a control is down, including its pressed frame.
- Released is true for exactly the input frame in which a control
  transitions from down to up.
- One sampled snapshot is shared by every fixed update inside the same
  runtime frame, so all updates in that frame observe identical edges.
- Ending the input frame clears edges and per-frame deltas; holding state
  persists until the matching release is sampled.

Define and document the focus policy: what happens to held state and edges
when the platform reports focus loss or minimize, so a game can never
observe a permanently stuck key or button.

Search:

- `input edge pressed held released frame state`
- `input snapshot shared fixed updates single sample per frame`
- `focus loss clear input stuck keys game`

Stop when you can state, without reading code, what pressed, held, and
released report for a key tapped between two samples, held across three
frames, and released during window focus loss.

### Exercise 3 — SDL keyboard, mouse, and controller adapters

Sample real devices behind the input seam: keyboard state, mouse position
in window logical coordinates with buttons and wheel, and a bounded set of
attached controllers with buttons and axes. Unknown or irrelevant SDL input
events are handled deliberately rather than leaking through the seam.
Controller hot-plug must not invalidate previously sampled state or crash
the caller; document the attach/detach rule and the maximum simultaneously
tracked controller count.

Controllers need an explicit, documented deadzone policy. Record whether
each stick uses an axial or radial deadzone, the normalized input range,
and how sub-threshold values are treated, so later action mapping has a
stable `[-1, 1]` contract to consume.

Search:

- `SDL3 keyboard state scancode keycode difference`
- `SDL3 mouse state window coordinates wheel delta`
- `SDL3 gamepad axis button hot plug count`
- `controller deadzone axial radial`

Stop when a caller can read one key, the mouse position and wheel delta,
and one stick axis without importing SDL, and can explain which deadzone
shape its stick uses and why.

### Exercise 4 — Digital and analog action mappings

Add configurable bindings that turn raw controls into game-facing actions.
Digital actions expose the same pressed/held/released triple as raw
controls. Analog actions expose one `f32` in `[-1, 1]`. Requirements:

- One action may bind several physical sources (for example, a key, a
  mouse button, and a controller button driving one jump action).
- The combination rule is deterministic and documented: which source wins
  or how sources merge when several are active at once.
- Analog bindings document their source (key pair, mouse delta, stick
  axis), scale, and how the controller deadzone from exercise 3 flows
  through without being applied twice.
- Rebinding never allocates during the frame; mapping storage is owned by
  an explicit configuration value with a documented lifetime.

Keep game meaning out of the engine: the package supplies the mapping
mechanism, while games own the action set (move, jump, pause) in a later
milestone.

Search:

- `game input action mapping digital analog bindings`
- `multiple bindings same action combine rule deterministic`
- `analog action normalization stick trigger key pair`

Stop when you can add a second physical source to an existing action,
predict the combined result for every conflicting-input case, and state who
owns the binding storage.

### Exercise 5 — Scripted deterministic input playback

Add a scripted test adapter behind the same input seam as the SDL devices.
A test writes a frame-indexed script of raw controls or actions; the
runtime consumes exactly one script frame per runtime frame and advances
only when the runtime advances. Document the out-of-script policy (hold
last frame versus release everything) and keep it total: a short or empty
script is a normal condition, never a crash.

Fixed-update logic consumes only the snapshot; it must never poll devices,
read the clock, or seed randomness implicitly. Any randomness in later game
code accepts an explicit seed, so the same initial state plus the same
script always produces the same simulation result on the supported target.

Search:

- `deterministic input playback scripted test adapter game`
- `fixed update no wall clock explicit seed determinism`
- `frame indexed input script out of frames policy`

Stop when a test can replay the same script twice, including focus-loss and
controller-detach frames, and observe byte-identical action sequences
without opening a window or sleeping.

### Exercise 6 — Fixed-timestep accumulator and render pacing

Own the outer-loop timing with a 60 Hz accumulator driven by the platform
`Clock_Adapter`, never by a wall calendar clock:

- The fixed delta is exactly `1/60` second. Name it as a constant so tests
  and later games share one definition.
- The platform clock is consumed raw; all clamping lives in the runtime.
  Document the per-frame time cap that prevents the spiral of death and the
  maximum fixed steps allowed per runtime frame.
- Leftover time below one fixed step is carried into the next frame, never
  discarded silently and never allowed to grow without bound.
- Each runtime frame runs zero or more fixed updates followed by exactly
  one render-callback invocation. The callback receives an interpolation
  value in `[0, 1)` derived from the leftover time; the GPU work itself
  belongs to milestone 4, so a call counter is enough to prove pacing.
- Fixed updates receive the fixed delta and the shared input snapshot.
  They never read the clock directly.

Search:

- `fixed timestep game loop accumulator spiral of death`
- `maximum timesteps per frame clamp leftover time`
- `render interpolation alpha fixed update leftover`

Stop when you can predict the update count and interpolation value for
frame times of zero, exactly one step, a fractional step, several steps,
and a pathological multi-second gap, and can explain why the system clock
changing cannot change elapsed time.

### Exercise 7 — Runtime composition and lifecycle

Compose the engine-owned lifecycle: configure, initialize, advance one
frame, invoke fixed-update and render callbacks, handle quit, and shut down
in reverse ownership order. Rules:

- Configuration (fixed rate, input bindings, clock selection, settings
  path) is validated before use; invalid values fail with an explicit
  `Engine_Error` and acquire nothing.
- Platform quit events are observable through the runtime frame result and
  never rely on process termination as cleanup. Quit arriving alongside
  input or resize events follows a documented ordering rule.
- Scene transitions and resource destruction are queued for safe points
  rather than mutating a collection while it is iterated; the queue itself
  may be minimal until the scenes milestone.
- Game callbacks are narrow procedure values with borrowed state. They
  cannot retain frame-arena memory past the frame-reset safe point.
- Every successful initialization has one matching shutdown path,
  including failures after partial SDL, input, or clock initialization.

Search:

- `game engine runtime composition root lifecycle init shutdown`
- `quit event ordering game loop safe shutdown`
- `deferred scene transition queued safe point iteration`

Stop when you can draw the ownership graph from the entry point through the
runtime context to SDL, input state, and the clock, and can state the exact
frame-phase order (platform events, input sample, fixed updates, render
callback, input end, frame reset).

### Exercise 8 — Tests, integration smoke test, and leak check

Write headless tests through the same interfaces real callers use:
pressed/held/released transitions across frames, multi-source action
combination, deadzone boundaries, scripted playback determinism, and
accumulator step counts (zero, one, several, clamped) driven by the
deterministic clock without sleeping. Keep one small integration smoke test
explicit: start the runtime on the supported Linux target, observe fixed
updates advancing while the render callback is paced independently, drive
one action from a real or synthetic device, request quit, and shut down.

Use the foundation tracking allocator or an equivalent diagnostic to verify
that input bindings, runtime shutdown, and settings handling leave no owned
allocations or native resources alive. If the test environment has no
display, report that limitation instead of weakening the production
contract.

## Invariants to preserve

- Imports point left along `foundation -> platform, input -> runtime ->
  game`. No circular package imports; no SDL types cross an engine seam.
- There are no mutable engine globals; subsystem state lives in explicit
  context values at stable addresses.
- Fixed simulation advances at exactly 60 Hz from the accumulator; rendering
  is paced independently and receives an interpolation value in `[0, 1)`.
- The runtime consumes raw time from the `Clock_Adapter`; clamping and the
  per-frame step cap live only in the runtime.
- Fixed-update code never reads wall-clock time and never polls devices
  directly; it consumes the shared per-frame input snapshot.
- Pressed and released are true for exactly one input frame; held includes
  the pressed frame; edges and wheel deltas clear at the frame boundary.
- One input snapshot is shared by all fixed updates in the same runtime
  frame; focus loss applies the documented stuck-input policy.
- Analog values remain in `[-1, 1]` after the single documented deadzone
  and normalization pass.
- Action combination is deterministic for every conflicting-input case.
- The same initial state plus the same scripted input always reproduces the
  same simulation result on the supported target.
- No frame-arena allocation is reachable after the frame-reset safe point.
- Quit is observable by the caller and every successful initialization has
  one matching shutdown path in reverse ownership order.

## Manual checklist

- A Linux build opens a window, runs fixed updates at 60 Hz while the
  render callback is paced independently, and closes cleanly from the
  window manager or a quit action.
- Keyboard, mouse, and at least one controller each visibly drive a bound
  action; unbinding or rebinding one source behaves as documented.
- Tapping, holding, and releasing a control shows the correct
  pressed/held/released triple, including across multi-update frames.
- Focus loss and minimize never leave a stuck pressed or held state.
- Stick rest positions read as zero action; full deflection reads as full
  action; the deadzone transition is smooth under the documented rule.
- Replaying a scripted input sequence twice produces the same simulation
  result without a window and without sleeping.
- A multi-second frame hitch causes a bounded catch-up, never a freeze or
  an unbounded update burst.
- Shutdown reports no live engine allocations or native resources.
- Foundation and platform checks plus all completed tests still pass under
  strict style checking.

## Retrospective template

```text
What I implemented:
Which seam owns which SDL dependency:
How pressed/held/released behave across a multi-update frame:
Which deadzone and combination rules I chose:
How the accumulator caps catch-up and derives interpolation:
How scripted playback proves determinism:
What was confusing:
Which invariant caught a bug:
What I would change in the interface:
New research question:
```
