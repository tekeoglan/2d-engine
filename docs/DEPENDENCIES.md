# Dependency Lock

This file records the dependency choices for the agreed roadmap. A dependency
is not used by source code until its milestone begins.

## Toolchain snapshot

| Dependency | Pinned version | Purpose | Source in this setup | License |
| --- | --- | --- | --- | --- |
| Odin | `dev-2026-08-nightly:902106f` | compiler, core library, vendor bindings | managed as mise `dev-2026-08` | BSD 3-Clause |
| SDL3 | `3.4.14` | Linux window, devices, input, and audio access | native library rejected unless the verifier sees this exact version | zlib |
| Odin SDL3 bindings | Odin snapshot; headers report `3.4.2` | typed access to SDL3 | `vendor:sdl3` in pinned Odin | zlib |
| Odin OpenGL loader | Odin snapshot; glad-generated OpenGL 4.6 core declarations | load functions, limited by this engine to OpenGL 3.3 core | `vendor:OpenGL` in pinned Odin | MIT and glad license |
| stb_image | `2.27` from Odin snapshot | decode PNG pixels | `vendor:stb/image` | public domain or MIT |
| stb_truetype | `1.26` from Odin snapshot | rasterize TrueType glyphs | `vendor:stb/truetype` | public domain or MIT |
| stb_vorbis | `1.22` from Odin snapshot | decode OGG Vorbis | `vendor:stb/vorbis` | public domain or MIT |
| SDL_LoadWAV | SDL3 `3.4.14` | decode WAV samples | SDL3 audio interface | zlib |

The SDL binding headers and installed SDL runtime have different patch
versions. Before milestone 2, verify that every SDL declaration used by the
engine exists in both versions. Upgrade the pinned Odin snapshot or use matching
bindings if an incompatibility appears; never copy a declaration ad hoc.

## Reproduction commands

Install the pinned compiler through mise:

```sh
mise install
odin version
```

Verify the exact compiler and native dependency versions:

```sh
./scripts/verify_dependencies.sh
```

The verifier exits unsuccessfully rather than silently accepting a different
system SDL3. Milestone 2 will add distro-specific installation guidance before
any SDL code is introduced. Decoder libraries and the OpenGL loader come from
the pinned Odin distribution, so their snapshot changes only when the compiler
lock changes.

## Build command lifecycle

Commands are introduced only when their target exists:

| Purpose | Command | Available |
| --- | --- | --- |
| Dependency verification | `./scripts/verify_dependencies.sh` | now |
| Strict foundation check | `odin check engine/foundation -no-entry-point -strict-style` | now |
| Foundation test | `odin test tests/foundation -strict-style` | now; deliberately red until its current TODO is filled |
| Debug game build | `odin build games/pong -debug -out:build/pong-debug` | milestone 5 |
| Release game build | `odin build games/pong -o:speed -out:build/pong` | milestone 5 |
| Release package | project packaging command, named with its implementation | milestone 14 |

Do not add a fake command that claims to package a game before a game entry point
and packaging format exist.
