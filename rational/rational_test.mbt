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

test "new" {
  // 1/2
  let a = @rational.new(1L, 2L)
  inspect!(a, content="Some(1/2)")

  // 1/0
  let a = @rational.new(1L, 0L)
  inspect!(a, content="None")
}

test "addition" {
  let a = @rational.new(1L, 2L).unwrap()
  let b = @rational.new(1L, 3L).unwrap()
  let result = a + b
  inspect!(result, content="5/6")
}

test "subtraction" {
  let a = @rational.new(3L, 4L).unwrap()
  let b = @rational.new(1L, 4L).unwrap()
  let result = a - b
  inspect!(result, content="1/2")
}

test "multiplication" {
  let a = @rational.new(2L, 3L).unwrap()
  let b = @rational.new(3L, 4L).unwrap()
  let result = a * b
  inspect!(result, content="1/2")
}

test "division" {
  let a = @rational.new(1L, 2L).unwrap()
  let b = @rational.new(3L, 4L).unwrap()
  let result = a / b
  inspect!(result, content="2/3")
}

test "from_double overflow" {
  let result = 10.0e200 |> @result.wrap1(f=@rational.from_double)
  assert_eq!(result, Err(RationalError("Rational::from_double: overflow")))
}

test "from_double NaN" {
  let result = Double::nan() |> @result.wrap1(f=@rational.from_double)
  assert_eq!(
    result,
    Err(RationalError("Rational::from_double: cannot convert NaN")),
  )
}

test "from_double overflow edge case" {
  let result = 9_223_372_036_854_775_807.1
    |> @result.wrap1(f=@rational.from_double)
  assert_eq!(result, Err(RationalError("Rational::from_double: overflow")))
}

test "from_double overflow edge case" {
  let result = 9_223_372_036_854_775_807.1
    |> @result.wrap1(f=@rational.from_double)
  assert_eq!(result, Err(RationalError("Rational::from_double: overflow")))
}

test "from_double overflow check in continued fraction algorithm" {
  let result = 10.0e200 |> @result.wrap1(f=@rational.from_double)
  assert_eq!(result, Err(RationalError("Rational::from_double: overflow")))
}

test "from_double NaN check" {
  let result = Double::nan() |> @result.wrap1(f=@rational.from_double)
  assert_eq!(
    result,
    Err(RationalError("Rational::from_double: cannot convert NaN")),
  )
}

// currently it requires the `content` argument to be passed int the second position
fn inspect_double_array(
  a : Array[Double],
  ~content : String = "",
  ~loc : SourceLoc = _,
  ~args_loc : ArgsLoc = _
) -> Unit! {
  inspect!(
    a.map(fn { x => @rational.from_double?(x) }),
    ~content,
    ~loc,
    ~args_loc,
  )
}

test "from_double array" {
  let a : Array[Double] = [
    0.5, 5, 29.97, -29.97, 63.5, 126.5, 127.0, 127.5, -63.5, -126.5, -127.0, -127.5,
  ]
  inspect_double_array!(
    a,
    content="[Ok(1/2), Ok(5), Ok(2997/100), Ok(-2997/100), Ok(127/2), Ok(253/2), Ok(127), Ok(255/2), Ok(-127/2), Ok(-253/2), Ok(-127), Ok(-255/2)]",
  )
  let a = [-10.0e200, 10.0e200, Double::inf(1), Double::inf(-1), Double::nan()]
  a
  |> inspect_double_array!(
    content=
      #|[Err("Rational::from_double: overflow"), Err("Rational::from_double: overflow"), Err("Rational::from_double: overflow"), Err("Rational::from_double: overflow"), Err("Rational::from_double: cannot convert NaN")]
    ,
  )
  inspect_double_array!(
    [
      2.2204460492503131e-16, 0.0, -0.0, 9_223_372_036_800_000_000.0, 9_223_372_036_854_775_807.1,
      9_223_372_036_854_775_807.0,
    ],
    content=
      #|[Ok(1/4503599627370496), Ok(0), Ok(0), Ok(9223372036800000000), Err("Rational::from_double: overflow"), Err("Rational::from_double: overflow")]
    ,
  )
  // content="[Ok(1/4503599627370496), Ok(0), Ok(0), Ok(9223372036800000000)]")
}

test "rational arbitrary" {
  let samples : Array[@rational.T] = @quickcheck.samples(20)
  inspect!(samples[1:5], content="[0, 0, 0, 1/-1]")
  inspect!(samples[5:10], content="[-1/-2, 5/-4, 1/6, 3/-1, -1/2]")
  inspect!(samples[10:15], content="[9/-4, 5/3, -2, 7/-11, -1/-4]")
}