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

// High-level pipeline used by this file:
// 1) build two indexed trees with label/value/size/height/subtree-hash metadata
// 2) run top-down anchor matching on same-height frontiers
// 3) run map-entry key-priority refinement for `Map([MapEntry(k, v), ...])`
// 4) run bottom-up candidate search and optional local recovery
// 5) emit a simplified edit script from the final one-to-one mapping

///|
/// Minimum subtree height accepted by top-down anchor matching.
const GUMTREE_MIN_HEIGHT : Int = 1

///|
/// Minimum Dice score required by bottom-up candidate acceptance.
const GUMTREE_MIN_DICE : Double = 0.5

///|
/// Maximum subtree size allowed for local recovery on matched pairs.
const GUMTREE_MAX_SIZE : Int = 100

///|
/// Seed used by subtree hash generation.
const GUMTREE_HASH_SEED : Int = 0

///|
/// Per-bucket cap for ambiguous top-down candidate pair expansion.
const GUMTREE_TOP_DOWN_PAIR_LIMIT_PER_BUCKET : Int = 4096

///|
/// Matching result from `repr_match`.
///
/// The mapping is a set of `(src_id, dst_id)` pairs over the internal node ids
/// created by `build_repr_tree`. A node id is unique within one tree.
priv struct ReprMatchResult {
  mapping : Array[(Int, Int)]
}

///|
/// edit action generated from a node mapping.
priv enum ReprEditAction {
  Insert(Int)
  Delete(Int)
  Update(Int, Int)
  Move(Int, Int)
}

///|
/// Run GumTree-style two-phase matching and return node mapping `srcId -> dstId`.
fn repr_match(src : Repr, dst : Repr) -> ReprMatchResult {
  let (_, _, mapping) = match_repr_internal(src, dst)
  let mapping_pairs = mapping.to_array()
  { mapping: mapping_pairs }
}

///|
/// Build a simplified edit script from GumTree mapping.
///
/// Current MVP:
/// - emits UPDATE / MOVE / INSERT / DELETE
/// - MOVE is structural: parent mismatch implies move
/// - sibling reorder is represented later in `delta.mbt` by anchor/LIS alignment
fn repr_edit_script(src : Repr, dst : Repr) -> Array[ReprEditAction] {
  let (src_tree, dst_tree, mapping) = match_repr_internal(src, dst)
  build_edit_script(src_tree, dst_tree, mapping)
}

///|
let none_node_id : Int = -1

///|
priv struct ReprLabelKey {
  kind : Int
  name : String?
} derive(Hash, Eq)

///|
priv struct ReprBucketKey {
  label : ReprLabelKey
  hash : Int
} derive(Hash, Eq)

///|
priv struct ReprNodePair {
  src : Int
  dst : Int
}

///|
priv struct ReprTopDownCandidate {
  src : Int
  dst : Int
  mut score : Double
}

///|
priv struct ReprMapEntryKeySig {
  size : Int
  hash : Int
} derive(Hash, Eq)

///|
priv struct ReprMapEntryNodeInfo {
  entry_id : Int
  key_id : Int
  value_id : Int
}

///|
priv struct ReprTree {
  root : Int
  nodes : Array[Repr]
  labels : Array[ReprLabelKey]
  values : Array[String?]
  children : Array[Array[Int]]
  parent : Array[Int]
  size : Array[Int]
  height : Array[Int]
  subtree_hash : Array[Int]
  postorder : Array[Int]
  max_height : Int
}

///|
priv struct ReprHeightFrontier {
  min_height : Int
  mut max_height : Int
  buckets : Array[Array[Int]]
}

///|
priv struct ReprNodeMapping {
  src_to_dst : Array[Int]
  dst_to_src : Array[Int]
}

///|
fn repr_label_key(node : Repr) -> ReprLabelKey {
  match node {
    UnitLit => { kind: 0, name: None }
    Integer(_) => { kind: 1, name: None }
    DoubleLit(_) => { kind: 2, name: None }
    FloatLit(_) => { kind: 3, name: None }
    BoolLit(_) => { kind: 4, name: None }
    CharLit(_) => { kind: 5, name: None }
    StringLit(_) => { kind: 6, name: None }
    Tuple(_) => { kind: 7, name: None }
    Array(_) => { kind: 8, name: None }
    Record(_) => { kind: 9, name: None }
    Enum(name, _) => { kind: 10, name: Some(name) }
    Map(_) => { kind: 11, name: None }
    RecordField(name, _) => { kind: 12, name: Some(name) }
    EnumLabeledArg(label, _) => { kind: 13, name: Some(label) }
    Opaque(name, _) => { kind: 14, name: Some(name) }
    Literal(_) => { kind: 15, name: None }
    MapEntry(_, _) => { kind: 16, name: None }
    Omitted => { kind: 17, name: None }
  }
}

///|
fn repr_value_key(node : Repr) -> String? {
  match node {
    Integer(v) => Some(v)
    DoubleLit(v) => Some(v.to_string())
    FloatLit(v) => Some(v.to_string())
    BoolLit(v) => Some(v.to_string())
    CharLit(v) => Some(v.to_string())
    StringLit(v) => Some(v)
    Literal(v) => Some(v)
    _ => None
  }
}

