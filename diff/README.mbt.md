# Diff

Compute edit scripts between two sequences using the Myers diff algorithm by
default, or patience diff when you pass `algorithm=Patience`.

`Diff` works with any element type that implements `Hash + Eq`. Constructing a
`Diff[T]` bundles the source arrays with the edit script. Call `group` on the
result to split far-apart changes into separate `Hunk[T]` values for
unified-diff-style output.

## Compute A Diff

`Diff(old~, new~)` computes the full sequence of `Delete`, `Insert`, and
`Equal` operations, accessible via `edits()`.

```mbt check
///|
test "Diff computes deletes inserts and equals" {
  let old = ["apple", "pear", "banana"][:]
  let new = ["apple", "banana", "coconut"][:]

  let d = @diff.Diff(old~, new~)

  assert_eq(d.edits().length(), 4)
  assert_true(
    d.edits()
    is [
      Equal(old_index=0, new_index=0, len=1),
      Delete(old_index=1, old_len=1, new_index=1),
      Equal(old_index=2, new_index=1, len=1),
      Insert(old_index=3, new_index=2, new_len=1),
    ],
  )
}
```

## Prefer Unique Anchors With Patience Diff

Pass `algorithm=Patience` to `Diff(old~, new~, algorithm=Patience)` to enable
patience diff. This first finds elements that appear exactly once in both
inputs and uses them as anchors, then runs Myers diff on the unmatched ranges
between those anchors. This can produce more stable result when repeated
elements move around.

```mbt check
///|
test "patience diff keeps unique anchors in place" {
  let old = ["unique", "dup", "dup"][:]
  let new = ["dup", "unique", "dup"][:]

  let myers = @diff.Diff(old~, new~)
  let patience = @diff.Diff(old~, new~, algorithm=Patience)

  assert_true(
    myers.edits()
    is [
      Delete(old_index=0, old_len=1, new_index=0),
      Equal(old_index=1, new_index=0, len=1),
      Insert(old_index=2, new_index=1, new_len=1),
      Equal(old_index=2, new_index=2, len=1),
    ],
  )
  assert_true(
    patience.edits()
    is [
      Insert(old_index=0, new_index=0, new_len=1),
      Equal(old_index=0, new_index=1, len=2),
      Delete(old_index=2, old_len=1, new_index=3),
    ],
  )
}
```

## Group Into Hunks And Render

`group` splits the edit script into `Hunk[T]` values, keeping `context` lines
of surrounding context (default 3). `context` must be non-negative, and
`context=0` emits hunks without surrounding context. Render each `Hunk[T]` as unified-diff
text with `render`, passing a callback that turns one element into its line.

```mbt check
///|
test "group splits distant changes into separate hunks" {
  let old = [
      " aaaaaaaaaa", " bbbbbbbbbb", " cccccccccc", " dddddddddd", " eeeeeeeeee",
      " ffffffffff", " gggggggggg", " hhhhhhhhhh",
    ][:]
  let new = [
      " aaaaaaaaaa", " xxxxxxxxxx", " cccccccccc", " dddddddddd", " eeeeeeeeee",
      " ffffffffff", " yyyyyyyyyy", " hhhhhhhhhh",
    ][:]

  let hunks = @diff.Diff(old~, new~).group(context=1)

  assert_eq(hunks.length(), 2)
  assert_eq(
    hunks[0].render(show=line => line),
    (
      #|@@ -1,3 +1,3 @@
      #|  aaaaaaaaaa
      #|- bbbbbbbbbb
      #|+ xxxxxxxxxx
      #|  cccccccccc
      #|
    ),
  )
  assert_eq(
    hunks[1].render(show=line => line),
    (
      #|@@ -6,3 +6,3 @@
      #|  ffffffffff
      #|- gggggggggg
      #|+ yyyyyyyyyy
      #|  hhhhhhhhhh
      #|
    ),
  )
}
```
