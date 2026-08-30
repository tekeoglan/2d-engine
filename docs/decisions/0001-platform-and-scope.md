# Decision 0001: Platform and Version 0.1 Scope

Status: accepted on 2026-08-30.

## Decision

Target Linux x86-64 first. Use SDL3 for window, input, and audio-device access;
use OpenGL 3.3 for graphics. Implement engine modules ourselves while using
established format decoders behind engine-owned interfaces.

Version 0.1 targets small, single-player arcade and pixel-art games. Pong and a
top-down tile-based room are the reference games.

## Consequences

The first version excludes a graphical editor, networking, scripting, full
rigid-body physics, complex text shaping, skeletal animation, visual shader
tools, multi-window rendering, and general multithreading.

These exclusions keep the learning path finite. Package seams and explicit
ownership allow later additions without pretending they are already designed.