///|
fn build_repr_tree(root_node : Repr) -> ReprTree {
  let nodes : Array[Repr] = []
  let labels : Array[ReprLabelKey] = []
  let values : Array[String?] = []
  let children : Array[Array[Int]] = []
  let parent : Array[Int] = []
  let size : Array[Int] = []
  let height : Array[Int] = []
  let subtree_hash : Array[Int] = []
  let postorder : Array[Int] = []

  fn visit(node : Repr, parent_id : Int) -> Int {
    // Node ids are assigned in pre-order DFS.
    // This guarantees each subtree occupies a contiguous id range:
    //   [node_id, node_id + size[node_id]).
    // Several downstream checks rely on this interval property.
    let node_id = nodes.length()
    nodes.push(node)
    labels.push(repr_label_key(node))
    values.push(repr_value_key(node))
    children.push([])
    parent.push(parent_id)
    size.push(1)
    height.push(1)
    subtree_hash.push(0)

    for child_node in node.children() {
      let child_id = visit(child_node, node_id)
      children[node_id].push(child_id)
    }

    let mut subtree_size = 1
    let mut subtree_height = 1
    let hasher = Hasher::new(seed=GUMTREE_HASH_SEED)

    // Merkle-style hash: local label/value + ordered child hashes.
    // Child order is intentionally preserved for sequence-sensitive nodes.
    hasher.combine(labels[node_id])
    match values[node_id] {
      Some(v) => hasher.combine(v)
      None => ()
    }
    for child_id in children[node_id] {
      subtree_size += size[child_id]
      let child_height = height[child_id] + 1
      if child_height > subtree_height {
        subtree_height = child_height
      }
      hasher.combine(subtree_hash[child_id])
    }

    size[node_id] = subtree_size
    height[node_id] = subtree_height
    subtree_hash[node_id] = hasher.finalize()
    postorder.push(node_id)
    node_id
  }

  ignore(visit(root_node, none_node_id))
  {
    root: 0,
    nodes,
    labels,
    values,
    children,
    parent,
    size,
    height,
    subtree_hash,
    postorder,
    max_height: height[0],
  }
}

///|
fn ReprTree::is_descendant(self : ReprTree, ancestor : Int, node : Int) -> Bool {
  // Relies on pre-order contiguous subtree id range produced by `build_repr_tree`.
  node >= ancestor && node < ancestor + self.size[ancestor]
}

///|
fn node_labels_equal(
  src_tree : ReprTree,
  src_id : Int,
  dst_tree : ReprTree,
  dst_id : Int,
) -> Bool {
  src_tree.labels[src_id] == dst_tree.labels[dst_id]
}

///|
fn node_values_equal(
  src_tree : ReprTree,
  src_id : Int,
  dst_tree : ReprTree,
  dst_id : Int,
) -> Bool {
  src_tree.values[src_id] == dst_tree.values[dst_id]
}

///|
fn exact_isomorphic(
  src_tree : ReprTree,
  src_id : Int,
  dst_tree : ReprTree,
  dst_id : Int,
) -> Bool {
  let stack : Array[ReprNodePair] = [{ src: src_id, dst: dst_id }]
  while stack.pop() is Some(pair) {
    if !node_labels_equal(src_tree, pair.src, dst_tree, pair.dst) {
      return false
    }
    if !node_values_equal(src_tree, pair.src, dst_tree, pair.dst) {
      return false
    }
    let src_children = src_tree.children[pair.src]
    let dst_children = dst_tree.children[pair.dst]
    if src_children.length() != dst_children.length() {
      return false
    }
    for i in 0..<src_children.length() {
      stack.push({ src: src_children[i], dst: dst_children[i] })
    }
  }
  true
}

///|
fn equal_subtree(
  src_tree : ReprTree,
  src_id : Int,
  dst_tree : ReprTree,
  dst_id : Int,
) -> Bool {
  if src_tree.size[src_id] != dst_tree.size[dst_id] {
    return false
  }
  if src_tree.subtree_hash[src_id] != dst_tree.subtree_hash[dst_id] {
    return false
  }
  exact_isomorphic(src_tree, src_id, dst_tree, dst_id)
}

///|
fn ReprHeightFrontier::new(
  tree_max_height : Int,
  min_height : Int,
) -> ReprHeightFrontier {
  let max_height = Int::max(1, tree_max_height)
  {
    min_height: Int::max(1, min_height),
    max_height,
    buckets: Array::makei(max_height + 1, _ => []),
  }
}

///|
fn ReprHeightFrontier::push(
  self : ReprHeightFrontier,
  tree : ReprTree,
  node_id : Int,
) -> Unit {
  let h = tree.height[node_id]
  if h < self.min_height {
    return ()
  }
  if h > self.max_height {
    self.max_height = h
  }
  self.buckets[h].push(node_id)
}

///|
fn ReprHeightFrontier::peek_max_height(self : ReprHeightFrontier) -> Int? {
  while self.max_height >= self.min_height &&
        self.buckets[self.max_height].is_empty() {
    self.max_height -= 1
  }
  if self.max_height < self.min_height {
    None
  } else {
    Some(self.max_height)
  }
}

