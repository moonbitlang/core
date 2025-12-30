// Copyright 2025 International Digital Economy Academy
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
/// Internal pairing heap node storing a value and links to sibling/child nodes.
priv struct Node[A] {
  content : A
  mut sibling : Node[A]?
  mut child : Node[A]?
}

///|
/// A max-heap priority queue implemented as a pairing heap.
///
/// Elements are ordered by the `Compare` trait; the greatest element is at the
/// front by default.
///
/// # Example
/// ```mbt check
/// test {
///   let pq = @priority_queue.from_array([3, 1, 2])
///   inspect(pq.peek(), content="Some(3)")
/// }
/// ```
#alias(T, deprecated="Use PriorityQueue instead")
struct PriorityQueue[A] {
  mut len : Int
  mut top : Node[A]?
}
