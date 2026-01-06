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
/// Default max depth for pruning.
let default_max_depth : Int = 4

///|
/// Default layout threshold for compact-vs-multiline decisions.
///
/// Larger values prefer single-line output.
let default_threshold : Int = 30

///|
/// Prune a `Repr` using max_depth (replacing with `Omitted`).
fn prune_repr_info(max_depth : Int?, info : Repr) -> Repr {
  match max_depth {
    None => info
    Some(depth) => prune_info(info, depth~)
  }
}

///|
/// Prune a `Repr` tree to a given depth (replacing pruned subtrees).
///
/// Parameters:
/// - `depth~`: maximum depth. Values `<= 0` are treated as `1`.
/// - `replacement?`: the node used to replace pruned subtrees.
///   Defaults to `Repr::omitted()`.
///
/// Semantics:
/// - Leaf nodes are never replaced.
/// - When the depth budget is exhausted and the node has children:
///   - if `info_adds_depth() == false`, pruning continues into its children;
///   - otherwise the whole subtree is replaced by `replacement`.
fn prune_info(
  info : Repr,
  replacement? : Repr = Repr::omitted(),
  depth~ : Int,
) -> Repr {
  fn go(d : Int, node : Repr) -> Repr {
    let children = node.children()
    if d <= 0 {
      if children.is_empty() {
        node
      } else if !node.info_adds_depth() {
        node.with_children(children.map(fn(child) { go(d, child) }))
      } else {
        replacement
      }
    } else if children.is_empty() {
      node
    } else {
      let next_depth = if node.info_adds_depth() { d - 1 } else { d }
      node.with_children(children.map(fn(child) { go(next_depth, child) }))
    }
  }

  go(Int::max(1, depth), info)
}

///|
/// Whether visiting this node should consume (decrement) the remaining depth budget.
///
/// This is used by depth-limited pruning: structural edge nodes like
/// `RecordField` / `EnumLabeledArg` / `MapEntry` do not count as a depth level,
/// so field names / labels can still be preserved when pruning.
fn Repr::info_adds_depth(info : Repr) -> Bool {
  match info {
    RecordField(_, _) | EnumLabeledArg(_, _) | MapEntry(_, _) => false
    _ => true
  }
}

///|
/// Heuristic "size" of a node for compact-vs-multiline decisions.
fn info_size(info : Repr) -> Int {
  match info {
    UnitLit => 1
    Integer(_) => 1
    DoubleLit(_) => 1
    FloatLit(_) => 1
    BoolLit(_) => 1
    CharLit(_) => 1
    StringLit(s) => if s.length() <= 15 { 1 } else { 2 }
    Tuple(_) => 1
    Array(_) => 1
    Record(_) => 2
    RecordField(name, _) => if name.length() <= 15 { 0 } else { 1 }
    EnumLabeledArg(name, _) => if name.length() <= 15 { 0 } else { 1 }
    Enum(name, _) => if name.length() <= 15 { 1 } else { 2 }
    Opaque(name, _) => if name.length() <= 15 { 1 } else { 2 }
    Literal(s) => if s.length() <= 15 { 1 } else { 2 }
    Map(_) => 2
    MapEntry(_, _) => 0
    Omitted => 0
  }
}

///|
/// Returns `true` when a record field name can be printed without quotes.
fn is_unquoted_key(key : String) -> Bool {
  fn is_lower_alpha_ascii(ch : Char) -> Bool {
    ch >= 'a' && ch <= 'z'
  }

  fn is_upper_alpha_ascii(ch : Char) -> Bool {
    ch >= 'A' && ch <= 'Z'
  }

  fn is_numeric_ascii(ch : Char) -> Bool {
    ch >= '0' && ch <= '9'
  }

  fn is_unquoted_key_head(ch : Char) -> Bool {
    ch == '_' || is_lower_alpha_ascii(ch)
  }

  fn is_unquoted_key_tail(ch : Char) -> Bool {
    ch == '_' ||
    is_lower_alpha_ascii(ch) ||
    is_upper_alpha_ascii(ch) ||
    is_numeric_ascii(ch)
  }

  if key.is_empty() {
    false
  } else {
    let chars = key.to_array()
    let head = chars[0]
    if !is_unquoted_key_head(head) {
      false
    } else {
      for i = 1, ok = true
          i < chars.length()
          i = i + 1, ok = ok && is_unquoted_key_tail(chars[i]) {

      } else {
        ok
      }
    }
  }
}

///|
/// Escape a string as a literal (used for quoted keys and `String` values).
fn quote_string_literal(s : String) -> String {
  s.escape()
}

///|
/// Pretty-print a record field name (quoted when needed).
fn pretty_print_label(name : String) -> String {
  if is_unquoted_key(name) {
    name
  } else {
    quote_string_literal(name)
  }
}

