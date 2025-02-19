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
struct H {
  x : Int
  y : Int
} derive(@quickcheck.Arbitrary, Show)

///|
test {
  let state = @splitmix.RandomState::default()
  let size = 10
  let v : H = @quickcheck.gen(state~, size~)
  inspect!(v, content="{x: 0, y: 0}")
  let state = state.split()
  let v : H = @quickcheck.gen(state~, size~)
  inspect!(v, content="{x: -1, y: -2}")
  let state = state.split()
  let v : H = @quickcheck.gen(state~, size~)
  inspect!(v, content="{x: 7, y: 2}")
}

///|
test "gen with only size" {
  // Call gen with only size parameter to trigger default state line 
  let x : Bool = @quickcheck.gen(size=1)
  inspect!(x, content="true")
}

///|
test "gen with default parameters" {
  // Call gen with no parameters, both size and state will be None.
  // Use Bool as the arbitrary type since it's simple.
  // Outputs will be random, but we don't care about the actual value,
  // we only need to trigger those lines.
  let x : Bool = @quickcheck.gen()
  inspect!(x, content="true")
}

///|
test "iter arbitrary" {
  let samples : Array[Iter[Int]] = samples(20)
  inspect!("[0, 0, 0, 1, 2, -2]", content="[0, 0, 0, 1, 2, -2]")
  inspect!(samples[1:5], content="[[], [0], [0], [0]]")
  // inspect!(samples[9], content="[0, 0, 0, 1, 2, -2]") (Cause infinite loop?)
  inspect!(samples[10], content="[0, 0, 0]")
}

///|
test "arbitrary unit" {
  // generate a random Unit value using the `gen` function
  let generated : Unit = gen()
  // Unit has only one value, so it must be equal to ()
  inspect!(generated, content="()")
}

///|
test "arbitrary float" {
  let state = @splitmix.new()
  let f1 : Float = gen(size=42, state~)
  let f2 : Float = gen(size=42, state~)
  // These two random floats should be different
  inspect!(f1 != f2, content="true")
}

///|
test "arbitrary_iter_break" {
  let rs = @splitmix.RandomState::default()
  let iter : Iter[Int] = gen(size=3, state=rs)
  let mut i = 0
  match
    iter.run(fn(_ : Int) -> IterResult {
      i = i + 1
      IterEnd
    }) {
    IterEnd => inspect!(i, content="1")
    IterContinue => panic()
  }
}
