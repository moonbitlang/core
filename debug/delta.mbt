///|
/// Tree-shaped diff between two `Repr` values.
priv enum ReprDelta {
  Same(Repr, Array[ReprDelta])
  Different(Repr, Repr)
  Extra1(Repr)
  Extra2(Repr)
}

///|
/// Default max relative error for `DoubleLit` comparisons.
let default_max_relative_error : Double = 0.000000000001

///|
/// Absolute value for `Double`.
fn double_abs(x : Double) -> Double {
  if x < 0.0 {
    -x
  } else {
    x
  }
}

///|
/// Maximum of two `Double` values.
fn double_max(x : Double, y : Double) -> Double {
  if x > y {
    x
  } else {
    y
  }
}

///|
/// Relative error metric used for approximate `DoubleLit` comparisons.
fn relative_error(x : Double, y : Double) -> Double {
  if x == y {
    0.0
  } else {
    let denom = double_max(double_abs(x), double_abs(y))
    if denom == 0.0 {
      double_abs(x - y)
    } else {
      double_abs(x - y) / denom
    }
  }
}

///|
/// Compare two node "labels", with float tolerance for `DoubleLit`.
fn info_approx_eq(max_relative_error : Double, x : Repr, y : Repr) -> Bool {
  match (x, y) {
    (DoubleLit(x1), DoubleLit(y1)) =>
      relative_error(x1, y1) <= max_relative_error
    (FloatLit(x1), FloatLit(y1)) => x1 == y1
    (Integer(x1), Integer(y1)) => x1 == y1
    (BoolLit(x1), BoolLit(y1)) => x1 == y1
    (CharLit(x1), CharLit(y1)) => x1 == y1
    (StringLit(x1), StringLit(y1)) => x1 == y1
    (Literal(x1), Literal(y1)) => x1 == y1
    (Omitted, Omitted) => true
    (Tuple(_), Tuple(_)) => true
    (Array(_), Array(_)) => true
    (Record(_), Record(_)) => true
    (RecordField(n1, _), RecordField(n2, _)) => n1 == n2
    (EnumLabeledArg(n1, _), EnumLabeledArg(n2, _)) => n1 == n2
    (Enum(n1, _), Enum(n2, _)) => n1 == n2
    (Opaque(n1, _), Opaque(n2, _)) => n1 == n2
    (Map(_), Map(_)) => true
    (MapEntry(_, _), MapEntry(_, _)) => true
    _ => false
  }
}

///|
/// Labels that are treated as structural "containers" (may be collapsed in diffs).
fn info_is_unimportant(info : Repr) -> Bool {
  match info {
    MapEntry(_, _) | Tuple(_) | Array(_) | Record(_) => true
    _ => false
  }
}

///|
/// Child nodes of a `Repr` node.
fn info_children(info : Repr) -> Array[Repr] {
  info.children()
}

///|
/// A shallow copy of `info` containing only its "label" (children replaced).
fn info_shallow(info : Repr) -> Repr {
  info.shallow()
}

///|
/// Returns `true` iff `p` holds for every element.
fn[T] tree_all(xs : Array[T], p : (T) -> Bool) -> Bool {
  let mut ok = true
  for x in xs {
    if !p(x) {
      ok = false
      break
    }
  }
  ok
}

///|
/// Core `Repr` diff: returns a `ReprDelta` describing differences.
fn diff_info_with(
  left : Repr,
  right : Repr,
  max_relative_error~ : Double,
) -> ReprDelta {
  fn differing(d : ReprDelta) -> Bool {
    match d {
      Same(_, _) => false
      _ => true
    }
  }

  fn go(left_node : Repr, right_node : Repr) -> ReprDelta {
    if info_approx_eq(max_relative_error, left_node, right_node) {
      let xs = info_children(left_node)
      let ys = info_children(right_node)
      let xlen = xs.length()
      let ylen = ys.length()
      let min_len = if xlen < ylen { xlen } else { ylen }
      let children : Array[ReprDelta] = for i = 0, acc = [] {
        if i < min_len {
          continue i + 1, acc + [go(xs[i], ys[i])]
        } else {
          break acc
        }
      }
      let children = if xlen < ylen {
        children + ys[min_len:ylen].to_array().map(fn(t) { Extra2(t) })
      } else if xlen > ylen {
        children + xs[min_len:xlen].to_array().map(fn(t) { Extra1(t) })
      } else {
        children
      }
      if info_is_unimportant(left_node) && tree_all(children, differing) {
        Different(left_node, right_node)
      } else {
        Same(info_shallow(left_node), children)
      }
    } else {
      Different(left_node, right_node)
    }
  }

  go(left, right)
}

///|
/// Diff two `Repr` values.
///
/// Optional parameters:
/// - `max_relative_error?`: relative-error tolerance for `DoubleLit`.
///   - If omitted, the default is `1e-12`.
///   - Larger tolerances make doubles less likely to be reported as different.
fn diff_repr(
  x : Repr,
  y : Repr,
  max_relative_error? : Double = default_max_relative_error,
) -> ReprDelta {
  diff_info_with(x, y, max_relative_error~)
}

