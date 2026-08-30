# Project Contract

This document records the learning agreement for the repository.

## Division of work

The scaffold may provide:

- Constants and data-type declarations.
- Procedure signatures and nonfunctional TODO bodies.
- Documentation comments describing why declarations exist.
- Preconditions, postconditions, ownership, lifetime, and error contracts.
- Test names and unfinished test bodies.
- Research phrases, diagrams, acceptance criteria, and manual checks.

The scaffold must not provide:

- Working engine algorithms inside procedure bodies.
- Copy-ready pseudocode that solves an exercise.
- Completed test assertions that reveal the implementation.
- Hidden fallback behavior that makes an unfinished feature look functional.

`panic("TODO: ...")` is allowed because it keeps a declaration type-checkable
and makes unfinished work fail loudly.

## Assistance ladder

When you get stuck, ask for help at the least revealing level that can unblock
you:

1. Restate the contract or technical term.
2. Supply better research phrases.
3. Explain the invariant that is probably being violated.
4. Review your attempted implementation and diagnose it.
5. Give a localized algorithm hint.

Working implementation code should be supplied only if you explicitly replace
this project contract later.

## Completion gate

A milestone is complete only when:

- Its packages type-check with strict style enabled.
- Its completed tests pass.
- Its manual demonstration checklist passes.
- Its lifetime exercise and leak check pass.
- No unexplained TODO remains inside that milestone.
- A short retrospective records lessons and architecture changes.

TODOs belonging to future milestones do not block the current milestone.