///|
fn ReprHeightFrontier::pop_max_height_set(
  self : ReprHeightFrontier,
) -> Array[Int]? {
  match self.peek_max_height() {
    Some(h) => {
      let nodes = self.buckets[h]
      self.buckets[h] = []
      Some(nodes)
    }
    None => None
  }
}

///|
fn ReprHeightFrontier::open_children(
  self : ReprHeightFrontier,
  tree : ReprTree,
  node_id : Int,
) -> Unit {
  for child_id in tree.children[node_id] {
    self.push(tree, child_id)
  }
}

///|
fn ReprNodeMapping::new(
  src_node_count : Int,
  dst_node_count : Int,
) -> ReprNodeMapping {
  {
    src_to_dst: Array::makei(src_node_count, _ => none_node_id),
    dst_to_src: Array::makei(dst_node_count, _ => none_node_id),
  }
}

///|
fn ReprNodeMapping::is_mapped_src(self : ReprNodeMapping, src_id : Int) -> Bool {
  self.src_to_dst[src_id] != none_node_id
}

///|
fn ReprNodeMapping::is_mapped_dst(self : ReprNodeMapping, dst_id : Int) -> Bool {
  self.dst_to_src[dst_id] != none_node_id
}

///|
fn ReprNodeMapping::add(
  self : ReprNodeMapping,
  src_id : Int,
  dst_id : Int,
) -> Bool {
  let existing_dst = self.src_to_dst[src_id]
  let existing_src = self.dst_to_src[dst_id]
  if existing_dst == none_node_id && existing_src == none_node_id {
    self.src_to_dst[src_id] = dst_id
    self.dst_to_src[dst_id] = src_id
    true
  } else {
    existing_dst == dst_id && existing_src == src_id
  }
}

///|
fn ReprNodeMapping::remove_src(self : ReprNodeMapping, src_id : Int) -> Unit {
  let dst_id = self.src_to_dst[src_id]
  if dst_id == none_node_id {
    return ()
  }
  self.src_to_dst[src_id] = none_node_id
  if self.dst_to_src[dst_id] == src_id {
    self.dst_to_src[dst_id] = none_node_id
  }
}

///|
fn ReprNodeMapping::remove_dst(self : ReprNodeMapping, dst_id : Int) -> Unit {
  let src_id = self.dst_to_src[dst_id]
  if src_id == none_node_id {
    return ()
  }
  self.dst_to_src[dst_id] = none_node_id
  if self.src_to_dst[src_id] == dst_id {
    self.src_to_dst[src_id] = none_node_id
  }
}

///|
fn ReprNodeMapping::force_add(
  self : ReprNodeMapping,
  src_id : Int,
  dst_id : Int,
) -> Bool {
  if self.src_to_dst[src_id] == dst_id && self.dst_to_src[dst_id] == src_id {
    return true
  }
  let existing_dst = self.src_to_dst[src_id]
  if existing_dst != none_node_id {
    self.remove_src(src_id)
  }
  let existing_src = self.dst_to_src[dst_id]
  if existing_src != none_node_id {
    self.remove_dst(dst_id)
  }
  self.add(src_id, dst_id)
}

///|
fn ReprNodeMapping::to_array(self : ReprNodeMapping) -> Array[(Int, Int)] {
  let pairs : Array[(Int, Int)] = []
  for src_id in 0..<self.src_to_dst.length() {
    let dst_id = self.src_to_dst[src_id]
    if dst_id != none_node_id {
      pairs.push((src_id, dst_id))
    }
  }
  pairs
}

///|
/// Check whether two isomorphic subtree shapes can be merged into current mapping
/// without violating one-to-one constraints.
///
/// The function does not check semantic equality itself (label/value/hash). It
/// only validates compatibility with existing mapping commitments.
fn can_match_subtrees(
  src_tree : ReprTree,
  src_id : Int,
  dst_tree : ReprTree,
  dst_id : Int,
  mapping : ReprNodeMapping,
) -> Bool {
  let stack : Array[ReprNodePair] = [{ src: src_id, dst: dst_id }]
  while stack.pop() is Some(pair) {
    let existing_dst = mapping.src_to_dst[pair.src]
    if existing_dst != none_node_id && existing_dst != pair.dst {
      return false
    }
    let existing_src = mapping.dst_to_src[pair.dst]
    if existing_src != none_node_id && existing_src != pair.src {
      return false
    }
    let src_children = src_tree.children[pair.src]
    let dst_children = dst_tree.children[pair.dst]
    if src_children.length() != dst_children.length() {
      return false
    }
    for i in 0..<src_children.length() {
      stack.push({ src: src_children[i], dst: dst_children[i] })
    }
  }
  true
}

///|
/// Add a whole subtree pair into mapping (zip by child index) if it is mapping-compatible.
///
/// This is used after strong evidence (`equal_subtree`) so we can bulk-add many
/// descendants in one pass.
fn match_subtrees(
  src_tree : ReprTree,
  src_id : Int,
  dst_tree : ReprTree,
  dst_id : Int,
  mapping : ReprNodeMapping,
) -> Bool {
  if !can_match_subtrees(src_tree, src_id, dst_tree, dst_id, mapping) {
    return false
  }
  let stack : Array[ReprNodePair] = [{ src: src_id, dst: dst_id }]
  while stack.pop() is Some(pair) {
    ignore(mapping.add(pair.src, pair.dst))
    let src_children = src_tree.children[pair.src]
    let dst_children = dst_tree.children[pair.dst]
    for i in 0..<src_children.length() {
      stack.push({ src: src_children[i], dst: dst_children[i] })
    }
  }
  true
}

