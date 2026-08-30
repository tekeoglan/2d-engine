# Implementation Roadmap

The roadmap uses vertical slices: each group of modules becomes observable in
a small running program before it is deepened. Later details may change as the
working engine teaches us more; the dependency direction may not.

## Milestone 0 — Project setup

Purpose: establish reproducible tools, documentation, license, formatting, and
build conventions.

Deliverables:

- Pin the Odin compiler, SDL3, OpenGL loader/bindings, and decoder versions.
- Record every dependency's purpose, source, version, and license.
- Add one command each for checking, testing, debug building, and release
  packaging.
- Confirm Linux x86-64 as the only supported target for version 0.1.

Research phrases:

- `Odin compiler collections import path`
- `Odin strict style vet flags`
- `pkg-config SDL3 Odin foreign import`
- `reproducible native dependency pinning`

## Milestone 1 — Memory and foundation

Purpose: learn ownership and establish vocabulary used by every later module.

Deliverables:

- Engine constants and error categories.
- 2D math data types and unfinished operations.
- Generational identifiers and unfinished validity operations.
- A persistent tracking allocator plus frame arena interface.
- Headless test skeletons and memory exercises.

This is the current milestone. See
[01-memory-and-foundation.md](milestones/01-memory-and-foundation.md).

## Milestone 2 — Platform adapter

Purpose: create a Linux window, receive OS events, measure time, and own an
OpenGL context without leaking SDL details upward.

Deliverables:

- SDL initialization and shutdown.
- Resizable window, focus, minimize, resize, and quit events.
- Borderless fullscreen, VSync, and high-DPI state.
- Real clock adapter and deterministic test clock adapter.
- OpenGL 3.3 context creation and function loading.

Research phrases:

- `SDL3 initialization subsystem lifecycle`
- `SDL3 OpenGL 3.3 core profile context attributes`
- `SDL3 high DPI drawable size window size difference`
- `monotonic clock vs wall clock game loop`

## Milestone 3 — Runtime and input

Purpose: own the outer loop and turn raw input into game actions.

Deliverables:

- Fixed 60 Hz simulation accumulator.
- Independently paced render callback.
- Pressed, held, and released input states.
- Keyboard, mouse, and controller adapters.
- Configurable digital and analog action mappings.
- Headless deterministic input playback for tests.

Research phrases:

- `fixed timestep game loop accumulator spiral of death`
- `input edge pressed held released frame state`
- `controller deadzone axial radial`

## Milestone 4 — Renderer foundation

Purpose: make GPU work visible while keeping OpenGL behind the rendering seam.

Deliverables:

- Screen clear and colored rectangle drawing.
- Shader compilation diagnostics.
- Vertex array, vertex buffer, and index buffer ownership.
- Configurable logical resolution, integer scaling, and letterboxing.
- Recording render adapter for headless command verification.

Research phrases:

- `OpenGL 3.3 rendering pipeline vertex fragment shader`
- `OpenGL VAO VBO EBO lifetime`
- `pixel perfect integer scaling letterboxing`
- `OpenGL alpha blending premultiplied alpha`

## Milestone 5 — First Pong slice

Purpose: prove the smallest real engine path.

Deliverables:

- Paddle and ball data in `games/pong` rather than the engine.
- Movement through actions and fixed updates.
- Rectangle overlap collision.
- Scoring, restart, and a minimal gameplay scene.
- Manual checks at multiple window sizes.

Pong starts simple and becomes complete as assets, sound, and text arrive.

## Milestone 6 — Asset manager

Purpose: centralize resource ownership and keep files and decoder libraries out
of game code.

Deliverables:

- JSON manifest with stable names and import settings.
- Reference-counted generational asset handles.
- Texture, font, sound, music, shader, and map resource records.
- Native file adapter and in-memory test adapter.
- Leak reporting and explicit unload behavior.

Research phrases:

- `asset registry handle generation reference counting`
- `resource cache ownership lifetime game engine`
- `JSON schema version migration`

## Milestone 7 — Complete 2D rendering

Purpose: supply the rendering features needed by the agreed game scope.

Deliverables:

