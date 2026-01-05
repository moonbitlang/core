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
/// Rendered content with line layout and paren preference.
///
/// This is an internal implementation detail of `pretty_print`.
/// Users should rely on `pretty_print_repr` / `pretty_print_delta`.
priv struct Content {
  size : Int
  lines : Array[String]
  needs_parens : Bool
}

///|
/// Rendered content without paren preference metadata.
///
/// This is an internal implementation detail of `pretty_print`.
priv struct ContentParens {
  size : Int
  lines : Array[String]
}

///|

///|
impl Add for ContentParens with add(self, other) {
  { size: self.size + other.size, lines: self.lines + other.lines }
}

///|
/// Empty content value.
fn empty_content() -> Content {
  { size: 0, lines: [], needs_parens: false }
}

///|
/// Single literal token as a `ContentParens`.
fn verbatim(x : String) -> ContentParens {
  { size: 1, lines: [x] }
}

///|
/// Build a `ContentParens` from explicit size and lines.
fn content_parens(size : Int, lines : Array[String]) -> ContentParens {
  { size, lines }
}

///|
/// Render any `Show` value as a leaf content node.
fn[T : Show] leaf(x : T, needs_parens? : Bool = false) -> Content {
  { size: 1, lines: [repr(x)], needs_parens }
}

///|
/// Render any `Show` value as a leaf with a type suffix.

///|
/// Map a transformation over the lines of `ContentParens`.
fn with_lines(
  r : ContentParens,
  f : (Array[String]) -> Array[String],
) -> ContentParens {
  { size: r.size, lines: f(r.lines) }
}

///|
/// Map a transformation over the lines of `Content`.
fn Content::with_lines_content(
  r : Content,
  f : (Array[String]) -> Array[String],
) -> Content {
  { size: r.size, lines: f(r.lines), needs_parens: r.needs_parens }
}

///|
/// Surround multi-line content with a prefix/suffix, preserving layout.
fn surround_lines(
  start : String,
  finish : String,
  lines : Array[String],
) -> Array[String] {
  match lines {
    [] => [start + finish]
    [item] => [start + item + finish]
    [first, ..] => {
      let n = lines.length()
      let middle = if n <= 2 { [] } else { lines[1:n - 1].to_array() }
      let last = lines[n - 1]
      [start + first] + middle + [last + finish]
    }
  }
}

///|
/// Surround content with a prefix/suffix, preserving layout.
fn surround(
  start : String,
  finish : String,
  r : ContentParens,
) -> ContentParens {
  with_lines(r, fn(lines) { surround_lines(start, finish, lines) })
}

///|
/// Convert `Content` to `ContentParens` without adding parentheses.
fn Content::no_wrap(c : Content) -> ContentParens {
  { size: c.size, lines: c.lines }
}

///|
/// Mark a content chunk as needing parentheses when embedded.
fn parens(r : ContentParens) -> Content {
  { size: r.size, lines: r.lines, needs_parens: true }
}

///|
/// Mark a content chunk as not needing parentheses when embedded.
fn no_parens(r : ContentParens) -> Content {
  { size: r.size, lines: r.lines, needs_parens: false }
}

