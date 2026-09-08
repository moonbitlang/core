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
/// The size these tests use. It has to clear the js and wasm-gc stack limits
/// (both are in the low tens of thousands of frames) while staying small
/// enough that building one candidate is cheap.
const DEEP : Int = 20000

///|
/// `removes_list` recurses once per removed block, and the recursive call sits
/// in argument position, so the whole descent runs while the iterator is being
/// built -- before it can yield anything. With `k = 1` that is one frame per
/// element.
test "removes_list builds its candidates without recursing per element" {
  let xs : @list.List[Int] = List(Array::makei(DEEP, i => i))
  guard removes_list(1, DEEP, xs).next() is Some(candidate) else {
    abort("expected a candidate")
  }
  guard candidate.length() == DEEP - 1 else {
    abort("expected \{DEEP - 1} elements, got \{candidate.length()}")
  }
}

///|
/// `removes_array` has the same shape. Its candidate order reaches `k = 1`
/// only at the end of the sequence, so a property test hits this later than it
/// hits the `List` case, but the recursion depth is the same.
test "removes_array builds its candidates without recursing per element" {
  let xs = Array::makei(DEEP, i => i)
  guard removes_array(1, DEEP, xs).next() is Some(candidate) else {
    abort("expected a candidate")
  }
  guard candidate.length() == DEEP - 1 else {
    abort("expected \{DEEP - 1} elements, got \{candidate.length()}")
  }
}

///|
/// The user-visible symptom: a property test whose counterexample is a large
/// list crashes while shrinking instead of reporting the counterexample.
test "shrinking a large list yields a candidate" {
  let xs : @list.List[Int] = List(Array::makei(DEEP, i => i))
  guard Shrink::shrink(xs).next() is Some(candidate) else {
    abort("expected a candidate")
  }
  guard candidate.length() == DEEP - 1 else {
    abort("expected \{DEEP - 1} elements, got \{candidate.length()}")
  }
}