- Textured sprites, source rectangles, tint, pivot, rotation, and scale.
- Batching with visible draw-call counters.
- Orthographic cameras and world-to-screen conversion.
- Draw layers with deterministic ordering.
- Render targets and custom shader materials with typed parameters.
- Primitive rectangles, circles, lines, and debug drawing.

Research phrases:

- `sprite batching texture atlas draw call`
- `orthographic projection world screen coordinates`
- `framebuffer object render to texture OpenGL 3.3`
- `uniform reflection custom shader material`

## Milestone 8 — Scenes, entities, and transforms

Purpose: organize runtime state without committing to a full ECS.

Deliverables:

- Scene stack and queued transitions.
- Generational entity identifiers.
- Explicit game-owned data composition.
- Local and world transforms with parent-child relationships.
- Dirty propagation and hierarchy cycle rejection.

Research phrases:

- `scene stack push pop replace game states`
- `generational index stale handle`
- `transform hierarchy dirty propagation cycle detection`

## Milestone 9 — Collision

Purpose: provide queries and simple resolution for arcade and top-down games.

Deliverables:

- Axis-aligned rectangles and circles.
- Overlap and sweep queries with contact information.
- Static and game-controlled moving colliders.
- Collision layers and masks.
- Collider and contact debug rendering.

Research phrases:

- `AABB intersection minimum translation vector`
- `swept AABB time of impact`
- `circle AABB closest point collision`
- `collision layer bitmask filtering`

Rigid-body mass, torque, joints, and stacked simulation are excluded from 0.1.

## Milestone 10 — Audio

Purpose: mix engine-owned audio and stream music through SDL3.

Deliverables:

- Multiple simultaneous sound effects.
- Streamed music, pause, resume, stop, loop, and fade.
- Master, music, and effects volume groups.
- Audio-thread communication with explicit ownership and synchronization.

Research phrases:

- `SDL3 audio stream callback mixing float samples`
- `audio buffer underrun ring buffer`
- `linear gain decibels audio volume`

## Milestone 11 — Text and game UI

Purpose: complete Pong menus, score, settings, and pause flow.

Deliverables:

- UTF-8 decoding and TrueType glyph rasterization.
- Glyph atlas caching, multiline layout, wrapping, and alignment.
- Immediate-mode labels, buttons, panels, rows, and columns.
- Mouse interaction plus keyboard/controller focus.

Research phrases:

- `UTF-8 code point decoding replacement character`
- `font glyph metrics baseline advance bearing kerning`
- `dynamic glyph atlas packing`
- `immediate mode GUI hot active focused state`

Complex script shaping and a visual UI editor are excluded from 0.1.

## Milestone 12 — Animation

Purpose: make frame animation data-driven and observable.

Deliverables:

- Named sprite-sheet clips with per-frame duration.
- Loop and one-shot playback, speed control, and frame events.
- Small animation state machines with explicit transitions.

Research phrases:

- `sprite sheet animation accumulator frame duration`
- `animation state machine transition guard`
- `animation event skipped frames large delta time`

## Milestone 13 — Tile maps and top-down game

Purpose: prove the engine beyond Pong.

Deliverables:

- Finite orthogonal JSON tile maps.
- Multiple visual layers and tilesets.
- Tile collision metadata, spawn points, and triggers.
- Camera-based tile culling.
- A small top-down room using actions, animation, collision, audio, text, and UI.

Research phrases:

- `orthogonal tilemap tileset global local tile id`
- `tilemap camera culling visible row column range`
- `tile collision metadata object layer`

## Milestone 14 — Debugging and release

Purpose: make the finished learning version understandable and distributable.

Deliverables:

- Overlay for frame timing, updates, draw calls, sprites, memory, and resources.
- Packed asset archive beside a Linux executable.
- Clean-machine launch checklist and dependency license inventory.
- Architecture review using module depth, leverage, and locality.

## Post-fundamentals track

Only after profiling the completed single-threaded engine:

1. Learn data races, atomics, mutexes, semaphores, and condition variables.
2. Build a bounded job system with deterministic tests.
3. Move one measured workload at a time, such as decoding or broad-phase work.
4. Re-profile after every change.
5. Consider client/server networking only after this phase is stable.
