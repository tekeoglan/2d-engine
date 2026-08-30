# Architecture

## Architectural shape

The engine is a modular monolith: one compiled library divided into cohesive
packages. A module hides substantial behavior behind a small interface. A seam
exists only when behavior actually varies and at least two adapters are useful.

The dependency direction is strict:

```text
foundation -> subsystem modules -> runtime composition -> game
```

Imports may point left, never right. Circular package imports are forbidden.

## Planned package map

Only `foundation` exists in milestone 1. Other paths are created when their
milestone begins.

```text
engine/
  foundation/   value types, errors, memory policy, generational identifiers
  platform/     SDL3 Linux adapter; no game rules
  input/        raw state and action mapping
  rendering/    draw interface, command recording, OpenGL adapter
  assets/       manifest, handles, decoding, resource lifetime
  scenes/       scene stack, entities, transforms
  collision/    shapes, queries, contacts, filtering
  audio/        mixing, streaming, buses, SDL3 adapter
  text/         UTF-8 decoding, glyph caching, layout
  ui/           immediate-mode game interface
  animation/    clips, playback, events, state machines
  tilemap/      orthogonal map data, queries, visible-range calculation
  runtime/      composition root and engine-owned lifecycle
games/
  pong/         Pong rules and data; depends on engine modules
  top_down/     second reference game
tests/
  <module>/     tests through the same interfaces used by callers
```

## Real seams and adapters

The initial real seams are:

| Seam | Production adapter | Test adapter | Reason |
| --- | --- | --- | --- |
| Clock | SDL monotonic clock | deterministic clock | fixed-loop tests |
| Input | SDL devices | scripted input | deterministic game tests |
| Rendering | OpenGL 3.3 | command recorder | headless verification |
| File access | native filesystem | in-memory files | asset tests |

Do not add an interface merely because a dependency could hypothetically be
replaced. One adapter is a hypothetical seam; two adapters make it real.

## Engine-owned lifecycle

The runtime owns configure, initialize, fixed update, render, and shutdown.
Game callbacks receive only the context they require. Games never call SDL3,
OpenGL, or the native audio device directly.

Scene transitions and resource destruction are queued and performed at safe
points. This prevents a collection from changing while a procedure iterates it.

## Context and globals

An `Engine_Context` will eventually own subsystem state. Dependencies are
passed explicitly; there are no mutable engine globals. A procedure should not
receive the whole engine context when a narrower module reference is enough.

## Coordinates and time

- World space: positive X right, positive Y up.
- Screen/UI space: positive X right, positive Y down, origin at top-left.
- World units are independent of physical pixels.
- Internal angles use radians.
- Game simulation advances at a fixed 60 updates per second.
- Rendering may run at a different rate.

## Entity and resource identity

Entities and resources use an index plus generation. Reusing an index increments
its generation, allowing lookup to reject stale identifiers. A full ECS is not
part of version 0.1; games compose explicit data types.

Assets are owned by their manager, requested through stable handles, cached by
stable manifest name, and reference-counted. The manager reports unexpected live
references at shutdown.

## Interface documentation template

Every public procedure should document:

- Purpose: why callers need it.
- Preconditions: facts required before the call.
- Postconditions: facts guaranteed after success.
- Ownership: who owns each allocation or external resource.
- Lifetime: how long returned pointers, slices, and strings remain valid.
- Failure: expected errors versus programmer assertions.
- Thread: which thread may call it.
- Research: exact phrases useful before implementation.

## Error policy

- Expected failure returns an explicit error value.
- Programmer mistakes trigger development assertions.
- Unrecoverable startup failure is logged and terminates cleanly.
- Logging will support debug, information, warning, and error severity.

## Determinism

Fixed-update logic must not read wall-clock time directly. Randomness must accept
an explicit seed. Given the same initial state and input sequence, a game should
produce the same simulation result within the supported environment.

Cross-machine rollback-grade determinism is not promised by version 0.1.