///|
/// Pretty-print a `ReprDelta`.
///
/// Optional parameters:
/// - `max_depth?`: maximum expansion depth; deeper subtrees are folded.
///   Defaults to `4` when omitted. Values `<= 0` are treated as `1`.
/// - `compact_threshold?`: compact-vs-multiline layout threshold (heuristic one-line vs multiline).
///   Larger values prefer single-line output. Defaults to `30` when omitted.
/// - `use_ansi?`: whether to emit ANSI color escape codes (for +/- markers).
///   Defaults to `true` when omitted.
fn pretty_print_delta(
  d : ReprDelta,
  max_depth? : Int,
  compact_threshold? : Int = default_threshold,
  use_ansi? : Bool = true,
) -> String {
  let max_depth : Int? = match max_depth {
    Some(_) => max_depth
    None => Some(default_max_depth)
  }
  let delta = prune_delta(max_depth, d)
  print_content(render_delta(compact_threshold, use_ansi, delta).no_wrap())
}

///|
/// Prune a `ReprDelta` using max_depth (replacing with `Same(Omitted, [])`).
fn prune_delta(max_depth : Int?, delta : ReprDelta) -> ReprDelta {
  fn go(d : Int, node : ReprDelta) -> ReprDelta {
    match node {
      Same(label, children) =>
        if d <= 0 {
          if children.is_empty() {
            node
          } else if !label.info_adds_depth() {
            Same(label, children.map(fn(child) { go(d, child) }))
          } else {
            Same(Repr::omitted(), [])
          }
        } else {
          let next_depth = if label.info_adds_depth() { d - 1 } else { d }
          Same(label, children.map(fn(child) { go(next_depth, child) }))
        }
      Different(left, right) =>
        if d <= 0 {
          Same(Repr::omitted(), [])
        } else {
          Different(prune_info(left, depth=d), prune_info(right, depth=d))
        }
      Extra1(x) =>
        if d <= 0 {
          Same(Repr::omitted(), [])
        } else {
          Extra1(prune_info(x, depth=d))
        }
      Extra2(x) =>
        if d <= 0 {
          Same(Repr::omitted(), [])
        } else {
          Extra2(prune_info(x, depth=d))
        }
    }
  }

  match max_depth {
    None => delta
    Some(depth) => go(Int::max(1, depth), delta)
  }
}

///|
/// Heuristic "size" of a delta for compact-vs-multiline decisions.
fn delta_root_size(delta : ReprDelta) -> Int {
  match delta {
    Same(label, _) => info_size(label)
    _ => 0
  }
}

///|
/// ANSI escape reset.
fn ansi_reset() -> String {
  "\u001b[0m"
}

///|
/// ANSI escape for red.
fn ansi_red() -> String {
  "\u001b[31m"
}

///|
/// ANSI escape for green.
fn ansi_green() -> String {
  "\u001b[32m"
}

///|
/// Mark removed content with `-` (and optionally ANSI color).
fn mark_removed(use_ansi : Bool, x : ContentParens) -> ContentParens {
  if use_ansi {
    surround(ansi_red() + "-", ansi_reset(), x)
  } else {
    surround("-", "", x)
  }
}

///|
/// Mark added content with `+` (and optionally ANSI color).
fn mark_added(use_ansi : Bool, x : ContentParens) -> ContentParens {
  if use_ansi {
    surround(ansi_green() + "+", ansi_reset(), x)
  } else {
    surround("+", "", x)
  }
}

///|
/// Render a `ReprDelta` as `Content` with resizing decisions.
fn render_delta(threshold : Int, use_ansi : Bool, delta : ReprDelta) -> Content {
  match delta {
    Same(label, children_delta) => {
      let children = children_delta.map(fn(child) {
        render_delta(threshold, use_ansi, child)
      })
      with_resizing(
        delta_root_size(delta),
        threshold,
        fn(children) { pretty_print_repr_go(label, children) },
        children,
      )
    }
    Different(left, right) => {
      let children : Array[Content] = [
        render_repr(threshold, left),
        render_repr(threshold, right),
      ]
      with_resizing(
        0,
        threshold,
        fn(children) {
          match children {
            [left, right] =>
              no_parens(
                mark_removed(use_ansi, left.no_wrap()) +
                mark_added(use_ansi, right.no_wrap()),
              )
            _ => empty_content()
          }
        },
        children,
      )
    }
    Extra1(x) => {
      let children : Array[Content] = [render_repr(threshold, x)]
      with_resizing(
        0,
        threshold,
        fn(children) {
          match children {
            [x] => no_parens(mark_removed(use_ansi, x.no_wrap()))
            _ => empty_content()
          }
        },
        children,
      )
    }
    Extra2(x) => {
      let children : Array[Content] = [render_repr(threshold, x)]
      with_resizing(
        0,
        threshold,
        fn(children) {
          match children {
            [x] => no_parens(mark_added(use_ansi, x.no_wrap()))
            _ => empty_content()
          }
        },
        children,
      )
    }
  }
}
