# Research Guide

Every milestone supplies exact search phrases. Use them as queries, then prefer
sources in this order:

1. Current official documentation for Odin, SDL3, and Khronos OpenGL.
2. Source code and examples shipped with the exact pinned version.
3. Specifications and reference pages.
4. Focused articles that explain one concept and state their assumptions.

Treat tutorials as explanations, not authorities. Many OpenGL tutorials target
deprecated versions, many SDL examples use SDL2 rather than SDL3, and many Odin
examples predate compiler changes.

## Research loop

For each phrase:

1. Write the concept in your own words.
2. Record one invariant or failure mode.
3. Find the exact declaration in the pinned dependency.
4. Build a tiny isolated experiment when documentation is ambiguous.
5. Stop researching once you can predict the experiment's behavior and explain
   why it happens.

## Better query pattern

Combine the concept, exact version, and the uncertainty:

```text
SDL3 OpenGL drawable size vs window size high DPI
Odin dev-2026-08 mem arena reset pointer lifetime
OpenGL 3.3 core framebuffer incomplete status causes
```

Avoid vague queries such as `how make game engine`. Search one mechanism at a
time.

## Research notes template

```text
Concept:
Search phrases:
Authoritative declaration or specification:
Explanation in my own words:
Invariant:
Common failure mode:
Tiny experiment:
What result would prove my understanding:
```