///|
/// Count already-mapped descendants of `src_id` that land under destination subtree `dst_id`.
///
/// This is the overlap term used by the Dice similarity.
fn common_mapped_descendants(
  src_tree : ReprTree,
  dst_tree : ReprTree,
  mapping : ReprNodeMapping,
  src_id : Int,
  dst_id : Int,
) -> Int {
  let end = src_id + src_tree.size[src_id]
  let mut count = 0
  for src_desc in src_id..<end {
    let mapped_dst = mapping.src_to_dst[src_desc]
    if mapped_dst != none_node_id && dst_tree.is_descendant(dst_id, mapped_dst) {
      count += 1
    }
  }
  count
}

///|
/// Dice similarity between candidate subtree roots based on already matched descendants.
///
/// Formula:
/// `2 * common / (|src_subtree| + |dst_subtree|)`.
/// The score is 0 when no common mapped descendants are found.
fn dice_score(
  src_tree : ReprTree,
  dst_tree : ReprTree,
  mapping : ReprNodeMapping,
  src_id : Int,
  dst_id : Int,
) -> Double {
  if src_id == none_node_id || dst_id == none_node_id {
    if src_id == dst_id {
      1.0
    } else {
      0.0
    }
  } else {
    let common = common_mapped_descendants(
      src_tree, dst_tree, mapping, src_id, dst_id,
    )
    if common == 0 {
      0.0
    } else {
      2.0 *
      common.to_double() /
      (src_tree.size[src_id] + dst_tree.size[dst_id]).to_double()
    }
  }
}

///|
/// Build hash bucket index for one source level in top-down phase.
///
/// Key = `(label, subtree_hash)`, and already mapped nodes are excluded.
fn build_bucket_index_for_src(
  nodes : Array[Int],
  tree : ReprTree,
  mapping : ReprNodeMapping,
) -> @hashmap.HashMap[ReprBucketKey, Array[Int]] {
  let index : @hashmap.HashMap[ReprBucketKey, Array[Int]] = @hashmap.new()
  for node_id in nodes {
    if mapping.is_mapped_src(node_id) {
      continue
    }
    let key = { label: tree.labels[node_id], hash: tree.subtree_hash[node_id] }
    let bucket = index.get_or_init(key, () => [])
    bucket.push(node_id)
  }
  index
}

///|
/// Build hash bucket index for one destination level in top-down phase.
fn build_bucket_index_for_dst(
  nodes : Array[Int],
  tree : ReprTree,
  mapping : ReprNodeMapping,
) -> @hashmap.HashMap[ReprBucketKey, Array[Int]] {
  let index : @hashmap.HashMap[ReprBucketKey, Array[Int]] = @hashmap.new()
  for node_id in nodes {
    if mapping.is_mapped_dst(node_id) {
      continue
    }
    let key = { label: tree.labels[node_id], hash: tree.subtree_hash[node_id] }
    let bucket = index.get_or_init(key, () => [])
    bucket.push(node_id)
  }
  index
}

///|
/// Expand ambiguous hash buckets into candidate pairs.
///
/// We apply lightweight structural filters (size and arity) and cap emitted
/// pairs with `top_down_pair_limit_per_bucket` to avoid quadratic blowups when
/// many identical subtrees exist.
fn add_ambiguous_candidates(
  src_bucket : Array[Int],
  dst_bucket : Array[Int],
  src_tree : ReprTree,
  dst_tree : ReprTree,
  candidates : Array[ReprTopDownCandidate],
  src_in_candidates : @hashset.HashSet[Int],
  dst_in_candidates : @hashset.HashSet[Int],
) -> Unit {
  let mut emitted = 0
  for src_id in src_bucket {
    for dst_id in dst_bucket {
      if src_tree.size[src_id] != dst_tree.size[dst_id] {
        continue
      }
      if src_tree.children[src_id].length() !=
        dst_tree.children[dst_id].length() {
        continue
      }
      candidates.push({ src: src_id, dst: dst_id, score: 0.0 })
      src_in_candidates.add(src_id)
      dst_in_candidates.add(dst_id)
      emitted += 1
      if emitted >= GUMTREE_TOP_DOWN_PAIR_LIMIT_PER_BUCKET {
        return ()
      }
    }
  }
}

