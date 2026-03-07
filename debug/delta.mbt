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
/// Tree-shaped diff between two `Repr` values.
priv enum ReprDelta {
  Same(Repr, Array[ReprDelta])
  Different(Repr, Repr)
  Moved(Repr, Repr)
  Extra1(Repr)
  Extra2(Repr)
}

///|
/// Default max relative error for `DoubleLit` comparisons.
const DEFAULT_MAX_RELATIVE_ERROR : Double = 0.000000000001

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
    (UnitLit, UnitLit) => true
    (Integer(x1), Integer(y1)) => x1 == y1
    (DoubleLit(x1), DoubleLit(y1)) =>
      relative_error(x1, y1) <= max_relative_error
    (FloatLit(x1), FloatLit(y1)) => x1 == y1
    (BoolLit(x1), BoolLit(y1)) => x1 == y1
    (CharLit(x1), CharLit(y1)) => x1 == y1
    (StringLit(x1), StringLit(y1)) => x1 == y1
    (Tuple(_), Tuple(_)) => true
    (Array(_), Array(_)) => true
    (Record(_), Record(_)) => true
    (Enum(n1, _), Enum(n2, _)) => n1 == n2
    (Map(_), Map(_)) => true
    (RecordField(n1, _), RecordField(n2, _)) => n1 == n2
    (EnumLabeledArg(n1, _), EnumLabeledArg(n2, _)) => n1 == n2
    (Opaque(n1, _), Opaque(n2, _)) => n1 == n2
    (Literal(x1), Literal(y1)) => x1 == y1
    (MapEntry(_, _), MapEntry(_, _)) => true
    (Omitted, Omitted) => true
    _ => false
  }
}

///|
/// Labels that are treated as structural "containers" (may be collapsed in diffs).
fn info_is_unimportant(info : Repr) -> Bool {
  info is (MapEntry(_, _) | Tuple(_) | Array(_) | Record(_))
}

///|
priv struct ReprDiffTreeIndex {
  nodes : Array[Repr]
  children : Array[Array[Int]]
  parent : Array[Int]
}

///|
priv struct ReprActionIndex {
  updates : @hashmap.HashMap[Int, Int]
  moves : @hashmap.HashMap[Int, Int]
}

///|
priv struct ReprSiblingPair {
  src_idx : Int
  dst_idx : Int
  src_id : Int
  dst_id : Int
}

///|
let delta_none_node_id : Int = -1

///|
fn build_diff_tree_index(root : Repr) -> ReprDiffTreeIndex {
  let nodes : Array[Repr] = []
  let children : Array[Array[Int]] = []
  let parent : Array[Int] = []

  fn visit(node : Repr, parent_id : Int) -> Int {
    let node_id = nodes.length()
    nodes.push(node)
    children.push([])
    parent.push(parent_id)
    for child in node.children() {
      let child_id = visit(child, node_id)
      children[node_id].push(child_id)
    }
    node_id
  }

  ignore(visit(root, delta_none_node_id))
  { nodes, children, parent }
}

///|
fn build_mapping_arrays(
  src_count : Int,
  dst_count : Int,
  pairs : Array[(Int, Int)],
) -> (Array[Int], Array[Int]) {
  let src_to_dst = Array::makei(src_count, _ => delta_none_node_id)
  let dst_to_src = Array::makei(dst_count, _ => delta_none_node_id)
  for pair in pairs {
    let (src_id, dst_id) = pair
    if src_id >= 0 && src_id < src_count && dst_id >= 0 && dst_id < dst_count {
      src_to_dst[src_id] = dst_id
      dst_to_src[dst_id] = src_id
    }
  }
  (src_to_dst, dst_to_src)
}

///|
fn build_action_index(actions : Array[ReprEditAction]) -> ReprActionIndex {
  let updates : @hashmap.HashMap[Int, Int] = @hashmap.new()
  let moves : @hashmap.HashMap[Int, Int] = @hashmap.new()
  for action in actions {
    match action {
      Update(src_id, dst_id) => updates.set(src_id, dst_id)
      Move(src_id, dst_id) => moves.set(src_id, dst_id)
      Insert(_) | Delete(_) => ()
    }
  }
  { updates, moves }
}

