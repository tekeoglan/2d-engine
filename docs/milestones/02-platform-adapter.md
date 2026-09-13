# Milestone 2: Platform Adapter

## Outcome

After this milestone, a small Linux program can start and shut down cleanly,
open a resizable window, receive window
events, and read monotonic time. The rest of the engine sees platform-owned
types and errors rather than SDL handles or event codes. GPU device and
swapchain ownership belongs to the later rendering milestone, which uses
SDL_gpu.

The program should be able to run with a real clock and a deterministic clock
in tests. It should also load and save a versioned display-settings file so a
user's window mode, size, VSync choice, and volume preferences survive a
restart. This milestone does not implement a game loop, action mapping, or
game rendering.

## Scaffold state

The initial scaffold provides platform-facing types, procedure contracts, and
test names in `engine/platform` and `tests/platform`. Procedure and test bodies
are intentionally TODOs. Implement the first registered test and its smallest
supporting slice, then activate the next test as you learn what the seam needs.

## Read first

1. [Project contract](../PROJECT_CONTRACT.md)
2. [Architecture](../ARCHITECTURE.md)
3. [Dependency lock](../DEPENDENCIES.md)
4. [Memory model](../MEMORY_MODEL.md)
5. [Roadmap](../ROADMAP.md)
6. The SDL3 binding comments (including SDL_gpu) available in the pinned Odin
   distribution.

Before writing platform code, run the dependency verifier and resolve any
compiler or native-library mismatch against the lock. Do not copy SDL
declarations into the repository to work around a version mismatch.

## Package boundary

Create `engine/platform`. It may depend on `engine/foundation`, SDL3, and
the standard-library facilities needed for settings
serialization. Callers outside the package must not need to import SDL3.

The adapter owns the window and SDL subsystem
lifecycle. It exposes only engine-facing configuration, state, events, clock
operations, and `Engine_Error` values. It does not decide what an input means,
advance game simulation, issue game draw commands, mix audio, or decode assets.
GPU device and swapchain creation belong to the rendering milestone.

## Implementation order

### Exercise 1 — Dependency and package smoke test

Verify the exact Odin and SDL3 versions from [DEPENDENCIES.md](../DEPENDENCIES.md)
and add the empty platform package with strict-style checking. Confirm the
package can link the SDL3 symbols required by the adapter before adding window
behavior.

Search:

- `Odin vendor SDL3 import linker flags`
- `SDL3 version compatibility headers runtime`
- `Odin package strict style foreign import`

Stop when you can explain which dependency supplies each declaration and which
step supplies the native symbols at link time.

### Exercise 2 — Configuration, state, and ownership

Define the smallest platform-facing configuration and state values needed by
the later runtime. Keep requested configuration separate from observed state:
for example, a requested logical window size is not the same thing as the
current drawable pixel size on a high-DPI display.

Document ownership and lifetime for the platform context, window state, event
values, error messages, and any strings returned from settings. The context
must remain at a stable address while borrowed callbacks or handles refer to
it, just as the foundation memory context does.

Search:

- `opaque platform context resource ownership`
- `SDL3 window logical size pixel density drawable size`
- `borrowed string lifetime configuration snapshot`

Stop when you can draw the ownership graph from the application entry point to
SDL and the window.

### Exercise 3 — SDL lifecycle and resizable window

Initialize only the SDL subsystems this milestone needs, create a resizable
window, and return a platform error for expected startup failures. Every
partially completed initialization path must release the resources it already
owns. Shutdown must happen in reverse dependency order and leave the context
reusable only if the public contract explicitly permits reinitialization.

Support focused, minimized, resized, quit, and borderless-fullscreen state.
Borderless fullscreen means the desktop-sized fullscreen window mode; it is not
an exclusive display-mode switch. Preserve the requested size so leaving that
mode can restore the user's window.

Search:

- `SDL3 SDL_Init SDL_Quit subsystem lifecycle`
- `SDL3 create resizable window fullscreen borderless`
- `SDL3 window event resize focus minimized close`
- `RAII partial initialization reverse order cleanup`

Stop when closing the window through the window manager reaches the caller as a
quit event and every startup failure has a matching cleanup path.

### Exercise 4 — VSync preference and SDL_gpu handoff

Record the requested VSync preference in the platform window state. The
SDL_gpu device, swapchain, and present-mode selection belong to the rendering
milestone, so this milestone stores the preference without creating GPU state.
A later renderer claims the window for its GPU device and applies the stored
preference through the swapchain present mode. A window-creation smoke test is
enough to prove the platform seam; game drawing belongs to milestone 4.

Search:

- `SDL3 GPU device claim window swapchain`
- `SDL_gpu swapchain present mode VSync`
- `SDL_gpu device window ownership lifecycle`

Stop when the smoke test can open a window, record the VSync preference, and
shut down without leaving a live window behind.

### Exercise 5 — Event translation and window state

Pump the SDL event queue once per caller request and translate only platform
concerns into engine events. Include quit, focus changes, minimize/restore,
resize, and fullscreen transitions. Unknown or irrelevant SDL events should be
handled deliberately rather than accidentally leaking through the seam.

