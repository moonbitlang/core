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

// Real-world validation of HTML diff rendering on the public `@diff` API:
// a side-by-side (split) view with intraline word highlights, exercised on
// genuine inputs — an actual refactor from this package's own history, prose,
// and HTML-special/Unicode content. Shares `tokenize`/`esc`/`side_rows`/
// `word_diff_html` with diff_word_test.mbt (same blackbox package).

///|
/// GitHub-style split view: one table row per line pair. Equal lines appear
/// on both sides; a Delete+Insert replacement is word-diffed once and its
/// refined rows are zipped (excess lines pair with an empty cell); pure
/// deletions/insertions leave the other cell empty.
fn side_by_side_html(
  old~ : ArrayView[String],
  new~ : ArrayView[String],
) -> String {
  let buf = StringBuilder::new()
  fn row(l : String, lc : String, r : String, rc : String) {
    buf <+
      "<tr><td class=\"\{lc}\">\{l}</td><td class=\"\{rc}\">\{r}</td></tr>\n"
  }

  buf <+ "<table class=\"split\">\n"
  for h in @diff.Diff(old~, new~).group() {
    buf <+
      "<tr><td class=\"hunk-header\" colspan=\"2\">\{esc(h.header())}</td></tr>\n"
    let edits = h.edits()
    let o = h.old_view()
    let n = h.new_view()
    let mut i = 0
    while i < edits.length() {
      match edits[i] {
        Delete(old_index~, old_len~, ..) if i + 1 < edits.length() &&
          edits[i + 1] is Insert(..) => {
          guard edits[i + 1] is Insert(new_index~, new_len~, ..)
          let old_lines = o.view(start=old_index, end=old_index + old_len)
          let new_lines = n.view(start=new_index, end=new_index + new_len)
          // tokenize each line once
          let olds = old_lines.map(l => tokenize_line(l))
          let news = new_lines.map(l => tokenize_line(l))
          // DP work budget (cells), plus dimension guards
          let mut work = 0
          for ta in olds {
            for tb in news {
              work += (ta.length() + 1) * (tb.length() + 1)
            }
          }
          if olds.length() > 64 || news.length() > 64 || work > 2_000_000 {
            // safe fallback: plain unpaired rows, never highlighted zipping
            for l in old_lines {
              row(esc(l), "del", "", "empty")
            }
            for l in new_lines {
              row("", "empty", esc(l), "add")
            }
          } else {
            for pair in align(olds, news) {
              match pair {
                (Some(ii), Some(jj)) => {
                  let (lh, rh) = pair_row_html(pair_ops(olds[ii], news[jj]))
                  row(lh, "del", rh, "add")
                }
                (Some(ii), None) => row(esc(old_lines[ii]), "del", "", "empty")
                (None, Some(jj)) => row("", "empty", esc(new_lines[jj]), "add")
                (None, None) => ()
              }
            }
          }
          i += 2
        }
        Equal(old_index~, len~, ..) => {
          for l in o.view(start=old_index, end=old_index + len) {
            row(esc(l), "ctx", esc(l), "ctx")
          }
          i += 1
        }
        Delete(old_index~, old_len~, ..) => {
          for l in o.view(start=old_index, end=old_index + old_len) {
            row(esc(l), "del", "", "empty")
          }
          i += 1
        }
        Insert(new_index~, new_len~, ..) => {
          for l in n.view(start=new_index, end=new_index + new_len) {
            row("", "empty", esc(l), "add")
          }
          i += 1
        }
      }
    }
  }
  buf <+ "</table>\n"
  buf.to_string()
}

///|
test "split view keeps blank-but-present rows classified" {
  // old's blank middle line is part of the replacement: it must render as a
  // (blank) deletion cell, while the genuinely absent excess row on the new
  // side renders as an empty cell.
  let html = side_by_side_html(old=["foo(1)", "", "bar(2)"], new=[
    "foo(9)", "baz(3)",
  ])
  inspect(html.contains("<td class=\"del\"></td>"), content="true")
  inspect(html.contains("<td class=\"empty\"></td>"), content="true")
}

///|
fn lines_of(text : String) -> Array[String] {
  text.split("\n").map(l => l.to_owned()).collect()
}

