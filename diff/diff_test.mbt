// Copyright 2026 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
fn[T] edits_to_string(d : @diff.Diff[T], show~ : (T) -> String) -> String {
  let old = d.old_view()
  let new = d.new_view()
  let lines = Array::new()
  for edit in d.edits() {
    let (prefix, slice) = match edit {
      Insert(new_index~, new_len~, ..) =>
        ("+", new.view(start=new_index, end=new_index + new_len))
      Delete(old_index~, old_len~, ..) =>
        ("-", old.view(start=old_index, end=old_index + old_len))
      Equal(old_index~, len~, ..) =>
        (" ", old.view(start=old_index, end=old_index + len))
    }
    for s in slice {
      lines.push("\{prefix} \{show(s)}")
    }
  }
  lines.join("\n")
}

///|
fn[T] hunks_to_string(
  hunks : Array[@diff.Hunk[T]],
  show~ : (T) -> String,
) -> String {
  hunks.map(fn(h) { h.render(show~) }).join("\n")
}

///|
priv struct User {
  id : Int
  name : String
} derive(Hash, Eq)

///|
fn show_user(u : User) -> String {
  "User { id: " + u.id.to_string() + ", name: " + u.name + " }"
}

///|
priv enum Token {
  Start
  Stop
  Num(Int)
  Word(String)
} derive(Hash, Eq)

///|
fn show_token(t : Token) -> String {
  match t {
    Start => "Start"
    Stop => "Stop"
    Num(n) => "Num(" + n.to_string() + ")"
    Word(w) => "Word(\"" + w + "\")"
  }
}

///|
test "condense into one equal" {
  let old = [
      "apple", "pineapple", "banana", "tomato", "carrot", "tomato", "potato", "cabbage",
    ][:]
  let new = [
      "apple", "pineapple", "banana", "tomato", "carrot", "tomato", "potato", "cabbage",
    ][:]
  @debug.assert_eq(old, new)
  let d = @diff.Diff(old~, new~)
  let patience = @diff.Diff(old~, new~, algorithm=Patience)
  inspect(
    edits_to_string(d, show=s => s),
    content=(
      #|  apple
      #|  pineapple
      #|  banana
      #|  tomato
      #|  carrot
      #|  tomato
      #|  potato
      #|  cabbage
    ),
  )
  inspect(
    edits_to_string(patience, show=s => s),
    content=(
      #|  apple
      #|  pineapple
      #|  banana
      #|  tomato
      #|  carrot
      #|  tomato
      #|  potato
      #|  cabbage
    ),
  )
}

///|
test "mixed" {
  let old = ["carrot", "tomato", "potato", "cabbage"][:]
  let new = ["apple", "banana", "tomato", "pineapple"][:]
  let d = @diff.Diff(old~, new~)
  let patience = @diff.Diff(old~, new~, algorithm=Patience)
  inspect(
    edits_to_string(d, show=s => s),
    content=(
      #|- carrot
      #|+ apple
      #|+ banana
      #|  tomato
      #|- potato
      #|- cabbage
      #|+ pineapple
    ),
  )
  inspect(
    edits_to_string(patience, show=s => s),
    content=(
      #|- carrot
      #|+ apple
      #|+ banana
      #|  tomato
      #|- potato
      #|- cabbage
      #|+ pineapple
    ),
  )
}

///|
test "delete then insert to hunks" {
  let old = ["fn main() {", "  println(\"foo\")", "}"][:]
  let new = ["fn main() {", "  println(\"bar\")", "}"][:]
  let d = @diff.Diff(old~, new~)
  let patience = @diff.Diff(old~, new~, algorithm=Patience)
  inspect(
    edits_to_string(d, show=s => s),
    content=(
      #|  fn main() {
      #|-   println("foo")
      #|+   println("bar")
      #|  }
    ),
  )
  inspect(
    edits_to_string(patience, show=s => s),
    content=(
      #|  fn main() {
      #|-   println("foo")
      #|+   println("bar")
      #|  }
    ),
  )
  inspect(
    hunks_to_string(d.group(), show=s => s),
    content=(
      #|@@ -1,3 +1,3 @@
      #| fn main() {
      #|-  println("foo")
      #|+  println("bar")
      #| }
      #|
    ),
  )
}

///|
test "delete then insert to hunks without context" {
  let old = ["fn main() {", "  println(\"foo\")", "}"][:]
  let new = ["fn main() {", "  println(\"bar\")", "}"][:]
  let d = @diff.Diff(old~, new~)
  let patience = @diff.Diff(old~, new~, algorithm=Patience)
  inspect(
    hunks_to_string(d.group(context=0), show=s => s),
    content=(
      #|@@ -2 +2 @@
      #|-  println("foo")
      #|+  println("bar")
      #|
    ),
  )
  inspect(
    hunks_to_string(patience.group(context=0), show=s => s),
    content=(
      #|@@ -2 +2 @@
      #|-  println("foo")
      #|+  println("bar")
      #|
    ),
  )
}

