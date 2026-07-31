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

// A word-based diff with intraline refinement, written purely against the
// public `@diff` API — a prototype of what a third-party `diff-words`
// package would look like. Tokenization uses `lexscan`; rendering targets
// HTML with word-level highlights inside changed lines.

///|
/// Split a text into lexical tokens: identifiers, number literals, whitespace
/// runs, and single punctuation characters. Whitespace is kept as tokens so
/// that concatenating the tokens reproduces the input exactly.
///
/// Deliberately limited: only ASCII identifiers, digit runs, spaces/tabs and
/// newline get grouped treatment; Unicode identifiers, other whitespace and
/// richer number syntax fall back to single-character tokens (still faithful,
/// just finer-grained).
fn tokenize(text : StringView) -> Array[String] {
  let tokens = []
  let mut rest = text
  while rest is [_, ..] {
    rest = lexscan rest with longest {
      (re"^[A-Za-z_][A-Za-z0-9_]*" as tok, after=next) => {
        tokens.push(tok.to_owned())
        next
      }
      (re"^[0-9]+" as tok, after=next) => {
        tokens.push(tok.to_owned())
        next
      }
      (re"^[ \t]+" as tok, after=next) => {
        tokens.push(tok.to_owned())
        next
      }
      // single-char rules capture a `Char`, not a `StringView`
      (re"^\n" as tok, after=next) => {
        tokens.push(tok.to_string())
        next
      }
      (re"^." as tok, after=next) => {
        tokens.push(tok.to_string())
        next
      }
      _ => abort("unreachable: `.` matches any remaining character")
    }
  }
  tokens
}

///|
test "tokenize is faithful and lexical" {
  let toks = tokenize("let x1 = foo(bar, 42);")
  @debug.debug_inspect(
    toks,
    content=(
      #|[
      #|  "let",
      #|  " ",
      #|  "x1",
      #|  " ",
      #|  "=",
      #|  " ",
      #|  "foo",
      #|  "(",
      #|  "bar",
      #|  ",",
      #|  " ",
      #|  "42",
      #|  ")",
      #|  ";",
      #|]
    ),
  )
  inspect(toks.join(""), content="let x1 = foo(bar, 42);")
}

///|
fn esc(s : String) -> String {
  let buf = StringBuilder::new()
  for c in s {
    match c {
      '&' => buf <+ "&amp;"
      '<' => buf <+ "&lt;"
      '>' => buf <+ "&gt;"
      _ => buf.write_char(c)
    }
  }
  buf.to_string()
}

///|
/// Emit the rows of one side of a refined replacement. The whole replacement
/// block (lines joined with `\n`) is word-diffed once; the old side renders
/// Equal + Delete tokens (deletions deep-highlighted), the new side renders
/// Equal + Insert tokens (insertions deep-highlighted). `\n` tokens split
/// rows, so unequal line counts fall out naturally.
fn side_rows(inner : @diff.Diff[String], old_side~ : Bool) -> Array[String] {
  let rows = []
  let buf = StringBuilder::new()
  let run = StringBuilder::new()
  fn flush_run() {
    if run.is_empty() {
      return
    }
    let cls = if old_side { "wd" } else { "wa" }
    buf <+ "<b class=\"\{cls}\">\{run.to_string()}</b>"
    run.reset()
  }

  fn emit(tok : String, changed : Bool) {
    if tok == "\n" {
      flush_run()
      rows.push(buf.to_string())
      buf.reset()
    } else if changed {
      run <+ "\{esc(tok)}"
    } else {
      flush_run()
      buf <+ "\{esc(tok)}"
    }
  }

  let o = inner.old_view()
  let n = inner.new_view()
  for edit in inner.edits() {
    match edit {
      Equal(old_index~, len~, ..) =>
        for t in o.view(start=old_index, end=old_index + len) {
          emit(t, false)
        }
      Delete(old_index~, old_len~, ..) =>
        if old_side {
          for t in o.view(start=old_index, end=old_index + old_len) {
            emit(t, true)
          }
        }
      Insert(new_index~, new_len~, ..) =>
        if !old_side {
          for t in n.view(start=new_index, end=new_index + new_len) {
            emit(t, true)
          }
        }
    }
  }
  flush_run()
  rows.push(buf.to_string())
  rows
}