///|
test "real-world HTML diff page" (t : @test.Test) {
  // Example 0: verbatim git history — diff/extends.mbt across the API
  // redesign (commit 25334bf6 -> current main), fetched with `git show`.
  let extends_old =
    #|// Copyright 2026 International Digital Economy Academy
    #|//
    #|// Licensed under the Apache License, Version 2.0 (the "License");
    #|// you may not use this file except in compliance with the License.
    #|// You may obtain a copy of the License at
    #|//
    #|//     http://www.apache.org/licenses/LICENSE-2.0
    #|//
    #|// Unless required by applicable law or agreed to in writing, software
    #|// distributed under the License is distributed on an "AS IS" BASIS,
    #|// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    #|// See the License for the specific language governing permissions and
    #|// limitations under the License.
    #|
    #|// --- promoted: kept as regular methods ---
    #|
    #|// A hunk's canonical string form is its unified-diff text, so `to_string` is
    #|// promoted; `output` is not (use the trait or string interpolation).
    #|
    #|///|
    #|pub extend Hunk with Show::{to_string}
    #|
    #|// --- deprecated: hidden from the generated interface ---
    #|
    #|///|
    #|#deprecated("Use `Debug::to_repr` instead", skip_current_package=true)
    #|#doc(hidden)
    #|pub extend Edit with @debug.Debug::{to_repr}
    #|
    #|///|
    #|#deprecated("Use `Show::output` via the trait or `to_string` instead", skip_current_package=true)
    #|#doc(hidden)
    #|pub extend Hunk with Show::{output}
  let extends_new =
    #|// Copyright 2026 International Digital Economy Academy
    #|//
    #|// Licensed under the Apache License, Version 2.0 (the "License");
    #|// you may not use this file except in compliance with the License.
    #|// You may obtain a copy of the License at
    #|//
    #|//     http://www.apache.org/licenses/LICENSE-2.0
    #|//
    #|// Unless required by applicable law or agreed to in writing, software
    #|// distributed under the License is distributed on an "AS IS" BASIS,
    #|// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    #|// See the License for the specific language governing permissions and
    #|// limitations under the License.
    #|
    #|// --- promoted: kept as regular methods ---
    #|
    #|///|
    #|pub extend DiffAlgorithm with Eq::{equal}
    #|
    #|///|
    #|pub extend Edit with Eq::{equal}
    #|
    #|// --- deprecated: hidden from the generated interface ---
    #|
    #|///|
    #|#deprecated("Use `Debug::to_repr` instead", skip_current_package=true)
    #|#doc(hidden)
    #|pub extend DiffAlgorithm with @debug.Debug::{to_repr}
    #|
    #|///|
    #|#deprecated("Use `!=` instead", skip_current_package=true)
    #|#doc(hidden)
    #|pub extend DiffAlgorithm with Eq::{not_equal}
    #|
    #|///|
    #|#deprecated("Use `Debug::to_repr` instead", skip_current_package=true)
    #|#doc(hidden)
    #|pub extend Edit with @debug.Debug::{to_repr}
    #|
    #|///|
    #|#deprecated("Use `!=` instead", skip_current_package=true)
    #|#doc(hidden)
    #|pub extend Edit with Eq::{not_equal}

  // Example 1: an actual refactor from this package's history — Hunk's
  // Show impl becoming the callback-based `render` (#3247 -> #3941 era).
  // Raw #| strings keep the embedded \{...} interpolations literal.
  let show_impl =
    #|///|
    #|pub impl[T : Show] Show for Hunk[T] with fn output(self, logger) {
    #|  let header = HunkHeader::new(self.edits).to_string()
    #|  logger.write_string(header)
    #|  logger.write_char('\n')
    #|  for edit in self.edits {
    #|    let (prefix, slice) = match edit {
    #|      Insert(..) => ("+", edit.view_from(old=self.old, new=self.new))
    #|      Delete(..) => ("-", edit.view_from(old=self.old, new=self.new))
    #|      Equal(..) => (" ", edit.view_from(old=self.old, new=self.new))
    #|    }
    #|    for s in slice {
    #|      logger.write_string("\{prefix}\{s}\n")
    #|    }
    #|  }
    #|}
  let render_fn =
    #|///|
    #|pub fn[T] Hunk::render(self : Hunk[T], show~ : (T) -> String) -> String {
    #|  let buf = StringBuilder::new()
    #|  buf <+ "\{self.header()}\n"
    #|  for edit in self.edits {
    #|    let (prefix, slice) = match edit {
    #|      Insert(..) => ("+", edit.view_from(old=self.old, new=self.new))
    #|      Delete(..) => ("-", edit.view_from(old=self.old, new=self.new))
    #|      Equal(..) => (" ", edit.view_from(old=self.old, new=self.new))
    #|    }
    #|    for s in slice {
    #|      buf <+ "\{prefix}\{show(s)}\n"
    #|    }
    #|  }
    #|  buf.to_string()
    #|}

  // Example 2: prose (word diff on natural language).
  let prose_old =
    #|`group` splits the edit script into `Hunk[T]` values, keeping `radius` lines
    #|of surrounding context (default 3). `radius` must be non-negative, and
    #|`radius=0` emits hunks without surrounding context.
  let prose_new =
    #|`group` splits the edit script into `Hunk[T]` values, keeping `context` lines
    #|of surrounding context (default 3). `context` must be non-negative, and
    #|`context=0` emits hunks without surrounding context.

  // Example 3: HTML-special characters and Unicode.
  let special_old =
    #|if a < b && *p != '&' { emit("<div>") }
    #|let 价格 = 10 // 单价
  let special_new =
    #|if a <= b && *p != '&' { emit("<span>") }
    #|let 价格 = 12 // 含税单价

  t.writeln("<!DOCTYPE html>")
  t.writeln("<html><head><meta charset=\"utf-8\"><style>")
  t.writeln("body { font-family: monospace; }")
  t.writeln("h3 { font-family: sans-serif; }")
  t.writeln(".unified { white-space: pre; }")
  t.writeln(".hunk-header { color: #00a; }")
  t.writeln(".del { background: #ffecec; display: block; }")
  t.writeln(".add { background: #eaffea; display: block; }")
  t.writeln(".ctx { display: block; }")
  t.writeln("b.wd { background: #f8b4b4; font-weight: normal; }")
  t.writeln("b.wa { background: #97e0a0; font-weight: normal; }")
  t.writeln("table.split { border-collapse: collapse; width: 100%; }")
  t.writeln("table.split td { width: 50%; vertical-align: top;")
  t.writeln(
    "  white-space: pre-wrap; border: 1px solid #eee; display: table-cell; }",
  )
  t.writeln("td.empty { background: #fafafa; }")
  t.writeln("</style></head><body>")
  t.writeln(
    "<h3>Verbatim git history: diff/extends.mbt across the API redesign (side-by-side)</h3>",
  )
  t.writeln(
    side_by_side_html(old=lines_of(extends_old), new=lines_of(extends_new)),
  )
  t.writeln("<h3>Refactor from this package's history (side-by-side)</h3>")
  t.writeln(side_by_side_html(old=lines_of(show_impl), new=lines_of(render_fn)))
  t.writeln("<h3>Same refactor (unified, word highlights)</h3>")
  t.writeln("<div class=\"unified\">")
  t.writeln(word_diff_html(old=lines_of(show_impl), new=lines_of(render_fn)))
  t.writeln("</div>")
  t.writeln("<h3>Prose</h3>")
  t.writeln("<div class=\"unified\">")
  t.writeln(word_diff_html(old=lines_of(prose_old), new=lines_of(prose_new)))
  t.writeln("</div>")
  t.writeln("<h3>HTML-special characters and Unicode</h3>")
  t.writeln("<div class=\"unified\">")
  t.writeln(
    word_diff_html(old=lines_of(special_old), new=lines_of(special_new)),
  )
  t.writeln("</div>")
  t.writeln("</body></html>")
  t.snapshot(filename="real_world.html")
}

///|
test "split view work budget falls back to plain rows" {
  // one enormous line blows the DP cell budget: the fallback must render
  // plain unpaired rows with no intraline highlights.
  let big = "word ".repeat(800) + "end"
  let html = side_by_side_html(old=[big], new=["tiny replacement"])
  inspect(html.contains("<b class="), content="false")
  inspect(html.contains("class=\"del\""), content="true")
  inspect(html.contains("class=\"add\""), content="true")
}
