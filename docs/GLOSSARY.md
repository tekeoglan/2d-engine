# Glossary

Use these terms consistently in code review and documentation.

## Architecture

**Module** — Anything with an interface and implementation, from one procedure
to an entire package.

**Interface** — Everything a caller must know: declarations, invariants,
ordering constraints, ownership, errors, and relevant performance behavior.

**Implementation** — Code hidden inside a module.

**Seam** — A location where behavior can be changed by supplying another
adapter without editing the caller.

**Adapter** — A concrete implementation that occupies a seam, such as an SDL
clock or deterministic test clock.

**Deep module** — A module that gives callers substantial behavior through a
small interface.

**Invariant** — A fact that must always remain true while a data structure is
valid.

**Precondition** — A condition the caller must satisfy before a procedure call.

**Postcondition** — A condition a procedure guarantees after it succeeds.

## Memory

**Allocation** — A reserved region of memory returned by an allocator.

**Allocator** — A value describing how memory is obtained, resized, and freed.

**Ownership** — Responsibility for eventually releasing a resource.

**Borrow** — Temporary permission to use data owned elsewhere, without taking
responsibility for freeing it.

**Lifetime** — The span during which data or a resource remains valid.

**Dangling pointer** — A pointer that still refers to memory after its lifetime
ended.

**Leak** — Owned memory or an external resource that becomes unreachable
without being released.

**Arena** — An allocator that serves allocations from a region and releases
them together. Individual allocations normally cannot be freed independently.

**Frame arena** — An arena reset after a rendered frame. Nothing allocated from
it may be retained for the next frame.

**Persistent allocation** — Memory intended to survive across many frames,
often until a scene, resource, or engine shuts down.

## Runtime

**Frame** — One rendered image. A frame is not necessarily one simulation step.

**Fixed timestep** — Advancing game rules by the same duration on every update.

**Accumulator** — Stored real time not yet consumed by fixed updates.

**Interpolation** — Visually blending between simulation states when rendering
falls between fixed updates.

**Determinism** — Reproducing the same state from the same initial conditions
and inputs.

## Identity and scenes

**Entity** — A stable identifier for a game object. It does not dictate how all
game data must be stored.

**Generation** — A counter changed when an identifier slot is reused.

**Stale identifier** — An old index-generation pair that no longer denotes a
live object.

**Scene** — A coherent runtime state such as a title screen, match, or pause
overlay.

**Scene stack** — An ordered collection in which scenes can be pushed above or
popped from existing scenes.

**Transform** — Position, rotation, and scale.

**Local transform** — A transform relative to a parent.

**World transform** — The derived transform relative to the game world.

## Graphics

**Graphics API** — A vocabulary, such as OpenGL, for submitting work to a GPU.

**Shader** — A program executed by the GPU during rendering.

**Material** — A shader plus textures and typed parameter values.

**Sprite** — A textured two-dimensional image placed in a scene.

**Sprite sheet** — One image containing several sprite or animation regions.

**Batching** — Combining draw data to reduce submissions to the GPU.

**Draw call** — One command that asks the graphics driver to render submitted
geometry with particular state.

**Render target** — A texture or display surface that receives rendered output.

**Orthographic camera** — A camera without perspective shrinking; useful for
two-dimensional worlds.

**Logical resolution** — The coordinate resolution a game renders into before
scaling to the physical window.

**Letterboxing** — Filling unused edges when logical and physical aspect ratios
differ.

## Assets, text, and audio

**Asset** — Data loaded for a game, such as a texture, font, sound, shader, or
map.

**Handle** — An identifier used to access a resource without exposing its raw
pointer or backend representation.

**Manifest** — Human-readable metadata mapping stable asset names to source
files and import settings.

**Decoder** — Code that turns a file format into pixels, glyph outlines, or
audio samples.

**Glyph** — A font's drawn representation of a character or character group.

**Glyph atlas** — A texture caching many rasterized glyph images.

**Text shaping** — Selecting and positioning glyphs according to a writing
system. Complex shaping is postponed beyond version 0.1.

**Mixing** — Combining several audio streams into final device samples.

**Streaming** — Decoding or supplying resource data incrementally instead of
keeping the entire result in memory.

## Collision and threading

**AABB** — Axis-aligned bounding box: a rectangle whose edges remain parallel
to the coordinate axes.

**Sweep test** — A query that checks a shape along a movement path and can
report the earliest contact.

**Layer and mask** — Bit fields describing what a collider is and what it may
interact with.

**Thread** — An independently scheduled sequence of program execution.

**Data race** — Unsynchronized concurrent access where at least one access
writes, making behavior invalid or unpredictable.

**Job system** — A scheduler that distributes small work items to worker
threads. It belongs to the post-fundamentals track.
