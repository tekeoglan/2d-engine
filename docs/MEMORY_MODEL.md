# Memory Model

Memory ownership is part of every module interface, not an implementation
detail to document later.

## Lifetime categories

The initial engine uses three conceptual lifetimes:

| Lifetime | Typical data | Released when |
| --- | --- | --- |
| Frame | temporary formatting, transient draw commands | end of frame |
| Scene | entities and scene-owned gameplay state | scene leaves permanently |
| Engine | subsystem state and long-lived caches | engine shutdown |

An asset has its own reference-counted lifetime. The asset manager owns its
memory and backend resources; callers own handles that must be released.

## Frame arena rule

The frame arena borrows a backing byte buffer. Resetting the arena invalidates
every pointer, slice, and string allocated from it. Storing any of those values
inside scene or engine state is a lifetime error even if it appears to work.

Invariant: no frame allocation is reachable after the frame-reset safe point.

## Persistent allocator rule

Long-lived allocations use an explicitly supplied allocator. The foundation
memory context wraps that allocator with Odin's tracking allocator so shutdown
can report leaks and bad frees.

The engine must not silently rely on `context.allocator` inside deep modules.
Accept the required allocator during initialization and store it where the
module owns allocations.

## Borrowing rule

For every pointer, slice, or string parameter, answer:

1. Does the callee only borrow it during the call?
2. Does the callee retain it after returning?
3. If retained, who guarantees its lifetime?
4. Must the callee clone it into owned storage?

Default rule: parameters are borrowed only for the duration of the call unless
the interface explicitly says otherwise.

## External resources

Memory is not the only owned resource. SDL windows, OpenGL buffers, textures,
shader programs, audio devices, decoder state, and file handles require explicit
destruction. Their owners must release them in reverse initialization order.

## Research before implementation

Search these exact phrases:

- `Odin context allocator explicit allocator parameter`
- `Odin core mem Arena arena_init arena_allocator arena_reset`
- `Odin core mem Tracking_Allocator tracking_allocator_init`
- `arena allocator use after reset dangling pointer`
- `resource acquisition initialization reverse order cleanup`
- `ownership borrowing lifetime game engine memory`

You are ready to implement milestone 1 when you can explain:

- Why a slice does not own its backing memory by itself.
- Why returning an arena-backed slice can be safe or unsafe depending on the
  caller's lifetime.
- Why an allocator stored inside a module must outlive that module.
- Why destroying tracking metadata is different from freeing leaked user data.
- Why external GPU and OS handles need ownership rules even when Odin memory is
  leak-free.
