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

// Black-box tests covering debug-rendering paths the existing suites miss:
// the structural diff produced when `assert_eq` fails, rendering of opaque /
// empty / deeply-nested `Repr` shapes, depth-limited rendering, and the
// `Debug` instances for builtin opaque types.

///|
priv struct CovPoint {
  x : Int
  y : Double
} derive(Eq, @debug.Debug)

///|
priv enum CovShape {
  Dot
  Circle(radius~ : Int)
  Line(Int, Int)
} derive(Eq, @debug.Debug)

///|
/// Run `assert_eq` on two values and return whether it reported a difference,
/// so the diff machinery runs to completion without aborting the test. Only the
/// `Failure` raised by `assert_eq` is treated as a reported diff; anything else
/// propagates so genuine errors are not masked.
fn[T : Eq + @debug.Debug] reports_diff(a : T, b : T) -> Bool raise {
  try {
    @debug.assert_eq(a, b)
    false
  } catch {
    Failure(_) => true
    err => raise err
  }
}

///|
test "assert_eq diff over primitives with mixed equal and differing fields" {
  // doubles: relative_error / double_max (|5.0| > |3.0|)
  assert_true(reports_diff((5.0, 1), (3.0, 2)))
  // an equal double beside a differing field exercises relative_error == 0
  assert_true(reports_diff((1.5, 1), (1.5, 2)))
  // unit beside a differing field
  assert_true(reports_diff(((), 1), ((), 2)))
  // float beside a differing field
  assert_true(reports_diff(((1.0 : Float), 1), ((1.0 : Float), 2)))
  // char beside a differing field
  assert_true(reports_diff(('a', 1), ('a', 2)))
  // equal values report no difference
  let no_diff = reports_diff((1, 2), (1, 2))
  assert_true(no_diff == false)
}

///|
test "assert_eq diff over records, enums and maps" {
  let p1 : CovPoint = { x: 1, y: 2.5 }
  let p2 : CovPoint = { x: 1, y: 4.5 }
  assert_true(reports_diff(p1, p2))
  let c1 : CovShape = Circle(radius=1)
  let c2 : CovShape = Circle(radius=2)
  assert_true(reports_diff(c1, c2))
  let l1 : CovShape = Line(1, 2)
  let l2 : CovShape = Line(1, 9)
  assert_true(reports_diff(l1, l2))
  let dot : CovShape = Dot
  assert_true(reports_diff(dot, c2))
  let m1 : Map[String, Int] = { "a": 1, "b": 2 }
  let m2 : Map[String, Int] = { "a": 1, "b": 9 }
  assert_true(reports_diff(m1, m2))
  // arrays of differing length, both directions
  assert_true(reports_diff([1, 2, 3], [1, 2, 3, 4]))
  assert_true(reports_diff([1, 2, 3, 4], [1, 2]))
}

///|
test "assert_eq diff over deeply nested structures collapses to one difference" {
  // every container has a single differing child, so the diff folds inward to a
  // single Different node at the root rather than a tree of Same wrappers
  assert_true(reports_diff([[[[[[1]]]]]], [[[[[[2]]]]]]))
  let c = Some(Some(Some(Some(Some(Some(1))))))
  let d = Some(Some(Some(Some(Some(Some(2))))))
  assert_true(reports_diff(c, d))
}

///|
test "render of empty, single and nested collections" {
  let empty_arr : Array[Int] = []
  inspect(
    @debug.to_string(empty_arr),
    content=(
      #|[]
    ),
  )
  let empty_map : Map[String, Int] = {}
  inspect(
    @debug.to_string(empty_map),
    content=(
      #|{}
    ),
  )
  let one : Map[String, Int] = { "k": 1 }
  inspect(
    @debug.to_string(one),
    content=(
      #|{ "k": 1 }
    ),
  )
  let empty_inner : Map[Int, Int] = {}
  inspect(
    @debug.to_string((empty_arr, empty_inner)),
    content=(
      #|([], {})
    ),
  )
}

///|
test "render of large structures breaks into multiple lines" {
  let big = Array::makei(40, i => i)
  assert_true(@debug.to_string(big).contains("\n"))
  let nested = Array::makei(8, i => Array::makei(8, j => i * 8 + j))
  assert_true(@debug.to_string(nested).contains("\n"))
  let big_map : Map[Int, Array[Int]] = {}
  for i in 0..<12 {
    big_map[i] = Array::makei(6, j => i * 6 + j)
  }
  assert_true(@debug.to_string(big_map).contains("\n"))
}

///|
test "render of opaque builtin types" {
  let fa : FixedArray[Int] = [1, 2, 3]
  inspect(
    @debug.to_string(fa),
    content=(
      #|<FixedArray: [1, 2, 3]>
    ),
  )
  inspect(
    @debug.to_string(b"ab"),
    content=(
      #|<Bytes: [0x61, 0x62]>
    ),
  )
  // Opaque with an omitted body renders as just the tag
  inspect(
    @debug.to_string(Hasher()),
    content=(
      #|<Hasher: ...>
    ),
  )
}

///|
test "depth-limited render replaces deep subtrees with ellipsis" {
  let nested = [[[[[1, 2]]]]]
  assert_true(@debug.render(@debug.to_repr(nested)).contains("1"))
  assert_true(
    @debug.render(@debug.to_repr(nested), max_depth=1).contains("..."),
  )
  // a depth-limited record still renders its (pruned) fields
  let p : CovPoint = { x: 7, y: 8.0 }
  assert_true(@debug.render(@debug.to_repr(p), max_depth=1).length() > 0)
  // depth <= 0 is treated as 1, so max_depth=0 renders identically to max_depth=1
  let r = @debug.to_repr(nested)
  @debug.assert_eq(@debug.render(r, max_depth=0), @debug.render(r, max_depth=1))
}

///|
test "debug runs over representative values (smoke)" {
  // `@debug.debug` only prints to stdout; this is a coverage/smoke check that it
  // executes for primitive, collection and record values without raising.
  @debug.debug(42)
  @debug.debug([1, 2, 3])
  let p : CovPoint = { x: 1, y: 2.0 }
  @debug.debug(p)
}

///|
test "Debug instance for Iter renders an omitted body" {
  let it : Iter[Int] = [1, 2, 3].iter()
  inspect(
    @debug.to_string(it),
    content=(
      #|<Iter: ...>
    ),
  )
}

///|
test "assert_eq diff over opaque wrappers compares by tag" {
  // FixedArray renders as Opaque("FixedArray", ...); diffing two of them
  // exercises the Opaque-vs-Opaque label comparison.
  let a : FixedArray[Int] = [1, 2, 3]
  let b : FixedArray[Int] = [1, 9, 3]
  assert_true(reports_diff(a, b))
}
