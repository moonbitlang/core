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
test " same_object call with the same object" {
  let s = "Hello"
  @test.same_object!(s, s)
}

///|
test "panic same_object call with different objects" {
  let a = "1"
  let b = "2"
  @test.same_object!(a, b)
}

///|
test "is_not called with the different objects" {
  let a = "1"
  let b = "2"
  @test.is_not!(a, b)
}

///|
test "panic is_not called with the same object" {
  let s = "Hello"
  @test.is_not!(s, s)
}

///|
test "bench: sum inside test" (it : @test.T) {
  it.bench!(
    fn() {
      let mut i = 0.0
      while i < 100000 {
        i += 1.0
      }
      ignore(i)
    },
    count=5,
  )
}

///|
test "bench: only first bench should run" (it : @test.T) {
  it.bench!(
    fn() {
      let mut i = 0.0
      while i < 10000000 {
        i += 1.0
      }
      ignore(i)
    },
    count=5,
  )
  it.bench!(fn() { panic() })
}

///|
test "monotonic clock" {
  let ts = monotonic_clock_start()
  let mut sum : Double = 0
  for i in 0..=100000 {
    sum += i.to_double()
  }
  let diff = monotonic_clock_end(ts)
  assert_false!(diff.is_nan())
  assert_true!(diff >= 0.0)
  inspect!(sum, content="5000050000")
}