///|
test "replacement insert uses post-delete old cursor" {
  let old = ["x", "a"][:]
  let new = ["y", "z", "a"][:]
  let d = @diff.Diff(old~, new~)
  assert_true(
    d.edits()
    is [
      Delete(old_index=0, old_len=1, new_index=0),
      Insert(old_index=1, new_index=0, new_len=2),
      Equal(old_index=1, new_index=2, len=1),
    ],
  )
}

///|
test "panic group with negative context" {
  let old = ["fn main() {", "}"][:]
  let new = old
  ignore(@diff.Diff(old~, new~).group(context=-1))
}

///|
test "large text to hunks" {
  let old = [
      "alert", "chop", "brave", "arise", "bring", "boy", "answer", "count", "begin",
      "casual", "dot", "bottom",
    ][:]
  let new = [
      "alert", "chop", "brave", "arise", "bring", "joy", "answer", "count", "begin",
      "casual", "dot", "bottom",
    ][:]
  let d = @diff.Diff(old~, new~)
  let patience = @diff.Diff(old~, new~, algorithm=Patience)
  inspect(
    edits_to_string(d, show=s => s),
    content=(
      #|  alert
      #|  chop
      #|  brave
      #|  arise
      #|  bring
      #|- boy
      #|+ joy
      #|  answer
      #|  count
      #|  begin
      #|  casual
      #|  dot
      #|  bottom
    ),
  )
  inspect(
    edits_to_string(patience, show=s => s),
    content=(
      #|  alert
      #|  chop
      #|  brave
      #|  arise
      #|  bring
      #|- boy
      #|+ joy
      #|  answer
      #|  count
      #|  begin
      #|  casual
      #|  dot
      #|  bottom
    ),
  )
  inspect(
    hunks_to_string(d.group(), show=s => s),
    content=(
      #|@@ -3,7 +3,7 @@
      #| brave
      #| arise
      #| bring
      #|-boy
      #|+joy
      #| answer
      #| count
      #| begin
      #|
    ),
  )
  inspect(
    hunks_to_string(d.group(context=2), show=s => s),
    content=(
      #|@@ -4,5 +4,5 @@
      #| arise
      #| bring
      #|-boy
      #|+joy
      #| answer
      #| count
      #|
    ),
  )
}

///|
test "diff with Int elements" {
  let old = [1, 2, 3, 4][:]
  let new = [1, 2, 4, 5][:]
  let d = @diff.Diff(old~, new~)
  let patience = @diff.Diff(old~, new~, algorithm=Patience)
  inspect(
    edits_to_string(d, show=n => n.to_string()),
    content=(
      #|  1
      #|  2
      #|- 3
      #|  4
      #|+ 5
    ),
  )
  inspect(
    edits_to_string(patience, show=n => n.to_string()),
    content=(
      #|  1
      #|  2
      #|- 3
      #|  4
      #|+ 5
    ),
  )
}

///|
test "diff with Bool elements" {
  let old = [true, false, false][:]
  let new = [true, false, true][:]
  let d = @diff.Diff(old~, new~)
  let patience = @diff.Diff(old~, new~, algorithm=Patience)
  inspect(
    edits_to_string(d, show=b => b.to_string()),
    content=(
      #|  true
      #|  false
      #|- false
      #|+ true
    ),
  )
  inspect(
    edits_to_string(patience, show=b => b.to_string()),
    content=(
      #|  true
      #|  false
      #|- false
      #|+ true
    ),
  )
}

///|
test "diff with struct elements" {
  let old = [
      { id: 1, name: "alice" },
      { id: 2, name: "bob" },
      { id: 3, name: "charlie" },
    ][:]
  let new = [
      { id: 1, name: "alice" },
      { id: 3, name: "charlie" },
      { id: 4, name: "david" },
    ][:]
  let d = @diff.Diff(old~, new~)
  let patience = @diff.Diff(old~, new~, algorithm=Patience)
  inspect(
    edits_to_string(d, show=show_user),
    content=(
      #|  User { id: 1, name: alice }
      #|- User { id: 2, name: bob }
      #|  User { id: 3, name: charlie }
      #|+ User { id: 4, name: david }
    ),
  )
  inspect(
    edits_to_string(patience, show=show_user),
    content=(
      #|  User { id: 1, name: alice }
      #|- User { id: 2, name: bob }
      #|  User { id: 3, name: charlie }
      #|+ User { id: 4, name: david }
    ),
  )
}

