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
test "Tree::is_node" {
  let empty_tree : Tree[Int] = Empty
  let leaf_tree = Leaf(FixedArray::from_array([1, 2, 3]))
  let node_tree : Tree[Int] = Node(FixedArray::from_array([Empty]), None)
  inspect(empty_tree.is_node(), content="false")
  inspect(leaf_tree.is_node(), content="false")
  inspect(node_tree.is_node(), content="true")
}

///|
test "Tree::is_leaf" {
  let empty_tree : Tree[Int] = Empty
  let leaf_tree = Leaf(FixedArray::from_array([1, 2, 3]))
  let node_tree : Tree[Int] = Node(FixedArray::from_array([Empty]), None)
  inspect(empty_tree.is_leaf(), content="false")
  inspect(leaf_tree.is_leaf(), content="true")
  inspect(node_tree.is_leaf(), content="false")
}

///|
test "Tree::left_child and Tree::right_child" {
  let child1 = Leaf(FixedArray::from_array([1, 2]))
  let child2 = Leaf(FixedArray::from_array([3, 4]))
  let child3 = Leaf(FixedArray::from_array([5, 6]))
  let node_tree = Node(FixedArray::from_array([child1, child2, child3]), None)

  // left_child should return first child
  let left = node_tree.left_child()
  inspect(left.is_leaf(), content="true")

  // right_child should return last child
  let right = node_tree.right_child()
  inspect(right.is_leaf(), content="true")
}

///|
test "Tree::leaf_elements" {
  let elements = FixedArray::from_array([1, 2, 3, 4, 5])
  let leaf_tree = Leaf(elements)
  let result = leaf_tree.leaf_elements()
  inspect(result.length(), content="5")
  inspect(result[0], content="1")
  inspect(result[4], content="5")
}

///|
test "Tree::node_children" {
  let child1 = Leaf(FixedArray::from_array([1]))
  let child2 = Leaf(FixedArray::from_array([2]))
  let node_tree = Node(FixedArray::from_array([child1, child2]), None)
  let children = node_tree.node_children()
  inspect(children.length(), content="2")
  inspect(children[0].is_leaf(), content="true")
  inspect(children[1].is_leaf(), content="true")
}

///|
test "Tree::local_size" {
  let empty_tree : Tree[Int] = Empty
  let leaf_tree = Leaf(FixedArray::from_array([1, 2, 3]))
  let node_tree : Tree[Int] = Node(
    FixedArray::from_array([Empty, Empty, Empty]),
    None,
  )
  inspect(empty_tree.local_size(), content="0")
  inspect(leaf_tree.local_size(), content="3")
  inspect(node_tree.local_size(), content="3")
}

///|
test "Tree::size for Empty" {
  let empty_tree : Tree[Int] = Empty
  inspect(empty_tree.size(5), content="0")
}

///|
test "Tree::size for Leaf" {
  let leaf_tree = Leaf(FixedArray::from_array([10, 20, 30]))
  inspect(leaf_tree.size(5), content="3")
}

///|
test "Tree::size for Node with sizes" {
  let sizes = FixedArray::from_array([5, 10])
  let child1 = Leaf(FixedArray::from_array([1]))
  let child2 = Leaf(FixedArray::from_array([2]))
  let node_tree = Node(FixedArray::from_array([child1, child2]), Some(sizes))
  inspect(node_tree.size(5), content="10")
}

///|
test "Tree::size for Node without sizes" {
  let child1 = Leaf(FixedArray::from_array([1, 2]))
  let child2 = Leaf(FixedArray::from_array([3, 4, 5]))
  let node_tree = Node(FixedArray::from_array([child1, child2]), None)

  // This will compute size based on the formula
  // The calculation: (len_1 << shift) + children[len_1].size(shift - num_bits)
  // With shift=6 and num_bits=5 (typical for immutable arrays)
  let result = node_tree.size(6)
  inspect(result >= 3, content="true") // At least the size of the last leaf
}
