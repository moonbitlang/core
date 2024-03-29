// Copyright 2024 International Digital Economy Academy
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

/// Compares and returns the maximum of two values.
///
/// Returns the second argument if the comparison determines them to be equal.
///
/// # Examples
///
/// ```
/// print(@math.maximum(1, 2))  // output: 2
/// print(@math.maximum(2, 2))  // output: 2
/// ```
pub fn maximum[T : Compare](x : T, y : T) -> T {
  if x > y {
    x
  } else {
    y
  }
}

test "maximum.value" {
  @test.eq(maximum(1, 2), 2)?
  @test.eq(maximum(2, 1), 2)?
  @test.eq(maximum(2, 2), 2)?
}

test "maximum.ref" {
  let v1 = 1
  let v2 = 2
  let x1 = "v\(v1)"
  let x2 = "v\(v2)"

  // We need another value that equals to x2 by value but not reference
  let x2t = "v\(v2)"
  @test.is_not(x2, x2t).unwrap()
  @test.is(maximum(x1, x2), x2)?
  @test.is(maximum(x2, x1), x2)?
  @test.is(maximum(x2, x2t), x2t)?
  @test.is(maximum(x2t, x2), x2)?
}

/// Compares and returns the minimum of two values.
///
/// Returns the first argument if the comparison determines them to be equal.
///
/// # Examples
///
/// ```
/// print(@math.minimum(1, 2))  // output: 1
/// print(@math.minimum(2, 2))  // output: 2
/// ```
pub fn minimum[T : Compare](x : T, y : T) -> T {
  if x > y {
    y
  } else {
    x
  }
}

test "minimum.value" {
  @test.eq(minimum(1, 2), 1)?
  @test.eq(minimum(2, 1), 1)?
  @test.eq(minimum(2, 2), 2)?
}

test "minimum.ref" {
  let v1 = 1
  let v2 = 2
  let x1 = "v\(v1)"
  let x2 = "v\(v2)"

  // We need another value that equals to x2 by value but not reference
  let x2t = "v\(v2)"
  @test.is_not(x2, x2t).unwrap()
  @test.is(minimum(x1, x2), x1)?
  @test.is(minimum(x2, x1), x1)?
  @test.is(minimum(x2, x2t), x2)?
  @test.is(minimum(x2t, x2), x2t)?
}