///|
/// Rank ambiguous top-down candidates and greedily accept compatible matches.
///
/// Candidate ordering:
/// 1) higher parent-level Dice score first
/// 2) larger subtree first (tie-breaker)
fn resolve_top_down_candidates(
  src_tree : ReprTree,
  dst_tree : ReprTree,
  mapping : ReprNodeMapping,
  candidates : Array[ReprTopDownCandidate],
) -> Unit {
  for candidate in candidates {
    let src_parent = src_tree.parent[candidate.src]
    let dst_parent = dst_tree.parent[candidate.dst]
    candidate.score = dice_score(
      src_tree, dst_tree, mapping, src_parent, dst_parent,
    )
  }
  candidates.sort_by(fn(a, b) {
    if a.score > b.score {
      -1
    } else if a.score < b.score {
      1
    } else {
      let size_a = src_tree.size[a.src]
      let size_b = src_tree.size[b.src]
      if size_a > size_b {
        -1
      } else if size_a < size_b {
        1
      } else {
        0
      }
    }
  })

  for candidate in candidates {
    if mapping.is_mapped_src(candidate.src) ||
      mapping.is_mapped_dst(candidate.dst) {
      continue
    }
    if equal_subtree(src_tree, candidate.src, dst_tree, candidate.dst) {
      ignore(
        match_subtrees(
          src_tree,
          candidate.src,
          dst_tree,
          candidate.dst,
          mapping,
        ),
      )
    }
  }
}

///|
/// GumTree top-down anchor phase.
///
/// The frontier is grouped by subtree height. We repeatedly synchronize both
/// sides to the same current height, match exact buckets first, then resolve
/// ambiguous buckets with Dice scoring.
fn gumtree_top_down(
  src_tree : ReprTree,
  dst_tree : ReprTree,
  mapping : ReprNodeMapping,
) -> Unit {
  let src_frontier = ReprHeightFrontier::new(
    src_tree.max_height,
    GUMTREE_MIN_HEIGHT,
  )
  let dst_frontier = ReprHeightFrontier::new(
    dst_tree.max_height,
    GUMTREE_MIN_HEIGHT,
  )
  src_frontier.push(src_tree, src_tree.root)
  dst_frontier.push(dst_tree, dst_tree.root)

  while src_frontier.peek_max_height() is Some(src_h0) &&
        dst_frontier.peek_max_height() is Some(dst_h0) {
    let mut src_h = src_h0
    let mut dst_h = dst_h0

    while src_h > dst_h {
      // Source side is "too high": open current level and move frontier downward.
      match src_frontier.pop_max_height_set() {
        Some(nodes) =>
          nodes.each(node => src_frontier.open_children(src_tree, node))
        None => ()
      }
      match src_frontier.peek_max_height() {
        Some(next_h) => src_h = next_h
        None => return ()
      }
    }

    while dst_h > src_h {
      // Destination side is "too high": symmetric operation.
      match dst_frontier.pop_max_height_set() {
        Some(nodes) =>
          nodes.each(node => dst_frontier.open_children(dst_tree, node))
        None => ()
      }
      match dst_frontier.peek_max_height() {
        Some(next_h) => dst_h = next_h
        None => return ()
      }
    }

    let src_level = match src_frontier.pop_max_height_set() {
      Some(nodes) => nodes
      None => break
    }
    let dst_level = match dst_frontier.pop_max_height_set() {
      Some(nodes) => nodes
      None => break
    }

    let src_index = build_bucket_index_for_src(src_level, src_tree, mapping)
    let dst_index = build_bucket_index_for_dst(dst_level, dst_tree, mapping)
    let src_in_candidates : @hashset.HashSet[Int] = @hashset.new()
    let dst_in_candidates : @hashset.HashSet[Int] = @hashset.new()
    let candidates : Array[ReprTopDownCandidate] = []

    src_index.each(fn(key, src_bucket) {
      match dst_index.get(key) {
        Some(dst_bucket) =>
          if src_bucket.length() == 1 && dst_bucket.length() == 1 {
            // Unambiguous bucket: take it immediately when subtrees are exactly equal.
            let src_id = src_bucket[0]
            let dst_id = dst_bucket[0]
            if equal_subtree(src_tree, src_id, dst_tree, dst_id) {
              ignore(
                match_subtrees(src_tree, src_id, dst_tree, dst_id, mapping),
              )
            }
          } else {
            // Ambiguous bucket: defer to score-based resolution.
            add_ambiguous_candidates(
              src_bucket, dst_bucket, src_tree, dst_tree, candidates, src_in_candidates,
              dst_in_candidates,
            )
          }
        None => ()
      }
    })

    resolve_top_down_candidates(src_tree, dst_tree, mapping, candidates)

    for src_id in src_level {
      // For unmatched nodes we keep descending. Nodes seen in candidate sets are
      // postponed to avoid expanding both accepted and rejected branches early.
      if !mapping.is_mapped_src(src_id) && !src_in_candidates.contains(src_id) {
        src_frontier.open_children(src_tree, src_id)
      }
    }
    for dst_id in dst_level {
      if !mapping.is_mapped_dst(dst_id) && !dst_in_candidates.contains(dst_id) {
        dst_frontier.open_children(dst_tree, dst_id)
      }
    }
  }
}

///|
/// Return structured `(entry_id, key_id, value_id)` for a `MapEntry`.
fn map_entry_node_info(
  tree : ReprTree,
  entry_id : Int,
) -> ReprMapEntryNodeInfo? {
  if !(tree.nodes[entry_id] is MapEntry(_, _)) {
    return None
  }
  match tree.children[entry_id] {
    [key_id, value_id] => Some({ entry_id, key_id, value_id })
    _ => None
  }
}

///|
/// Signature used to bucket map entries by key shape.
fn map_entry_key_sig(tree : ReprTree, key_id : Int) -> ReprMapEntryKeySig {
  { size: tree.size[key_id], hash: tree.subtree_hash[key_id] }
}

