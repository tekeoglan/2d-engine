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
- Format decoders, editors, networking, and multithreading are not part of the
  current platform-adapter milestone.

## Start here

Read these documents in order:

1. [Project contract](docs/PROJECT_CONTRACT.md)
2. [Roadmap](docs/ROADMAP.md)
3. [Architecture](docs/ARCHITECTURE.md)
4. [Dependency lock](docs/DEPENDENCIES.md)
5. [Memory model](docs/MEMORY_MODEL.md)
6. [Glossary](docs/GLOSSARY.md)
7. [Milestone 1](docs/milestones/01-memory-and-foundation.md)
8. [Milestone 2](docs/milestones/02-platform-adapter.md)
9. [Milestone 3](docs/milestones/03-runtime-and-input.md)

## Current milestone

Milestone 0 has scaffolded the repository and locked the current tool/dependency
choices. It remains open until later milestones provide real game-build and
packaging targets. Milestone 1's foundation implementation and active tests are
complete. Milestone 2's SDL3 platform adapter, clocks, window events, and
versioned display settings are complete as described in [its
guide](docs/milestones/02-platform-adapter.md). Milestone 3 is now the working
milestone: own the outer loop and turn raw input into game actions as
described in [its guide](docs/milestones/03-runtime-and-input.md).
Type-check the declarations with:

```sh
odin check engine/foundation -no-entry-point -strict-style
odin check tests/foundation -no-entry-point -strict-style
```

The completed foundation tests should pass. Unregistered TODO skeletons remain
lesson boundaries until their exercise is activated; a failing TODO is not a
compiler problem.

Milestone 2's platform procedures are implemented in `engine/platform` and
covered by the active tests in `tests/platform`. The settings file seam in
 `engine/platform/settings.odin` still carries TODO bodies that the next pass
 should finish or explicitly re-scope before the milestone is treated as fully
 closed.

Check the new declarations with:

```sh
odin check engine/platform -no-entry-point -strict-style
odin check tests/platform -no-entry-point -strict-style
```

Milestone 3 creates `engine/input` and `engine/runtime` with headless tests
in `tests/input` and `tests/runtime`. Check the new declarations with:

```sh
odin check engine/input -no-entry-point -strict-style
odin check engine/runtime -no-entry-point -strict-style
odin check tests/input -no-entry-point -strict-style
odin check tests/runtime -no-entry-point -strict-style
```

## Agreed technical direction

- Language: Odin.
- First platform: Linux x86-64.
- Platform access: SDL3.
- Graphics: SDL_gpu.
- Simulation: fixed 60 Hz updates with independently paced rendering.
- Architecture: modular monolith with one-way package dependencies.
- Initial genre scope: small, single-player arcade and pixel-art games.
- License: MIT, with permissively licensed and pinned dependencies.

There is intentionally no performance target yet. Instrumentation and
profiling will be added before optimization decisions are made.