///|
fn repr_edit_action_to_delta(
  action : ReprEditAction,
  src_nodes : Array[Repr],
  dst_nodes : Array[Repr],
) -> ReprDelta {
  match action {
    Insert(dst_id) =>
      if dst_id >= 0 && dst_id < dst_nodes.length() {
        Extra2(dst_nodes[dst_id])
      } else {
        Extra2(Repr::omitted())
      }
    Delete(src_id) =>
      if src_id >= 0 && src_id < src_nodes.length() {
        Extra1(src_nodes[src_id])
      } else {
        Extra1(Repr::omitted())
      }
    Update(src_id, dst_id) => {
      let left = if src_id >= 0 && src_id < src_nodes.length() {
        src_nodes[src_id]
      } else {
        Repr::omitted()
      }
      let right = if dst_id >= 0 && dst_id < dst_nodes.length() {
        dst_nodes[dst_id]
      } else {
        Repr::omitted()
      }
      Different(left, right)
    }
    Move(src_id, dst_id) => {
      let left = if src_id >= 0 && src_id < src_nodes.length() {
        src_nodes[src_id]
      } else {
        Repr::omitted()
      }
      let right = if dst_id >= 0 && dst_id < dst_nodes.length() {
        dst_nodes[dst_id]
      } else {
        Repr::omitted()
      }
      Moved(left, right)
    }
  }
}

///|
fn action_has_pair(
  index : @hashmap.HashMap[Int, Int],
  src_id : Int,
  dst_id : Int,
) -> Bool {
  match index.get(src_id) {
    Some(mapped_dst) => mapped_dst == dst_id
    None => false
  }
}

///|
/// Longest increasing subsequence on destination indices.
///
/// Input pairs are in source order; LIS on `dst_idx` gives an order-preserving
/// anchor set. Non-anchor mapped siblings are then treated as reorder/move in
/// surrounding segments.
///
/// Complexity: `O(n^2)` (sufficient for debug-scale sibling lists).
fn longest_increasing_dst_pairs(
  pairs : Array[ReprSiblingPair],
) -> Array[ReprSiblingPair] {
  if pairs.is_empty() {
    return []
  }
  let n = pairs.length()
  let dp = Array::makei(n, _ => 1)
  let prev = Array::makei(n, _ => -1)
  let mut best_idx = 0
  for i in 0..<n {
    for j in 0..<i {
      if pairs[j].dst_idx < pairs[i].dst_idx && dp[j] + 1 > dp[i] {
        dp[i] = dp[j] + 1
        prev[i] = j
      }
    }
    if dp[i] > dp[best_idx] {
      best_idx = i
    }
  }
  let anchor_indices : Array[Int] = []
  let mut cursor = best_idx
  while cursor != -1 {
    anchor_indices.push(cursor)
    cursor = prev[cursor]
  }
  let anchors : Array[ReprSiblingPair] = []
  while anchor_indices.pop() is Some(idx) {
    anchors.push(pairs[idx])
  }
  anchors
}