///|
/// Compact multi-line output into a single line when possible.
///
/// Note: we special-case common layouts (brackets/braces/paren-calls)
/// so that a multi-line output like:
///
/// ```text
/// [
///   a,
///   b,
/// ]
/// ```
///
/// compacts into:
///
/// ```text
/// [a, b]
/// ```
#warnings("-deprecated")
fn compact_lines(lines : Array[String]) -> Array[String] {
  match lines {
    [] => []
    [x] => [x]
    [first, ..] => {
      let n = lines.length()
      let last = lines[n - 1]

      // Special-case bracket/brace blocks: "[ ... ]" and "{ ... }"
      // produced by `bracket_seq_lines`.
      if (first == "[" && last == "]") || (first == "{" && last == "}") {
        let middle : ArrayView[String] = if n <= 2 {
          []
        } else {
          lines[1:n - 1]
        }
        let parts : Array[String] = []
        for m in middle {
          let t = m.trim_space().to_string()
          if t != "" {
            parts.push(t)
          }
        }
        let joined0 = parts.join(" "[:])
        let joined = match joined0.strip_suffix(","[:]) {
          Some(sv) => sv.to_string()
          None => joined0
        }

        // Match expected style:
        // - arrays: [a, b]
        // - records/maps: { field: value, field: value }
        if first == "{" {
          let inner0 = joined
          let inner1 = match inner0.strip_prefix(" "[:]) {
            Some(sv) => sv.to_string()
            None => inner0
          }
          let inner = match inner1.strip_suffix(" "[:]) {
            Some(sv) => sv.to_string()
            None => inner1
          }
          if inner == "" {
            ["{}"]
          } else {
            ["{ " + inner + " }"]
          }
        } else {
          ["[" + joined + "]"]
        }
      } else {
        // Special-case parenthesized call-like blocks produced by `comma_seq_lines`:
        //
        // ```text
        // Enum(
        //   a,
        //   b,
        // )
        // ```
        //
        // compacts into:
        //
        // ```text
        // Enum(a, b)
        // ```
        match (first.strip_suffix("("[:]), last) {
          (Some(_), ")") => {
            let middle : ArrayView[String] = if n <= 2 {
              []
            } else {
              lines[1:n - 1]
            }
            let parts : Array[String] = []
            for m in middle {
              let t = m.trim_space().to_string()
              if t != "" {
                parts.push(t)
              }
            }
            let joined0 = parts.join(" "[:])
            let joined = match joined0.strip_suffix(","[:]) {
              Some(sv) => sv.to_string()
              None => joined0
            }
            [first + joined + last]
          }
          _ => {
            let middle : ArrayView[String] = if n <= 2 {
              []
            } else {
              lines[1:n - 1]
            }
            let parts : Array[StringView] = [first]
            for m in middle {
              parts.push(m.trim_space())
            }
            parts.push(last.trim_space())
            [parts.join(" "[:])]
          }
        }
      }
    }
  }
}

///|
/// Compact a `Content` value.
fn Content::compact(r : Content) -> Content {
  r.with_lines_content(compact_lines)
}

///|
/// Indent every line by a fixed prefix.
fn indent(prefix : String, r : ContentParens) -> ContentParens {
  with_lines(r, fn(lines) { lines.map(fn(line) { prefix + line }) })
}

///|
/// Indent every line by a fixed number of spaces.
fn indent_spaces(n : Int, r : ContentParens) -> ContentParens {
  indent(" ".repeat(n), r)
}

///|
/// Render a bracket/brace sequence.
///
/// Multi-line layout is:
///
/// ```text
/// [
///   a,
///   b,
/// ]
/// ```
///
/// Compact layout (handled by `compact_lines`) is:
///
/// ```text
/// [a, b]
/// ```
fn bracket_seq_lines(
  open : String,
  close : String,
  indent_by : Int,
  contents : Array[Array[String]],
) -> Array[String] {
  match contents {
    [] => [open + close]
    [item] =>
      // If the item itself is multi-line, keep the surrounding brackets/braces
      // multi-line too (important for nested structures when threshold=0).
      // Also ensure the single element still gets a trailing comma in multi-line mode.
      if item.length() > 1 {
        let lines = indent_spaces(indent_by, { size: 0, lines: item }).lines
        if lines.length() > 0 {
          let last_i = lines.length() - 1
          lines[last_i] = lines[last_i] + ","
        }
        [open] + lines + [close]
      } else {
        // single-line item stays on one line
        let inner = compact_lines(item)
        match inner {
          [] => [open + close]
          [x] =>
            if open == "{" && close == "}" {
              let inner = x.trim().to_string()
              if inner == "" {
                ["{}"]
              } else {
                ["{ " + inner + " }"]
              }
            } else {
              [open + x + close]
            }
          _ =>
            [open] +
            indent_spaces(indent_by, { size: 0, lines: item }).lines +
            [close]
        }
      }
    _ => {
      // Multi-line always uses trailing comma style to match expectation.
      let out : Array[String] = [open]
      for i = 0; i < contents.length(); i = i + 1 {
        let item = contents[i]
        let item_lines = item.filter(fn(line) { line != "" })
        match item_lines {
          [] => ()
          [x] => out.push(" ".repeat(indent_by) + x + ",")
          [first, ..] => {
            let n = item_lines.length()
            out.push(" ".repeat(indent_by) + first)
            if n > 2 {
              for mid in item_lines[1:n - 1] {
                out.push(" ".repeat(indent_by) + mid)
              }
            }
            out.push(" ".repeat(indent_by) + item_lines[n - 1] + ",")
          }
        }
      }
      out.push(close)
      out
    }
  }
}

