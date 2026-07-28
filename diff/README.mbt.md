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

## Custom Renderers

`render` emits plain unified text. For anything else — terminal colors, HTML,
side-by-side — build on the structural accessors: `header()`, `edits()`, and
the `old_view()` / `new_view()` the edit indices refer to. Core ships no color
or markup support on purpose; a renderer is a small loop:

```mbt check
///|
test "git-style terminal colors from the public Hunk API" {
  let old = ["a", "b", "c"][:]
  let new = ["a", "x", "c"][:]
  let buf = StringBuilder::new()
  for h in @diff.Diff(old~, new~).group(context=1) {
    buf <+ "\u{1b}[36m\{h.header()}\u{1b}[0m\n"
    let o = h.old_view()
    let n = h.new_view()
    for edit in h.edits() {
      match edit {
        Equal(old_index~, len~, ..) =>
          for e in o.view(start=old_index, end=old_index + len) {
            buf <+ " \{e}\n"
          }
        Delete(old_index~, old_len~, ..) =>
          for e in o.view(start=old_index, end=old_index + old_len) {
            buf <+ "\u{1b}[31m-\{e}\u{1b}[0m\n"
          }
        Insert(new_index~, new_len~, ..) =>
          for e in n.view(start=new_index, end=new_index + new_len) {
            buf <+ "\u{1b}[32m+\{e}\u{1b}[0m\n"
          }
      }
    }
  }
  inspect(
    buf.to_string().escape(),
    content=(
      #|"\u{1b}[36m@@ -1,3 +1,3 @@\u{1b}[0m\n a\n\u{1b}[31m-b\u{1b}[0m\n\u{1b}[32m+x\u{1b}[0m\n c\n"
    ),
  )
}
```

An HTML renderer works the same way; escaping and CSS are the renderer's own
concern (see the blackbox tests for a complete example that snapshots a styled
page to `__snapshot__/hunk.html`).
