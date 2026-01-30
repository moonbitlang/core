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
test "diff: arrays collapse when all children differ" {
  let x = Repr::array([Repr::integer("1"), Repr::integer("2")])
  let y = Repr::array([Repr::integer("3"), Repr::integer("4")])
  let delta = diff_repr(x, y)
  guard delta is Different(Array(_), Array(_)) else {
    fail("expected Different(Array, Array)")
  }
}

///|
test "diff: empty containers stay Same" {
  struct Empty {} derive(Debug)
  let empty : Array[Int] = []
  let delta = diff_repr(Debug::to_repr(empty), Debug::to_repr(empty))
  guard delta is Same(Array([]), []) else {
    fail("expected Same(Array([]), [])")
  }
  let empty = Empty::{  }
  let delta = diff_repr(Debug::to_repr(empty), Debug::to_repr(empty))
  guard delta is Same(Record([]), []) else {
    fail("expected Same(Array([]), [])")
  }
}

///|
test "diff: arrays keep per-element when some children same" {
  let x = Repr::array([Repr::integer("1"), Repr::integer("2")])
  let y = Repr::array([Repr::integer("1"), Repr::integer("3")])
  let delta = diff_repr(x, y)
  guard delta is Same(Array([]), [Same(Integer("1"), []), _]) else {
    fail("expected Same(Array, children...)")
  }
}

///|
test "diff: extra elements are marked" {
  let x = Repr::array([Repr::integer("1")])
  let y = Repr::array([Repr::integer("1"), Repr::integer("2")])
  let delta = diff_repr(x, y)
  guard delta is Same(Array([]), [Same(Integer("1"), []), Extra2(Integer("2"))]) else {
    fail("expected Same(Array, [Same 1, Extra2 2])")
  }
}

///|
test "diff: tolerant doubles compare same" {
  let x = Repr::double(1.0)
  let y = Repr::double(1.0 + 1.0e-13)
  let delta = diff_repr(x, y, max_relative_error=1.0e-12)
  guard delta is Same(DoubleLit(_), []) else {
    fail("expected Same(DoubleLit, [])")
  }
}

///|
test "Repr is readonly but constructible via smart ctors" {
  let info = Repr::ctor("X", [(None, Repr::integer("1"))])
  guard info is Enum("X", [Integer("1")]) else {
    fail("expected Enum(\"X\", [Integer(\"1\")])")
  }
  assert_eq(info.children().length(), 1)
  guard info.shallow() is Enum("X", []) else {
    fail("expected shallow Enum(\"X\", [])")
  }
  guard Repr::omitted() is Omitted else { fail("expected Omitted") }
}

///|
test "diff: extra elements on left are marked Extra1" {
  let x = Repr::array([Repr::integer("1"), Repr::integer("2")])
  let y = Repr::array([Repr::integer("1")])
  let delta = diff_repr(x, y)
  guard delta is Same(Array([]), [Same(Integer("1"), []), Extra1(Integer("2"))]) else {
    fail("expected Same(Array, [Same 1, Extra1 2])")
  }
}

///|
test "diff: BoolLit and Literal compare by value" {
  let b1 = Repr::bool(true)
  let b2 = Repr::bool(false)
  let delta = diff_repr(b1, b2)
  guard delta is Different(BoolLit(true), BoolLit(false)) else {
    fail("expected Different(BoolLit, BoolLit)")
  }
  let l1 = Repr::literal("X")
  let l2 = Repr::literal("Y")
  let delta = diff_repr(l1, l2)
  guard delta is Different(Literal("X"), Literal("Y")) else {
    fail("expected Different(Literal, Literal)")
  }
}

///|
test "diff: mismatched label kinds are Different" {
  let x = Repr::integer("1")
  let y = Repr::string("1")
  let delta = diff_repr(x, y)
  guard delta is Different(Integer("1"), StringLit("1")) else {
    fail("expected Different(Integer, StringLit)")
  }
}