///|
/// Check whether pairing two map keys conflicts with existing mapping.
fn map_entry_key_compatible(
  mapping : ReprNodeMapping,
  src_key_id : Int,
  dst_key_id : Int,
) -> Bool {
  let mapped_dst = mapping.src_to_dst[src_key_id]
  if mapped_dst != none_node_id && mapped_dst != dst_key_id {
    return false
  }
  let mapped_src = mapping.dst_to_src[dst_key_id]
  mapped_src == none_node_id || mapped_src == src_key_id
}

///|
/// Force-align key/value slots after matching `MapEntry` pair.
///
/// This keeps `entry -> key/value` structure coherent even when one side was
/// previously matched to a different candidate.
fn map_entry_align_slot(
  src_tree : ReprTree,
  dst_tree : ReprTree,
  mapping : ReprNodeMapping,
  src_child_id : Int,
  dst_child_id : Int,
) -> Unit {
  if !mapping.force_add(src_child_id, dst_child_id) {
    return ()
  }
  if equal_subtree(src_tree, src_child_id, dst_tree, dst_child_id) {
    ignore(
      match_subtrees(src_tree, src_child_id, dst_tree, dst_child_id, mapping),
    )
  }
}

///|
/// Refine mapping under a matched `(Map, Map)` pair by key-priority.
///
/// Rationale:
/// - Regular GumTree may over-focus on value similarity for repeated entries.
/// - Map semantics care strongly about key identity.
/// - So we first bucket by key signature, then require exact key subtree match.
fn map_entries_for_map_pair(
  src_tree : ReprTree,
  src_map_id : Int,
  dst_tree : ReprTree,
  dst_map_id : Int,
  mapping : ReprNodeMapping,
) -> Bool {
  let src_index : @hashmap.HashMap[
    ReprMapEntryKeySig,
    Array[ReprMapEntryNodeInfo],
  ] = @hashmap.new()
  let dst_index : @hashmap.HashMap[
    ReprMapEntryKeySig,
    Array[ReprMapEntryNodeInfo],
  ] = @hashmap.new()

  for src_child_id in src_tree.children[src_map_id] {
    if mapping.is_mapped_src(src_child_id) {
      continue
    }
    match map_entry_node_info(src_tree, src_child_id) {
      Some(info) => {
        let bucket = src_index.get_or_init(
          map_entry_key_sig(src_tree, info.key_id),
          () => [],
        )
        bucket.push(info)
      }
      None => ()
    }
  }

  for dst_child_id in dst_tree.children[dst_map_id] {
    if mapping.is_mapped_dst(dst_child_id) {
      continue
    }
    match map_entry_node_info(dst_tree, dst_child_id) {
      Some(info) => {
        let bucket = dst_index.get_or_init(
          map_entry_key_sig(dst_tree, info.key_id),
          () => [],
        )
        bucket.push(info)
      }
      None => ()
    }
  }

  let mut matched_any = false
  src_index.each(fn(sig, src_bucket) {
    match dst_index.get(sig) {
      Some(dst_bucket) => {
        let dst_taken = Array::makei(dst_bucket.length(), _ => false)
        for src_info in src_bucket {
          if mapping.is_mapped_src(src_info.entry_id) {
            continue
          }
          let mut picked = -1
          for j in 0..<dst_bucket.length() {
            if dst_taken[j] {
              continue
            }
            let dst_info = dst_bucket[j]
            if mapping.is_mapped_dst(dst_info.entry_id) {
              continue
            }
            if !map_entry_key_compatible(
                mapping,
                src_info.key_id,
                dst_info.key_id,
              ) {
              continue
            }
            // Enforce size/hash quick filter + exact isomorphic check on key subtree.
            if !equal_subtree(
                src_tree,
                src_info.key_id,
                dst_tree,
                dst_info.key_id,
              ) {
              continue
            }
            picked = j
            break
          }
          if picked == -1 {
            continue
          }
          let dst_info = dst_bucket[picked]
          if mapping.add(src_info.entry_id, dst_info.entry_id) {
            matched_any = true
            // Keep key/value slots aligned under matched MapEntry.
            map_entry_align_slot(
              src_tree,
              dst_tree,
              mapping,
              src_info.key_id,
              dst_info.key_id,
            )
            map_entry_align_slot(
              src_tree,
              dst_tree,
              mapping,
              src_info.value_id,
              dst_info.value_id,
            )
            dst_taken[picked] = true
          }
        }
      }
      None => ()
    }
  })

  matched_any
}

///|
/// Apply map-entry key-priority refinement to all currently matched map pairs.
fn match_map_entries_by_key_priority(
  src_tree : ReprTree,
  dst_tree : ReprTree,
  mapping : ReprNodeMapping,
) -> Unit {
  for src_id in 0..<src_tree.nodes.length() {
    let dst_id = mapping.src_to_dst[src_id]
    if dst_id == none_node_id {
      continue
    }
    if !(src_tree.nodes[src_id] is Map(_)) ||
      !(dst_tree.nodes[dst_id] is Map(_)) {
      continue
    }
    ignore(
      map_entries_for_map_pair(src_tree, src_id, dst_tree, dst_id, mapping),
    )
  }
}