///|
/// Reconstruct a tree-shaped diff from matcher mapping + edit actions.
///
/// Design:
/// - Mapping provides structural correspondence.
/// - Action index provides explicit UPDATE/MOVE hints.
/// - Sibling ordering is reconstructed by anchor alignment:
///   1) keep mapped in-parent pairs
///   2) compute order-preserving anchors via LIS
///   3) emit gaps as delete/insert/move segments
///   4) recurse on anchors
///
/// This produces a stable, human-oriented delta tree rather than a minimal
/// machine patch script.
fn repr_edit_script_to_delta(
  left : Repr,
  right : Repr,
  pairs : Array[(Int, Int)],
  actions : Array[ReprEditAction],
  max_relative_error~ : Double,
) -> ReprDelta {
  let src_tree = build_diff_tree_index(left)
  let dst_tree = build_diff_tree_index(right)
  let (src_to_dst, dst_to_src) = build_mapping_arrays(
    src_tree.nodes.length(),
    dst_tree.nodes.length(),
    pairs,
  )
  let action_index = build_action_index(actions)

  fn go(src_id : Int, dst_id : Int) -> ReprDelta {
    let left_node = src_tree.nodes[src_id]
    let right_node = dst_tree.nodes[dst_id]

    if !info_approx_eq(max_relative_error, left_node, right_node) {
      // Prefer explicit action classification when available, otherwise fall back
      // to generic Different.
      if action_has_pair(action_index.moves, src_id, dst_id) {
        return repr_edit_action_to_delta(
          Move(src_id, dst_id),
          src_tree.nodes,
          dst_tree.nodes,
        )
      }
      if action_has_pair(action_index.updates, src_id, dst_id) {
        return repr_edit_action_to_delta(
          Update(src_id, dst_id),
          src_tree.nodes,
          dst_tree.nodes,
        )
      }
      return Different(left_node, right_node)
    }

    let children_delta : Array[ReprDelta] = []
    let src_children = src_tree.children[src_id]
    let dst_children = dst_tree.children[dst_id]
    let dst_index : @hashmap.HashMap[Int, Int] = @hashmap.new()
    for j in 0..<dst_children.length() {
      dst_index.set(dst_children[j], j)
    }
    let in_parent_pairs : Array[ReprSiblingPair] = []
    for i in 0..<src_children.length() {
      let src_child = src_children[i]
      let mapped_dst = src_to_dst[src_child]
      if mapped_dst != delta_none_node_id &&
        dst_tree.parent[mapped_dst] == dst_id {
        match dst_index.get(mapped_dst) {
          Some(j) =>
            in_parent_pairs.push({
              src_idx: i,
              dst_idx: j,
              src_id: src_child,
              dst_id: mapped_dst,
            })
          None => ()
        }
      }
    }
    // Anchors preserve relative sibling order under the same parent.
    let anchors = longest_increasing_dst_pairs(in_parent_pairs)

    fn emit_segment(
      src_begin : Int,
      src_end : Int,
      dst_begin : Int,
      dst_end : Int,
    ) -> Unit {
      // Left-side children in the gap become DELETE or MOVE.
      for i in src_begin..<src_end {
        let src_child = src_children[i]
        let mapped_dst = src_to_dst[src_child]
        if mapped_dst == delta_none_node_id {
          children_delta.push(
            repr_edit_action_to_delta(
              Delete(src_child),
              src_tree.nodes,
              dst_tree.nodes,
            ),
          )
        } else if dst_tree.parent[mapped_dst] != dst_id {
          children_delta.push(
            repr_edit_action_to_delta(
              Move(src_child, mapped_dst),
              src_tree.nodes,
              dst_tree.nodes,
            ),
          )
        } else {
          // Mapped under same parent but outside anchors => sibling reorder.
          children_delta.push(
            repr_edit_action_to_delta(
              Move(src_child, mapped_dst),
              src_tree.nodes,
              dst_tree.nodes,
            ),
          )
        }
      }
      // Right-side unmatched children in the gap become INSERT.
      for j in dst_begin..<dst_end {
        let dst_child = dst_children[j]
        if dst_to_src[dst_child] == delta_none_node_id {
          children_delta.push(
            repr_edit_action_to_delta(
              Insert(dst_child),
              src_tree.nodes,
              dst_tree.nodes,
            ),
          )
        }
      }
    }

    let mut prev_src = 0
    let mut prev_dst = 0
    for anchor in anchors {
      emit_segment(prev_src, anchor.src_idx, prev_dst, anchor.dst_idx)
      children_delta.push(go(anchor.src_id, anchor.dst_id))
      prev_src = anchor.src_idx + 1
      prev_dst = anchor.dst_idx + 1
    }
    emit_segment(
      prev_src,
      src_children.length(),
      prev_dst,
      dst_children.length(),
    )

    if children_delta.is_empty() &&
      action_has_pair(action_index.moves, src_id, dst_id) {
      repr_edit_action_to_delta(
        Move(src_id, dst_id),
        src_tree.nodes,
        dst_tree.nodes,
      )
    } else if info_is_unimportant(left_node) &&
      !children_delta.is_empty() &&
      children_delta.all(d => !(d is Same(_, _))) {
      // Collapse "purely changed" container nodes into one Different for a
      // shorter and usually clearer diff.
      Different(left_node, right_node)
    } else {
      Same(left_node.shallow(), children_delta)
    }
  }

  if src_tree.nodes.is_empty() || dst_tree.nodes.is_empty() {
    return Different(left, right)
  }
  let mapped_root = src_to_dst[0]
  // Prefer root-to-root. If source root maps elsewhere, we still render from
  // that mapped root so users can inspect matched structure.
  if mapped_root == 0 {
    go(0, 0)
  } else if mapped_root != delta_none_node_id {
    go(0, mapped_root)
  } else {
    Different(left, right)
  }
}