///|
test "diff with enum elements" {
  let old = [Start, Word("alpha"), Num(1), Stop][:]
  let new = [Start, Num(1), Word("beta"), Stop][:]
  let d = @diff.Diff(old~, new~)
  let patience = @diff.Diff(old~, new~, algorithm=Patience)
  inspect(
    edits_to_string(d, show=show_token),
    content=(
      #|  Start
      #|- Word("alpha")
      #|  Num(1)
      #|+ Word("beta")
      #|  Stop
    ),
  )
  inspect(
    edits_to_string(patience, show=show_token),
    content=(
      #|  Start
      #|- Word("alpha")
      #|  Num(1)
      #|+ Word("beta")
      #|  Stop
    ),
  )
}

///|
test "patience diff prefers unique anchors" {
  let old = ["unique", "dup", "dup"][:]
  let new = ["dup", "unique", "dup"][:]
  let myers = @diff.Diff(old~, new~)
  let patience = @diff.Diff(old~, new~, algorithm=Patience)
  inspect(
    edits_to_string(myers, show=s => s),
    content=(
      #|- unique
      #|  dup
      #|+ unique
      #|  dup
    ),
  )
  inspect(
    edits_to_string(patience, show=s => s),
    content=(
      #|+ dup
      #|  unique
      #|  dup
      #|- dup
    ),
  )
}

///|
/// Replay an edit script over `old` and check it reconstructs `new` exactly,
/// with monotone cursors and no zero-length edits. This holds for *any* valid
/// script, so it verifies the algorithms independently of which minimal diff
/// they deterministically choose — including the non-minimal results produced
/// when `cutoff` is exceeded.
fn check_reconstruct(
  d : @diff.Diff[Int],
  old : ArrayView[Int],
  new : ArrayView[Int],
) -> Unit raise {
  let rebuilt = Array::new()
  let mut oi = 0
  let mut ni = 0
  for edit in d.edits() {
    match edit {
      Equal(old_index~, new_index~, len~) => {
        assert_eq(old_index, oi)
        assert_eq(new_index, ni)
        assert_true(len > 0)
        for k in 0..<len {
          assert_eq(old[old_index + k], new[new_index + k])
          rebuilt.push(old[old_index + k])
        }
        oi += len
        ni += len
      }
      Delete(old_index~, old_len~, new_index~) => {
        assert_eq(old_index, oi)
        assert_eq(new_index, ni)
        assert_true(old_len > 0)
        oi += old_len
      }
      Insert(old_index~, new_index~, new_len~) => {
        assert_eq(old_index, oi)
        assert_eq(new_index, ni)
        assert_true(new_len > 0)
        for k in 0..<new_len {
          rebuilt.push(new[new_index + k])
        }
        ni += new_len
      }
    }
  }
  assert_eq(oi, old.length())
  assert_eq(ni, new.length())
  @debug.assert_eq(rebuilt, new.to_owned())
}

///|
test "property: edit scripts reconstruct new from old" {
  // Exhaustive over all pairs of {0,1}-sequences of length 0..4, both
  // algorithms, with the default cutoff and a tiny one (heuristic path).
  let seqs : Array[Array[Int]] = []
  for len in 0..<5 {
    for bits in 0..<(1 << len) {
      let a = Array::new(capacity=len)
      for i in 0..<len {
        a.push((bits >> i) & 1)
      }
      seqs.push(a)
    }
  }
  for a in seqs {
    for b in seqs {
      for alg in ([Myers, Patience] : Array[@diff.DiffAlgorithm]) {
        check_reconstruct(Diff(old=a, new=b, algorithm=alg), a, b)
        check_reconstruct(Diff(old=a, new=b, algorithm=alg, cutoff=1), a, b)
      }
    }
  }
}

///|
/// A terminal renderer written purely against the public API
/// (`header` + `edits` + views), the way a third-party `diff-ansi` package
/// would: cyan hunk header, red removals, green additions (git's default look).
fn[T] ansi_render(h : @diff.Hunk[T], show~ : (T) -> String) -> String {
  let buf = StringBuilder::new()
  buf <+ "\u{1b}[36m\{h.header()}\u{1b}[0m\n"
  let old = h.old_view()
  let new = h.new_view()
  for edit in h.edits() {
    match edit {
      Equal(old_index~, len~, ..) =>
        for e in old.view(start=old_index, end=old_index + len) {
          buf <+ " \{show(e)}\n"
        }
      Delete(old_index~, old_len~, ..) =>
        for e in old.view(start=old_index, end=old_index + old_len) {
          buf <+ "\u{1b}[31m-\{show(e)}\u{1b}[0m\n"
        }
      Insert(new_index~, new_len~, ..) =>
        for e in new.view(start=new_index, end=new_index + new_len) {
          buf <+ "\u{1b}[32m+\{show(e)}\u{1b}[0m\n"
        }
    }
  }
  buf.to_string()
}

