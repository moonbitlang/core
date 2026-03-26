# Diff

Compute edit scripts between two sequences using the Myers diff algorithm by
default, or patience diff when you pass `patience=true`.

`Diff` works with any element type that implements `Hash + Eq`. Constructing a
`Diff[T]` bundles the source arrays with the edit script. Call `group` on the
result to split far-apart changes into separate `Hunk[T]` values for
unified-diff-style output.

## Compute A Diff

`Diff(old~, new~)` computes the full sequence of `Delete`, `Insert`, and
`Equal` operations, accessible via the `edits` field.

```mbt check
///|
test "Diff computes deletes inserts and equals" {
  let old = ["apple", "pear", "banana"][:]
  let new = ["apple", "banana", "coconut"][:]

  let d = @diff.Diff(old~, new~)

  assert_eq(d.edits.length(), 4)
  assert_true(
    d.edits[:]
    is [
      Equal(old_index=0, new_index=0, len=1),
      Delete(old_index=1, new_index=1, old_len=1),
      Equal(old_index=2, new_index=1, len=1),
      Insert(old_index=3, new_index=2, new_len=1),
    ],
  )
}
```

## Prefer Unique Anchors With Patience Diff

Pass `patience=true` to `Diff(old~, new~, patience=true)` to enable patience
diff. This first finds elements that appear exactly once in both inputs and
uses them as anchors, then runs Myers diff on the unmatched ranges between
those anchors. This can produce more stable result when repeated elements move
around.

```mbt check
///|
test "patience diff keeps unique anchors in place" {
  let old = ["unique", "dup", "dup"][:]
  let new = ["dup", "unique", "dup"][:]

  let myers = @diff.Diff(old~, new~)
  let patience = @diff.Diff(old~, new~, patience=true)

  assert_true(
    myers.edits[:]
    is [
      Delete(old_index=0, new_index=0, old_len=1),
      Equal(old_index=1, new_index=0, len=1),
      Insert(old_index=2, new_index=1, new_len=1),
      Equal(old_index=2, new_index=2, len=1),
    ],
  )
  assert_true(
    patience.edits[:]
    is [
      Insert(old_index=0, new_index=0, new_len=1),
      Equal(old_index=0, new_index=1, len=2),
      Delete(old_index=2, new_index=3, old_len=1),
    ],
  )
}
```

## Group Into Hunks And Render

`group` splits the edit script into `Hunk[T]` values, keeping `radius` lines
of surrounding context (default 3). Each `Hunk[T]` implements `Show`, so you
can print it directly as unified-diff output.

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

  let hunks = @diff.Diff(old~, new~).group(radius=1)

  assert_eq(hunks.length(), 2)
  assert_eq(
    hunks[0].to_string(),
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
    hunks[1].to_string(),
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