///|
/// Check if a source node has at least one already matched child.
///
/// Bottom-up phase only considers nodes that have anchored evidence in their descendants.
fn has_mapped_child(
  src_tree : ReprTree,
  mapping : ReprNodeMapping,
  src_id : Int,
) -> Bool {
  for child_id in src_tree.children[src_id] {
    if mapping.is_mapped_src(child_id) {
      return true
    }
  }
  false
}

///|
/// Collect bottom-up destination candidates for `src_id`.
///
/// For each mapped descendant of `src_id`, walk up its destination ancestors and
/// count how many anchors support each unmatched ancestor with the same label.
fn collect_bottom_up_candidates(
  src_tree : ReprTree,
  dst_tree : ReprTree,
  mapping : ReprNodeMapping,
  src_id : Int,
) -> Array[(Int, Int)] {
  let counts : @hashmap.HashMap[Int, Int] = @hashmap.new()
  let end = src_id + src_tree.size[src_id]
  for src_desc in src_id..<end {
    let mapped_dst = mapping.src_to_dst[src_desc]
    if mapped_dst == none_node_id {
      continue
    }
    let mut cursor = mapped_dst
    while cursor != none_node_id {
      if !mapping.is_mapped_dst(cursor) &&
        node_labels_equal(src_tree, src_id, dst_tree, cursor) {
        let next_count = counts.get_or_default(cursor, 0) + 1
        counts.set(cursor, next_count)
      }
      cursor = dst_tree.parent[cursor]
    }
  }
  counts.to_array()
}

///|
/// Optional local recovery under a newly matched parent pair.
///
/// Current strategy (`LcsMvp`):
/// - compute LCS over child lists where equality is `equal_subtree`
/// - recursively recover aligned children
/// - greedily attach remaining children by exact subtree first, then by label
///
/// Complexity of one level is `O(src_children * dst_children)` due to LCS DP.
fn opt_recover_lcs(
  src_tree : ReprTree,
  dst_tree : ReprTree,
  src_id : Int,
  dst_id : Int,
) -> Array[ReprNodePair] {
  let recovered : Array[ReprNodePair] = []

  fn go(sid : Int, did : Int) -> Unit {
    if !node_labels_equal(src_tree, sid, dst_tree, did) {
      return ()
    }
    recovered.push({ src: sid, dst: did })

    let src_children = src_tree.children[sid]
    let dst_children = dst_tree.children[did]
    let src_len = src_children.length()
    let dst_len = dst_children.length()
    if src_len == 0 || dst_len == 0 {
      return ()
    }

    let stride = dst_len + 1
    // Flattened DP table for LCS length.
    let dp : Array[Int] = Array::makei((src_len + 1) * stride, _ => 0)

    fn at(i : Int, j : Int) -> Int {
      dp[i * stride + j]
    }

    fn set_at(i : Int, j : Int, value : Int) -> Unit {
      dp[i * stride + j] = value
    }

    for i in 1..<=src_len {
      for j in 1..<=dst_len {
        let a = src_children[i - 1]
        let b = dst_children[j - 1]
        if equal_subtree(src_tree, a, dst_tree, b) {
          set_at(i, j, at(i - 1, j - 1) + 1)
        } else {
          let top = at(i - 1, j)
          let left = at(i, j - 1)
          set_at(i, j, if top > left { top } else { left })
        }
      }
    }

    let src_used = Array::makei(src_len, _ => false)
    let dst_used = Array::makei(dst_len, _ => false)
    let lcs_pairs : Array[ReprNodePair] = []

    let mut i = src_len
    let mut j = dst_len
    while i > 0 && j > 0 {
      let a_idx = i - 1
      let b_idx = j - 1
      let a = src_children[a_idx]
      let b = dst_children[b_idx]
      if equal_subtree(src_tree, a, dst_tree, b) &&
        at(i, j) == at(i - 1, j - 1) + 1 {
        lcs_pairs.push({ src: a, dst: b })
        src_used[a_idx] = true
        dst_used[b_idx] = true
        i -= 1
        j -= 1
      } else if at(i - 1, j) >= at(i, j - 1) {
        i -= 1
      } else {
        j -= 1
      }
    }

    while lcs_pairs.pop() is Some(pair) {
      // `lcs_pairs` was collected in reverse traceback order.
      go(pair.src, pair.dst)
    }

    for si in 0..<src_len {
      if src_used[si] {
        continue
      }
      let src_child = src_children[si]
      let mut picked = none_node_id
      let mut picked_j = -1
      for dj in 0..<dst_len {
        if dst_used[dj] {
          continue
        }
        let dst_child = dst_children[dj]
        if equal_subtree(src_tree, src_child, dst_tree, dst_child) {
          picked = dst_child
          picked_j = dj
          break
        }
        if picked == none_node_id &&
          node_labels_equal(src_tree, src_child, dst_tree, dst_child) {
          picked = dst_child
          picked_j = dj
        }
      }
      if picked != none_node_id {
        src_used[si] = true
        dst_used[picked_j] = true
        go(src_child, picked)
      }
    }
  }

  go(src_id, dst_id)
  recovered
}