///|
/// An HTML renderer written purely against the public API, the way a
/// third-party `diff-html` package would. Escaping is the renderer's own
/// concern — exactly why HTML stays out of core.
fn[T] html_render(h : @diff.Hunk[T], show~ : (T) -> String) -> String {
  fn esc(s : String) -> String {
    let buf = StringBuilder::new()
    for c in s {
      match c {
        '&' => buf.write_string("&amp;")
        '<' => buf.write_string("&lt;")
        '>' => buf.write_string("&gt;")
        _ => buf.write_char(c)
      }
    }
    buf.to_string()
  }

  fn line(buf : StringBuilder, cls : String, prefix : String, text : String) {
    buf <+ "<span class=\"\{cls}\">\{prefix}\{text}</span>\n"
  }

  let buf = StringBuilder::new()
  buf <+ "<pre class=\"hunk\">\n"
  buf <+ "<span class=\"hunk-header\">\{esc(h.header())}</span>\n"
  let old = h.old_view()
  let new = h.new_view()
  for edit in h.edits() {
    match edit {
      Equal(old_index~, len~, ..) =>
        for e in old.view(start=old_index, end=old_index + len) {
          line(buf, "ctx", " ", esc(show(e)))
        }
      Delete(old_index~, old_len~, ..) =>
        for e in old.view(start=old_index, end=old_index + old_len) {
          line(buf, "del", "-", esc(show(e)))
        }
      Insert(new_index~, new_len~, ..) =>
        for e in new.view(start=new_index, end=new_index + new_len) {
          line(buf, "add", "+", esc(show(e)))
        }
    }
  }
  buf <+ "</pre>"
  buf.to_string()
}

///|
test "third-party ANSI renderer over the public Hunk API" {
  let old = ["a", "b", "c"][:]
  let new = ["a", "x", "c"][:]
  let hunks = @diff.Diff(old~, new~).group(context=1)
  inspect(
    ansi_render(hunks[0], show=l => l).escape(),
    content=(
      #|"\u{1b}[36m@@ -1,3 +1,3 @@\u{1b}[0m\n a\n\u{1b}[31m-b\u{1b}[0m\n\u{1b}[32m+x\u{1b}[0m\n c\n"
    ),
  )
}

///|
test "third-party HTML renderer over the public Hunk API" (t : @test.Test) {
  // File-based snapshot: the result is a real page at
  // diff/__snapshot__/hunk.html - open it in a browser.
  let old = ["let x = 1", "if a < b {", "  go()", "}"][:]
  let new = ["let x = 1", "if a & b < c {", "  stop()", "}"][:]
  t.writeln("<!DOCTYPE html>")
  t.writeln("<html><head><meta charset=\"utf-8\"><style>")
  t.writeln("pre.hunk { font-family: monospace; }")
  t.writeln(".hunk-header { color: #00a; }")
  t.writeln(".del { background: #fdd; }")
  t.writeln(".add { background: #dfd; }")
  t.writeln("</style></head><body>")
  for h in @diff.Diff(old~, new~).group() {
    t.writeln(html_render(h, show=l => l))
  }
  t.writeln("</body></html>")
  t.snapshot(filename="hunk.html")
}

///|
test "edits() with the views agrees with render()" {
  let old = ["a", "b", "c", "d"][:]
  let new = ["a", "x", "c", "y"][:]
  for h in @diff.Diff(old~, new~).group(context=1) {
    let rebuilt = StringBuilder::new()
    rebuilt <+ "\{h.header()}\n"
    let o = h.old_view()
    let n = h.new_view()
    for edit in h.edits() {
      match edit {
        Equal(old_index~, len~, ..) =>
          for e in o.view(start=old_index, end=old_index + len) {
            rebuilt <+ " \{e}\n"
          }
        Delete(old_index~, old_len~, ..) =>
          for e in o.view(start=old_index, end=old_index + old_len) {
            rebuilt <+ "-\{e}\n"
          }
        Insert(new_index~, new_len~, ..) =>
          for e in n.view(start=new_index, end=new_index + new_len) {
            rebuilt <+ "+\{e}\n"
          }
      }
    }
    assert_eq(rebuilt.to_string(), h.render(show=l => l))
  }
}
