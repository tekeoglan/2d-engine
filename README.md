# Ground-Up 2D Engine in Odin

This repository is a guided engine-development project. You will implement the
engine; the scaffold supplies structure, procedure contracts, research terms,
unfinished tests, and completion criteria.

The first two reference games are:

1. Pong, used to prove the smallest complete path through the runtime.
2. A top-down tile-based room, used to prove assets, cameras, animation, maps,
   UI, and richer collision.

## Non-goals of the scaffold

- Procedure bodies do not contain engine behavior.
- A `panic("TODO: ...")` marks work that belongs to you.
- Future milestone packages are documented but are not generated prematurely.
- SDL3, OpenGL, format decoders, editors, networking, and multithreading are not
  part of milestone 1.

## Start here

Read these documents in order:

1. [Project contract](docs/PROJECT_CONTRACT.md)
2. [Roadmap](docs/ROADMAP.md)
3. [Architecture](docs/ARCHITECTURE.md)
4. [Memory model](docs/MEMORY_MODEL.md)
5. [Glossary](docs/GLOSSARY.md)
6. [Milestone 1](docs/milestones/01-memory-and-foundation.md)

## Current milestone

Milestone 1 defines the foundation module and its unfinished test skeletons.
Type-check the declarations with:

```sh
odin check engine/foundation -no-entry-point -strict-style
odin check tests/foundation -no-entry-point -strict-style
```

The first registered test deliberately panics. Replace its TODO with assertions,
make the smallest implementation pass, and only then register the next test
skeleton. A failing TODO is not a compiler problem; it is the lesson boundary.

## Agreed technical direction

- Language: Odin.
- First platform: Linux x86-64.
- Platform access: SDL3.
- Graphics: OpenGL 3.3.
- Simulation: fixed 60 Hz updates with independently paced rendering.
- Architecture: modular monolith with one-way package dependencies.
- Initial genre scope: small, single-player arcade and pixel-art games.
- License: MIT, with permissively licensed and pinned dependencies.

There is intentionally no performance target yet. Instrumentation and
profiling will be added before optimization decisions are made.