///|
/// Render a single `Repr` node (label + rendered children) into `Content`.
fn pretty_print_repr_go(label : Repr, children : Array[Content]) -> Content {
  match label {
    UnitLit => comma_seq("(", ")", [])
    Integer(s) => {
      let needs_parens = s.length() > 0 && s.code_unit_at(0) == '-'
      no_parens(content_parens(if needs_parens { 1 } else { 0 }, [s]))
    }
    DoubleLit(x) => {
      let needs_parens = 1.0 / x < 0.0
      leaf(x, needs_parens~)
    }
    FloatLit(x) => {
      let needs_parens : Bool = (1.0 : Float) / x < (0.0 : Float)
      leaf(x, needs_parens~)
    }
    BoolLit(x) => leaf(x)
    CharLit(x) => leaf(x)
    StringLit(x) => no_parens(verbatim(quote_string_literal(x)))
    Tuple(_) => comma_seq("(", ")", children.map(x => x.no_wrap()))
    Enum(name, _) =>
      match children {
        [] => no_parens(verbatim(name))
        _ =>
          if name == "Tuple" {
            comma_seq("(", ")", children.map(x => x.no_wrap()))
          } else {
            comma_seq(name + "(", ")", children.map(x => x.no_wrap()))
          }
      }
    Array(_) => comma_seq("[", "]", children.map(x => x.no_wrap()))
    Record(_) => comma_seq("{", "}", children.map(x => x.no_wrap()))
    Opaque(name, _) =>
      if children.is_empty() {
        no_parens(surround("<", ">", verbatim(name)))
      } else {
        let body = verbatim(name + ":") +
          indent(
            "  ",
            comma_seq("", "", children.map(x => x.no_wrap())).no_wrap(),
          )
        no_parens(surround("<", ">", body))
      }
    Literal(str) => no_parens(verbatim(str))
    Map(_) => comma_seq("{", "}", children.map(x => x.no_wrap()))
    MapEntry(_, _) =>
      match children {
        [key, val] => {
          let k = key.no_wrap()
          let v = val.no_wrap()
          match v.lines {
            [] => empty_content()
            [one] =>
              no_parens(
                content_parens(1 + k.size + v.size, [
                  print_content(surround("", ": ", k)) + one,
                ]),
              )
            [first, ..] => {
              let n = v.lines.length()
              let rest = if n <= 1 { [] } else { v.lines[1:n].to_array() }
              // put the key and the first line of value on the same line
              // then keep the remaining lines of the value as-is.
              let head = print_content(surround("", ": ", k)) + first
              no_parens(content_parens(1 + k.size + v.size, [head] + rest))
            }
          }
        }
        _ => empty_content()
      }
    EnumLabeledArg(name, _) =>
      match children {
        [val] =>
          match val.lines {
            [] => empty_content()
            [first] =>
              no_parens(content_parens(1 + val.size, [name + "=" + first]))
            [first, ..] => {
              let n = val.lines.length()
              let rest = if n <= 1 { [] } else { val.lines[1:n].to_array() }
              no_parens(
                content_parens(1 + val.size, [name + "=" + first] + rest),
              )
            }
          }
        _ => empty_content()
      }
    RecordField(name, _) =>
      match children {
        [val] => {
          let label = pretty_print_label(name)
          let v = val.no_wrap()
          match v.lines {
            [] => empty_content()
            [one] => no_parens(content_parens(1 + v.size, [label + ": " + one]))
            [first, ..] => {
              let n = v.lines.length()
              let rest = if n <= 1 { [] } else { v.lines[1:n].to_array() }
              no_parens(
                content_parens(1 + v.size, [label + ": " + first] + rest),
              )
            }
          }
        }
        _ => empty_content()
      }
    Omitted => parens(verbatim("..."))
  }
}

///|
/// Render a `Repr` as `Content` with resizing decisions.
fn render_repr(threshold : Int, info : Repr) -> Content {
  let label = info.shallow()
  let children = info
    .children()
    .map(fn(child) { render_repr(threshold, child) })
  with_resizing(
    info_size(label),
    threshold,
    fn(children) { pretty_print_repr_go(label, children) },
    children,
  )
}

///|
/// Pretty-print a `Repr`.
///
/// Optional parameters:
/// - `max_depth?`: maximum expansion depth; deeper subtrees are replaced with `...`.
///   Defaults to `4` when `None`. Values `<= 0` are treated as `1`.
/// - `compact_threshold?`: compact-vs-multiline layout threshold.
///   The printer uses a heuristic “size” for nodes; when the structure is deemed
///   small enough under this threshold, it is kept on one line, otherwise it is
///   broken into multiple lines.
///   Larger values prefer single-line output. Defaults to `80` when `None`.
pub fn render(r : Repr, max_depth? : Int) -> String {
  let max_depth : Int? = match max_depth {
    Some(_) => max_depth
    None => Some(default_max_depth)
  }
  let threshold = default_threshold
  let info = prune_repr_info(max_depth, r)
  print_content(render_repr(threshold, info).no_wrap())
}

///|
/// Print a value in human-readable format to standard output.
pub fn[T : Debug] debug(x : T) -> Unit {
  println(render(x.to_repr()))
}
