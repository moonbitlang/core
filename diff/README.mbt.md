# Myers Diff

The `diff/myers` package computes edit scripts between two sequences with
Myers' diff algorithm.

`diff` returns a list of `Edit` values describing how to transform `old` into
`new`, while `group_edits` trims long unchanged ranges into hunks that can be
rendered with `HunkHeader`.

`diff` may rewrite equal values in `old~` and `new~` to shared representatives
internally, so equal values should be safely substitutable for one another.

## Compute An Edit Script

Start with `diff` when you want the full sequence of edit operations. The
result keeps both unchanged ranges and changed ranges, so it is a good input
for custom renderers or higher-level post-processing.

```mbt check
///|
test "diff returns deletes inserts and equals" {
  let old = ["apple", "pear", "banana"].mut_view()
  let new = ["apple", "banana", "coconut"].mut_view()

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

## Read The Slice For Each Edit

After you have an `Edit`, `take_tagged_view_from` lets you recover the concrete
slice that the edit refers to. This is useful when you want to inspect or print
the affected values instead of only working with indices and lengths.

```mbt check
///|
test "take_tagged_view_from returns the affected slice" {
  let old = ["apple", "pear", "banana"].mut_view()
  let new = ["apple", "banana", "coconut"].mut_view()
  let edits = @diff.diff(old~, new~)

  assert_true(
    edits.map(edit => edit.take_tagged_view_from(old~, new~))
    is [
      (Equal, ["apple"]),
      (Delete, ["pear"]),
      (Equal, ["banana"]),
      (Insert, ["coconut"]),
    ],
  )
}
```

## Group Edits Into Hunks

Use `group_edits` to prepare output for unified-diff-style displays. It keeps a
small amount of surrounding context around each change and splits far-apart
changes into separate hunks that can be labeled with `HunkHeader`.

```mbt check
///|
test "group_edits splits distant changes into separate hunks" {
  let old = [
    "aaaaaaaaaa", "bbbbbbbbbb", "cccccccccc", "dddddddddd", "eeeeeeeeee", "ffffffffff",
    "gggggggggg", "hhhhhhhhhh",
  ].mut_view()
  let new = [
    "aaaaaaaaaa", "xxxxxxxxxx", "cccccccccc", "dddddddddd", "eeeeeeeeee", "ffffffffff",
    "yyyyyyyyyy", "hhhhhhhhhh",
  ].mut_view()

  let groups = @diff.group_edits(@diff.diff(old~, new~), radius=1)

  assert_eq(groups.length(), 2)
  assert_eq(
    groups[0].render_with(old=old[:], new=new[:]),
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
    groups[1].render_with(old=old[:], new=new[:]),
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