Make event translation testable without an SDL window where possible. Define
the ordering rules for multiple resize events and for quit arriving alongside
other events. Keep keyboard, mouse, and controller details for milestone 3.

Search:

- `SDL3 event polling event queue ownership`
- `window resize event logical drawable size high DPI`
- `event translation adapter domain event boundary`
- `quit event ordering game loop`

Stop when a caller can consume a platform event without importing SDL and can
observe the current focus, minimized, fullscreen, logical-size, and drawable-
size state after each relevant event.

### Exercise 6 — Production and deterministic clocks

Add a production clock backed by a monotonic OS timer and a deterministic test
clock that advances only when a test tells it to. Use one documented unit and
numeric representation throughout the seam. The production clock must not
depend on wall-clock calendar changes, and fixed-update code must never read it
directly.

Test zero elapsed time, several advances, and large advances. Decide and
document whether the adapter reports raw elapsed time or clamps it; clamping
belongs to the later runtime accumulator if the platform clock is raw.

Search:

- `monotonic clock vs wall clock game loop`
- `SDL3 performance counter frequency elapsed seconds`
- `deterministic fake clock test adapter`
- `fixed timestep clock ownership`

Stop when a test can reproduce an exact sequence of timestamps without sleeping
and can explain why changing the system clock cannot change elapsed time.

### Exercise 7 — Versioned display settings

Persist user preferences as versioned JSON. At minimum, store window width,
window height, borderless-fullscreen mode, VSync, and the volume preferences
needed by the later audio buses. Keep transient observations such as focus,
minimized state, and actual drawable size out of the file.

Use defaults on a first run. A missing file is a normal condition; malformed,
unreadable, or unsupported-version data must produce an explicit diagnostic and
must not leave partially applied settings. Save only validated values, and make
the settings path injectable or otherwise testable without writing to a real
user profile.

The exact schema is part of the milestone contract. A minimal shape may look
like this, with the field names and volume grouping recorded in the package
documentation:

```json
{
  "version": 1,
  "window": {
    "width": 1280,
    "height": 720,
    "borderless_fullscreen": false,
    "vsync": true
  },
  "volume": {
    "master": 1.0,
    "music": 1.0,
    "effects": 1.0
  }
}
```

Search:

- `versioned JSON settings schema migration`
- `configuration defaults malformed file recovery`
- `atomic JSON settings save replace file`
- `user writable configuration path Linux`

Stop when round-tripping settings preserves values, a missing file creates
defaults, invalid values are rejected or normalized according to a documented
rule, and a future schema version cannot be silently misread.

### Exercise 8 — Tests, integration smoke test, and leak check

Write headless tests for settings defaults and round-tripping, malformed and
unsupported versions, event translation, high-DPI state bookkeeping, and the
deterministic clock. Keep the SDL/window test small and explicit: start
the adapter, observe the initial state, exercise resize/fullscreen/VSync where
the host supports it, and shut it down.

Run the integration smoke test on the supported Linux target with a real
display. If the test environment has no display or cannot provide an SDL_gpu
device,
report that limitation instead of weakening the production contract. Use the
foundation tracking allocator or an equivalent diagnostic to verify that
settings and platform shutdown do not leave owned allocations or native
resources alive.

## Invariants to preserve

- SDL is initialized before any SDL window or event operation and is shut down
  after every SDL-owned resource is destroyed.
- The SDL_gpu device, when created by the rendering milestone, is destroyed
  before SDL shuts down.
- No SDL handle or SDL event code crosses the platform
  seam.
- Logical window size and drawable pixel size remain distinct, especially on a
  high-DPI display.
- Borderless fullscreen and windowed mode preserve enough state to restore the
  previous window size.
- Quit is observable by the caller and does not rely on process termination as
  cleanup.
- Production elapsed time is monotonic; deterministic test time changes only
  through explicit test operations.
- Settings are validated before applying them and are never partially applied.
- Every successful initialization has one matching shutdown path, including
  failures after SDL or window initialization.

## Manual checklist

- The exact locked Odin and SDL3 versions pass the dependency verifier.
- A Linux build opens a resizable window and closes cleanly from the window
  manager.
- Focus loss/regain, minimize/restore, and resize update platform state.
- Borderless fullscreen can be entered and exited without losing the prior
  window size.
- The program reports the logical and drawable sizes separately on a high-DPI
  display.
- VSync preference is recorded and handed to the SDL_gpu swapchain; it is not
  silently ignored.
- A missing settings file uses defaults, a valid file round-trips, and a bad
  file produces a useful diagnostic without corrupting in-memory state.
- The deterministic clock reproduces the same timestamps in repeated tests.
- Shutdown reports no live platform allocations or native resources.
- Foundation checks and all completed tests still pass under strict style
  checking.

## Retrospective template

```text
What I implemented:
Which SDL resource owns which cleanup:
How the window hands off to the SDL_gpu device and swapchain:
What logical size differs from drawable size on my machine:
Which settings failure policy I chose:
How I tested time without sleeping:
What was confusing:
Which invariant caught a bug:
What I would change in the interface:
New research question:
```
