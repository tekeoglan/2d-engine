# Decision 0002: Deep Modules and Real Seams

Status: accepted on 2026-08-30.

## Decision

Use a modular monolith with a strict dependency direction. Design deep modules:
small interfaces that hide substantial behavior. Introduce a seam only where
two useful adapters exist.

Initial real seams are clock, input, rendering submission, and file access.
Each has a production adapter and a deterministic or in-memory test adapter.

## Consequences

SDL3 and OpenGL declarations remain local to their adapter modules. Games use
engine-owned value types and handles. Tests exercise the same module interfaces
as real callers rather than reaching through them.

Breaking interface changes are allowed before version 1.0 when recorded as an
architecture decision and updated consistently.
