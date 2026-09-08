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
/// `removes_list` used to recurse once per removed block, with the recursive
/// call in argument position, so the whole descent ran while the iterator was
/// being built -- before it could yield anything. With `k = 1` that was one
/// stack frame per element, and this test overflowed the stack on js, wasm and
/// wasm-gc.
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
/// `removes_array` had the same shape and overflowed the same way. Its
/// candidate order reaches `k = 1` only at the end of the sequence, so a
/// property test would have hit this later than it hits the `List` case, but
/// the depth was the same.
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
/// The user-visible symptom this guards against: a property test whose
/// counterexample was a large list crashed while shrinking instead of
/// reporting the counterexample.
test "shrinking a large list yields a candidate" {
  let xs : @list.List[Int] = List(Array::makei(DEEP, i => i))
  guard Shrink::shrink(xs).next() is Some(candidate) else {
    abort("expected a candidate")
  }
  guard candidate.length() == DEEP - 1 else {
    abort("expected \{DEEP - 1} elements, got \{candidate.length()}")
  }
}