///|
/// Join content chunks with commas and consistent indentation.
///
/// This is used for function call arguments etc.
fn comma_seq_lines(
  begin : String,
  end : String,
  contents : Array[Array[String]],
) -> Array[String] {
  // Special-case common bracket/brace forms to get nicer pretty-print output.
  if begin == "[" && end == "]" {
    bracket_seq_lines("[", "]", 2, contents)
  } else if begin == "{" && end == "}" {
    bracket_seq_lines("{", "}", 2, contents)
  } else if begin == "" && end == "" {
    // Used by some internal layouts (e.g. opaque wrappers).
    // Keep the legacy behavior to avoid introducing an empty leading/trailing line.
    fn spacer(begin : String) -> String {
      " ".repeat(begin.length())
    }

    let lines = match contents {
      [] => [begin + end]
      [item] => surround_lines(begin, end, item)
      [first, ..] => {
        let n = contents.length()
        let middle = if n <= 2 { [] } else { contents[1:n - 1].to_array() }
        let last = contents[n - 1]
        let space = spacer(begin)
        let middle_lines = middle.fold(init=[], fn(acc, item) {
          acc + surround_lines(space, ",", item)
        })
        surround_lines(begin, ",", first) +
        middle_lines +
        surround_lines(space, end, last)
      }
    }
    lines.filter(fn(line) { line != "" })
  } else {
    // Multi-line layout with trailing comma style:
    //
    // ```text
    // Enum(
    //   a,
    //   b,
    // )
    // ```
    let indent_by = 2
    match contents {
      [] => [begin + end]
      [item] => {
        let item_lines = item.filter(fn(line) { line != "" })
        match item_lines {
          [] => [begin + end]
          [x] => [begin + x + end]
          _ => {
            let out : Array[String] = [begin]
            for i = 0; i < item_lines.length(); i = i + 1 {
              let line = item_lines[i]
              if i == item_lines.length() - 1 {
                out.push(" ".repeat(indent_by) + line + ",")
              } else {
                out.push(" ".repeat(indent_by) + line)
              }
            }
            out.push(end)
            out
          }
        }
      }
      _ => {
        let out : Array[String] = [begin]
        for i = 0; i < contents.length(); i = i + 1 {
          let item = contents[i]
          let item_lines = item.filter(fn(line) { line != "" })
          match item_lines {
            [] => ()
            [x] => out.push(" ".repeat(indent_by) + x + ",")
            [first, ..] => {
              let n = item_lines.length()
              out.push(" ".repeat(indent_by) + first)
              if n > 2 {
                for mid in item_lines[1:n - 1] {
                  out.push(" ".repeat(indent_by) + mid)
                }
              }
              out.push(" ".repeat(indent_by) + item_lines[n - 1] + ",")
            }
          }
        }
        out.push(end)
        out
      }
    }
  }
}

///|
/// Build a comma-separated sequence as `Content`.
fn comma_seq(
  begin : String,
  end : String,
  contents : Array[ContentParens],
) -> Content {
  let mut size = 0
  for c in contents {
    size += c.size
  }
  {
    size,
    lines: comma_seq_lines(begin, end, contents.map(fn(c) { c.lines })),
    needs_parens: false,
  }
}

///|
/// Convert content into a final `String` with newline separators.
fn print_content(r : ContentParens) -> String {
  r.lines.join("\n"[:])
}

///|
/// Measure the maximum line width (in characters).
fn max_line_width(lines : Array[String]) -> Int {
  let mut m = 0
  for line in lines {
    // `String::length()` counts UTF-16 code units; this is good enough for a
    // debug pretty printer.
    let w = line.length()
    if w > m {
      m = w
    }
  }
  m
}

///|
/// Render compactly when the compact single-line layout stays under `threshold`.
///
/// `threshold` is treated as a *maximum width hint* (not a structural node count).
/// This fixes cases where a structurally small tree expands to a very long single
/// line (e.g. deeply nested `Cons(...)`).
fn with_resizing(
  _root_size : Int,
  threshold : Int,
  f : (Array[Content]) -> Content,
  children : Array[Content],
) -> Content {
  // `threshold=0` is used by tests/users to force multi-line output.
  // In that mode we should never run the compaction pass.
  let rendered = f(children)
  if threshold <= 0 {
    rendered
  } else {
    let compacted = rendered.compact()
    // Compacting is intended to produce a single line for the current node.
    // Still, we use the max line width to be safe.
    if max_line_width(compacted.lines) <= threshold {
      compacted
    } else {
      rendered
    }
  }
}
