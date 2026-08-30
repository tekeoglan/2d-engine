# Milestone 1: Memory and Foundation

## Outcome

After this milestone, you should be able to explain the lifetime of every value
in the foundation module and use its math and identifier types in headless tests.
Nothing in this milestone opens a window or performs rendering.

## Read first

1. [Memory model](../MEMORY_MODEL.md)
2. [Architecture](../ARCHITECTURE.md)
3. The comments in `engine/foundation`.
4. The test names in `tests/foundation`.

## Implementation order

### Exercise 1 — Plain values

Implement vector addition, subtraction, scalar multiplication, dot product, and
length squared. These operations allocate no memory.

Search:

- `2D vector addition scalar multiplication dot product`
- `squared length avoid square root comparison`

Stop when you can draw the operations on graph paper and predict signs for
vectors in every quadrant.

### Exercise 2 — Rectangles and transforms

Implement rectangle containment and overlap using the documented edge policy.
Then implement identity matrices and point transformation.

Search:

- `AABB overlap inclusive exclusive edge policy`
- `2D homogeneous transformation matrix 3x3 column major`
- `translation rotation scale matrix multiplication order`

Stop when you can explain why changing multiplication order changes the result.

### Exercise 3 — Generational identifiers

Implement identifier construction and validity checks. Do not build a slot map
yet; that belongs to the asset/entity milestones.

Search:

- `generational index stale handle slot map`
- `integer sentinel invalid index`

Stop when you can describe an exact stale-reference scenario that a raw array
index would fail to detect.

### Exercise 4 — Frame arena

Implement initialization, allocator access, reset, and deinitialization around
Odin's `mem.Arena`. The wrapper borrows its storage and does not free it.

Search:

- `Odin core mem arena_init arena_allocator arena_free_all`
- `frame arena lifetime use after reset`

Stop when you can state which value owns the backing byte buffer.

### Exercise 5 — Persistent tracking

Implement the memory context around `mem.Tracking_Allocator`. Ensure cleanup
order distinguishes user allocations from the tracker's internal metadata.

Search:

- `Odin mem Tracking_Allocator allocation_map leak report`
- `allocator wrapper backing allocator lifetime`

Stop when you can explain why destroying the tracker does not excuse live user
allocations.

### Exercise 6 — Tests and leak experiment

Only the first tracer-bullet test initially has an `@(test)` attribute. Replace
its TODO with independently chosen examples and assertions, make the smallest
implementation pass, and then add `@(test)` to the next skeleton. Repeat one
red-green slice at a time. Do not activate the entire planned catalog at once.

For the memory slice, write a tiny allocation with the tracked allocator,
verify it appears in the report, free it, then verify the live counts return to
zero.

Do not keep the intentional leak in committed code.

## Edge policies to preserve

- A zero-valued `Generation_Id` is invalid because its generation is zero.
- Generation zero is reserved and never assigned to a live slot.
- Rectangle `min` is inclusive and `max` is exclusive.
- Normalizing a zero-length vector returns an explicit error rather than NaN.
- Frame arena reset invalidates all values allocated from that arena.
- `memory_context_deinit` reports live allocations before destroying tracker
  metadata.

## Manual checklist

- You can explain ownership of the frame backing buffer.
- You can deliberately produce and then remove a tracked leak.
- You can explain why a stale identifier fails validation.
- You can show the difference between world Y-up and screen Y-down coordinates.
- All completed tests pass under strict style checking.

## Retrospective template

```text
What I implemented:
What was confusing:
Which invariant caught a bug:
Which allocation owns which memory:
What I would change in the interface:
New research question:
```
