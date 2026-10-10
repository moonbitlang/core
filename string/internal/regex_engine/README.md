# Lazy Tagged Regex Engine

Both `string.Regex` and `string/regex.Regex` compile Unicode patterns to
UTF-16 and use this engine for matching. Their public Regex and MatchResult
methods have the same signatures. The derivative engine has been removed;
the shared AST, character sets and symbol partition remain reusable packages.

## Matching Semantics

Alternatives use ordered First semantics. Greedy repetitions visit the body
before their exit; non-greedy repetitions visit the exit first. Search attempts
are ordered from the earliest input position. The engine supports captures,
bounded and unbounded repetitions, and input, line and word assertions.

Scoped Longest and Shortest preferences are absent from the internal AST.
They were not exposed by the public regex parser or combinators. UTF-16
character-class lowering uses disjoint alternatives, so it does not require
a scoped preference.

## Construction and Execution

Compilation builds an ordered Thompson NFA with explicit capture tags. DFA
states and transitions are constructed only when execution encounters them.
Character classes and assertion categories share the existing symbol partition
implementation. EOF has a separate transition column.

A state contains the previous character category and ordered NFA threads.
Each thread records its NFA node and the register identities of its tags.
Ordered epsilon closure retains the first visit to each node. When it reaches
an accepted candidate, lower-priority threads are discarded; higher-priority
consuming threads remain so greedy continuations can supersede that candidate.

Unbounded nullable repetitions use a consuming continuation that excludes
complete empty iterations. Greedy exits also contain a separate acyclic empty
projection so final empty captures are preserved without epsilon cycles.

Tag histories contain register identities, not input offsets. All tags written
on one transition refer to the same cursor, so they share one register. That
register is chosen from identities unused by the destination's surviving tags.
Existing identities are retained, avoiding runtime COPY programs. Register zero
is a disposable sink for transitions without tag writes.

Cached transitions contain an encoded destination and one register action.
Running destinations are transition-row bases; terminal destinations encode a
state index as `-index - 2`; `-1` is reserved for an uncomputed transition.
Execution refreshes table references after constructing an edge, since edge
construction can grow both tables and the register buffer.

Match results copy endpoints out of the register buffer and subtract the
StringView's backing-string offset. Subsequent executions cannot alter earlier
results. Cache and register storage is mutable; executions on one compiled
regex must remain synchronous.

## Validation

Both public packages run the existing regex tests. Before removal, 217 fixed
and generated patterns were checked against the derivative engine over all
short inputs and search offsets, including capture endpoints, nullable
repetitions, assertions and repeated cache use. Two independent rolling
digests per pattern preserve those verified results as regression baselines.
Unicode lowering on sliced StringViews has a separate historical baseline.
Direct engine tests check lazy cache reuse and large live-register counts.

The compiler's `re"..."` expression creates `string.Regex`, which also uses
this engine. Call `@regex.Regex(...)` to use the other public entry point.
Compiler regex intrinsics remain registered only on `string.Regex`.
