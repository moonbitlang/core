# Myers Diff

Compute edit scripts between two sequences using the Myers diff algorithm.

`diff` works with any element type that implements `Hash + Eq`. It returns an
array of `Edit` values describing how to transform `old` into `new`.
`group_edits` trims long unchanged ranges and splits far-apart changes into
separate `Hunk` values for unified-diff-style output.

## Compute An Edit Script

`diff` returns the full sequence of `Delete`, `Insert`, and `Equal` operations.
The result is a good input for custom renderers or higher-level post-processing.

```mbt check
///|
test "diff returns deletes inserts and equals" {
  let old = ["apple", "pear", "banana"][:]
  let new = ["apple", "banana", "coconut"][:]

  let edits = @diff.diff(old~, new~)

  assert_eq(edits.length(), 4)
  assert_true(
    edits
    is [
      Equal(old_index=0, new_index=0, len=1),
      Delete(old_index=1, new_index=1, old_len=1),
      Equal(old_index=2, new_index=1, len=1),
      Insert(old_index=3, new_index=2, new_len=1),
    ],
  )
}
```

### Limit Computation Cost

Pass `cutoff` to cap the minimum edit distance the algorithm will search
exhaustively. When the actual distance exceeds `cutoff`, `diff` returns a
correct but not necessarily minimal result. The default is approximately
`sqrt(old.length() + new.length())`.

```mbt check
///|
test "cutoff limits search depth" {
  let old = ["a", "b", "c", "d", "e"][:]
  let new = ["v", "w", "x", "y", "z"][:]

  // with a very low cutoff the diff still completes
  let edits = @diff.diff(old~, new~, cutoff=2)
  assert_true(edits.length() > 0)
}
```

## Group Edits Into Hunks

`group_edits` prepares output for unified-diff-style displays. It keeps
`radius` lines of surrounding context around each change (default 3) and
splits far-apart changes into separate hunks.

```mbt check
///|
test "group_edits splits distant changes into separate hunks" {
  let old = [
      " aaaaaaaaaa", " bbbbbbbbbb", " cccccccccc", " dddddddddd", " eeeeeeeeee",
      " ffffffffff", " gggggggggg", " hhhhhhhhhh",
    ][:]
  let new = [
      " aaaaaaaaaa", " xxxxxxxxxx", " cccccccccc", " dddddddddd", " eeeeeeeeee",
      " ffffffffff", " yyyyyyyyyy", " hhhhhhhhhh",
    ][:]

  let groups = @diff.group_edits(@diff.diff(old~, new~), radius=1)

  assert_eq(groups.length(), 2)
  assert_eq(
    groups[0].render_with(old~, new~),
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
    groups[1].render_with(old~, new~),
    (
      #|@@ -6,3 +6,3 @@
      #|  ffffffffff
      #|- gggggggggg
      #|+ yyyyyyyyyy
      #|  hhhhhhhhhh
      #|
    ),
  )

  assert_true(
    groups
    is [
      Hunk(
        [
          Equal(_),
          Delete(old_index=1, new_index=1, old_len=1),
          Insert(old_index=1, new_index=1, new_len=1),
          Equal(_),
        ]
      ),
      Hunk(
        [
          Equal(_),
          Delete(old_index=6, new_index=6, old_len=1),
          Insert(old_index=6, new_index=6, new_len=1),
          Equal(_),
        ]
      ),
    ],
  )
}
```