///|
/// Core `Repr` diff: returns a `ReprDelta` describing differences.
fn diff_info_with(
  left : Repr,
  right : Repr,
  max_relative_error~ : Double,
) -> ReprDelta {
  let match_result = repr_match(left, right)
  let actions = repr_edit_script(left, right)
  repr_edit_script_to_delta(
    left,
    right,
    match_result.mapping,
    actions,
    max_relative_error~,
  )
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
  max_relative_error? : Double = DEFAULT_MAX_RELATIVE_ERROR,
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
    if d <= 0 {
      match node {
        Same(label, children) =>
          if children.is_empty() {
            node
          } else if !label.info_adds_depth() {
            Same(label, children.map(fn(child) { go(d, child) }))
          } else {
            Same(Repr::omitted(), [])
          }
        Different(_, _) | Moved(_, _) | Extra1(_) | Extra2(_) =>
          Same(Repr::omitted(), [])
      }
    } else {
      match node {
        Same(label, children) => {
          let next_depth = if label.info_adds_depth() { d - 1 } else { d }
          Same(label, children.map(fn(child) { go(next_depth, child) }))
        }
        Different(left, right) =>
          Different(prune_info(left, depth=d), prune_info(right, depth=d))
        Moved(left, right) =>
          Moved(prune_info(left, depth=d), prune_info(right, depth=d))
        Extra1(x) => Extra1(prune_info(x, depth=d))
        Extra2(x) => Extra2(prune_info(x, depth=d))
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
const ANSI_RESET : String = "\u001b[0m"

///|
/// ANSI escape for red.
const ANSI_RED : String = "\u001b[31m"

///|
/// ANSI escape for green.
const ANSI_GREEN : String = "\u001b[32m"

///|
/// Mark removed content with `-` (and optionally ANSI color).
fn mark_removed(use_ansi : Bool, x : ContentParens) -> ContentParens {
  if use_ansi {
    surround(ANSI_RED + "-", ANSI_RESET, x)
  } else {
    surround("-", "", x)
  }
}

///|
/// Mark added content with `+` (and optionally ANSI color).
fn mark_added(use_ansi : Bool, x : ContentParens) -> ContentParens {
  if use_ansi {
    surround(ANSI_GREEN + "+", ANSI_RESET, x)
  } else {
    surround("+", "", x)
  }
}

///|
/// Mark moved content with `~` (and optionally ANSI color).
fn mark_moved(use_ansi : Bool, x : ContentParens) -> ContentParens {
  if use_ansi {
    surround("\u001b[36m~", ANSI_RESET, x)
  } else {
    surround("~", "", x)
  }
}

///|
/// Render a `ReprDelta` as `Content` with resizing decisions.
fn render_delta(threshold : Int, use_ansi : Bool, delta : ReprDelta) -> Content {
  match delta {
    Same(label, children_delta) => {
      let children = children_delta.map(child => {
        render_delta(threshold, use_ansi, child)
      })
      with_resizing(
        delta_root_size(delta),
        threshold,
        pretty_print_repr_go(label, children),
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
        match children {
          [left, right] =>
            no_parens(
              mark_removed(use_ansi, left.no_wrap()) +
              mark_added(use_ansi, right.no_wrap()),
            )
          _ => empty_content()
        },
      )
    }
    Moved(left, right) => {
      let children : Array[Content] = [
        render_repr(threshold, left),
        render_repr(threshold, right),
      ]
      with_resizing(
        0,
        threshold,
        match children {
          [left, right] => {
            let rendered = print_content(
              mark_moved(use_ansi, left.no_wrap()) +
              surround(" -> ", "", right.no_wrap()),
            )
            no_parens(verbatim(rendered))
          }
          _ => empty_content()
        },
      )
    }
    Extra1(x) => {
      let children : Array[Content] = [render_repr(threshold, x)]
      with_resizing(
        0,
        threshold,
        match children {
          [x] => no_parens(mark_removed(use_ansi, x.no_wrap()))
          _ => empty_content()
        },
      )
    }
    Extra2(x) => {
      let children : Array[Content] = [render_repr(threshold, x)]
      with_resizing(
        0,
        threshold,
        match children {
          [x] => no_parens(mark_added(use_ansi, x.no_wrap()))
          _ => empty_content()
        },
      )
    }
  }
}