///|
/// Dispatch optional local recovery strategy.
fn run_opt_recovery(
  src_tree : ReprTree,
  dst_tree : ReprTree,
  src_id : Int,
  dst_id : Int,
) -> Array[ReprNodePair] {
  opt_recover_lcs(src_tree, dst_tree, src_id, dst_id)
}

///|
/// GumTree bottom-up phase.
///
/// For each unmatched internal source node (in post-order), we gather
/// destination candidates supported by already mapped descendants, pick best by
/// Dice score (+ anchor count tie-break), then optionally recover nearby pairs.
fn gumtree_bottom_up(
  src_tree : ReprTree,
  dst_tree : ReprTree,
  mapping : ReprNodeMapping,
) -> Unit {
  for src_id in src_tree.postorder {
    if src_tree.children[src_id].is_empty() {
      continue
    }
    if mapping.is_mapped_src(src_id) {
      continue
    }
    if !has_mapped_child(src_tree, mapping, src_id) {
      continue
    }

    let candidates = collect_bottom_up_candidates(
      src_tree, dst_tree, mapping, src_id,
    )
    let mut best_dst = none_node_id
    let mut best_score = 0.0
    let mut best_anchor_count = -1

    for candidate in candidates {
      let (dst_id, anchor_count) = candidate
      let score = dice_score(src_tree, dst_tree, mapping, src_id, dst_id)
      if score > best_score ||
        (score == best_score && anchor_count > best_anchor_count) {
        best_score = score
        best_dst = dst_id
        best_anchor_count = anchor_count
      }
    }

    if best_dst != none_node_id && best_score > GUMTREE_MIN_DICE {
      if mapping.add(src_id, best_dst) {
        if src_tree.size[src_id] <= GUMTREE_MAX_SIZE &&
          dst_tree.size[best_dst] <= GUMTREE_MAX_SIZE {
          // Run bounded local recovery only on moderately-sized subtrees.
          let recovered = run_opt_recovery(src_tree, dst_tree, src_id, best_dst)
          for pair in recovered {
            if !mapping.is_mapped_src(pair.src) &&
              !mapping.is_mapped_dst(pair.dst) &&
              node_labels_equal(src_tree, pair.src, dst_tree, pair.dst) {
              ignore(mapping.add(pair.src, pair.dst))
            }
          }
        }
      }
    }
  }

  // Last-resort root alignment (if still unmatched and labels agree).
  if !mapping.is_mapped_src(src_tree.root) &&
    !mapping.is_mapped_dst(dst_tree.root) &&
    node_labels_equal(src_tree, src_tree.root, dst_tree, dst_tree.root) {
    ignore(mapping.add(src_tree.root, dst_tree.root))
  }
}

///|
/// Internal matcher driver that runs all matching passes in sequence.
///
/// Pass order matters:
/// 1) top-down anchors
/// 2) map key-priority refinement
/// 3) bottom-up completion
/// 4) map key-priority refinement again (to fix late map matches)
fn match_repr_internal(
  src : Repr,
  dst : Repr,
) -> (ReprTree, ReprTree, ReprNodeMapping) {
  let src_tree = build_repr_tree(src)
  let dst_tree = build_repr_tree(dst)
  let mapping = ReprNodeMapping::new(
    src_tree.nodes.length(),
    dst_tree.nodes.length(),
  )
  gumtree_top_down(src_tree, dst_tree, mapping)
  match_map_entries_by_key_priority(src_tree, dst_tree, mapping)
  gumtree_bottom_up(src_tree, dst_tree, mapping)
  match_map_entries_by_key_priority(src_tree, dst_tree, mapping)
  (src_tree, dst_tree, mapping)
}

///|
/// Build a simplified edit script from final mapping.
///
/// Emission order:
/// 1) UPDATE / MOVE for mapped source nodes
/// 2) INSERT for unmapped destination nodes
/// 3) DELETE for unmapped source nodes (post-order for readability)
///
/// Note: move detection here is parent-based; sibling reorder is resolved during
/// delta tree reconstruction in `delta.mbt`.
fn build_edit_script(
  src_tree : ReprTree,
  dst_tree : ReprTree,
  mapping : ReprNodeMapping,
) -> Array[ReprEditAction] {
  let actions : Array[ReprEditAction] = []

  for src_id in 0..<src_tree.nodes.length() {
    let dst_id = mapping.src_to_dst[src_id]
    if dst_id == none_node_id {
      continue
    }

    if src_tree.labels[src_id] == dst_tree.labels[dst_id] &&
      src_tree.values[src_id] != dst_tree.values[dst_id] {
      actions.push(Update(src_id, dst_id))
    }

    let src_parent = src_tree.parent[src_id]
    let dst_parent = dst_tree.parent[dst_id]
    if src_parent != none_node_id && dst_parent != none_node_id {
      let mapped_parent = mapping.src_to_dst[src_parent]
      if mapped_parent != dst_parent {
        actions.push(Move(src_id, dst_id))
      }
    }
  }

  for dst_id in 0..<dst_tree.nodes.length() {
    if !mapping.is_mapped_dst(dst_id) {
      actions.push(Insert(dst_id))
    }
  }

  for src_id in src_tree.postorder {
    if !mapping.is_mapped_src(src_id) {
      actions.push(Delete(src_id))
    }
  }

  actions
}