///|
/// Render a whole diff as an HTML page with intraline word refinement:
/// line-level rows via `group()` + `Hunk` accessors, and for each
/// Delete+Insert replacement pair, word-level highlights via a second
/// `@diff.Diff` over `lexscan` tokens.
fn word_diff_html(old~ : ArrayView[String], new~ : ArrayView[String]) -> String {
  let buf = StringBuilder::new()
  for h in @diff.Diff(old~, new~).group(context=1) {
    buf <+ "<span class=\"hunk-header\">\{esc(h.header())}</span>\n"
    let edits = h.edits()
    let o = h.old_view()
    let n = h.new_view()
    let mut i = 0
    while i < edits.length() {
      match edits[i] {
        Delete(old_index~, old_len~, ..) if i + 1 < edits.length() &&
          edits[i + 1] is Insert(..) => {
          guard! edits[i + 1] is Insert(new_index~, new_len~, ..)
          let removed = o
            .view(start=old_index, end=old_index + old_len)
            .map(l => l)
            .join("\n")
          let added = n
            .view(start=new_index, end=new_index + new_len)
            .map(l => l)
            .join("\n")
          let inner = @diff.Diff(old=tokenize(removed), new=tokenize(added))
          for r in side_rows(inner, old_side=true) {
            buf <+ "<span class=\"del\">-\{r}</span>\n"
          }
          for r in side_rows(inner, old_side=false) {
            buf <+ "<span class=\"add\">+\{r}</span>\n"
          }
          i += 2
        }
        Equal(old_index~, len~, ..) => {
          for l in o.view(start=old_index, end=old_index + len) {
            buf <+ "<span class=\"ctx\"> \{esc(l)}</span>\n"
          }
          i += 1
        }
        Delete(old_index~, old_len~, ..) => {
          for l in o.view(start=old_index, end=old_index + old_len) {
            buf <+ "<span class=\"del\">-\{esc(l)}</span>\n"
          }
          i += 1
        }
        Insert(new_index~, new_len~, ..) => {
          for l in n.view(start=new_index, end=new_index + new_len) {
            buf <+ "<span class=\"add\">+\{esc(l)}</span>\n"
          }
          i += 1
        }
      }
    }
  }
  buf.to_string()
}

///|
test "intraline word diff as a styled HTML page" (t : @test.Test) {
  // File-based snapshot: open diff/__snapshot__/word_diff.html in a browser.
  let old = [
      "fn total(items : Array[Item]) -> Int {", "  let mut sum = 0", "  for item in items {",
      "    sum += item.price * item.count", "  }", "  sum", "}",
    ][:]
  let new = [
      "fn total(items : Array[Item], tax~ : Int) -> Int {", "  let mut sum = 0",
      "  for item in items {", "    sum += item.price * item.count + tax", "  }",
      "  sum", "}",
    ][:]
  t.writeln("<!DOCTYPE html>")
  t.writeln("<html><head><meta charset=\"utf-8\"><style>")
  t.writeln("body { font-family: monospace; white-space: pre; }")
  t.writeln(".hunk-header { color: #00a; }")
  t.writeln(".del { background: #ffecec; display: block; }")
  t.writeln(".add { background: #eaffea; display: block; }")
  t.writeln(".ctx { display: block; }")
  t.writeln("b.wd { background: #f8b4b4; font-weight: normal; }")
  t.writeln("b.wa { background: #97e0a0; font-weight: normal; }")
  t.writeln("</style></head><body>")
  t.writeln(word_diff_html(old~, new~))
  t.writeln("</body></html>")
  t.snapshot(filename="word_diff.html")
}

///|
/// Whitespace- and comment-insensitive diffing: run the diff on a *normalized
/// key* while keeping the original text for rendering. `Diff[T]` only needs
/// `Hash + Eq`, so the policy plugs in as a wrapper type — the algorithm,
/// `group`, and `render` are untouched.
priv struct Loose {
  text : String
  key : String
}

///|
impl Eq for Loose with fn equal(a, b) {
  a.key == b.key
}

///|
impl Hash for Loose with fn hash_combine(self, hasher) {
  Hash::hash_combine(self.key, hasher)
}

///|
/// Normalized key: strip a trailing `//` comment (naive: not string-literal
/// aware), then drop whitespace tokens and rejoin — so any respacing or
/// comment rewrite compares equal.
fn loose(line : String) -> Loose {
  let code = match line.find("//") {
    Some(i) => line.view(end_offset=i)
    None => line.view()
  }
  let kept = tokenize(code).filter(t => !(t is [' ' | '\t', ..]))
  { text: line, key: kept.join("\u{0}") }
}

///|
test "loose keeps a lone trailing slash significant" {
  // regression: the previous regex-based stripper dropped a trailing `/`,
  // making `a/` compare equal to `a`.
  inspect(loose("a/").key == loose("a").key, content="false")
  inspect(loose("x = a/b // c").key == loose("x=a/b").key, content="true")
}

///|
test "whitespace- and comment-insensitive diff via a key wrapper" {
  let old = ["fn f(a:Int)->Int{ // sum", "  a+1", "}"].map(loose)
  let new = ["fn f( a : Int ) -> Int {   // add one", "  a+2", "}"].map(loose)
  let hunks = @diff.Diff(old~, new~).group(context=1)
  // Only the real change surfaces; the respaced line and rewritten comment
  // compare Equal. Note: Equal spans may differ textually under a normalized
  // key — `render` displays the old side's text by convention.
  assert_eq(hunks.length(), 1)
  inspect(
    hunks[0].render(show=l => l.text),
    content=(
      #|@@ -1,3 +1,3 @@
      #| fn f(a:Int)->Int{ // sum
      #|-  a+1
      #|+  a+2
      #| }
      #|
    ),
  )
}
