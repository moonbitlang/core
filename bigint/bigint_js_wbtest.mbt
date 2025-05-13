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
fn check_invariant(_a : BigInt) -> Unit! {
  assert_true!(true)
}

///|
let zero = 0N

///|
test "BigInt::to_uint" {
  assert_eq!(BigInt::from_int64(-1L).to_uint(), (-1).reinterpret_as_uint())
}

///|
test "BigInt::to_int64" {
  assert_eq!(BigInt::from_int64(-1).to_int64(), -1L)
}

///|
test "BigInt::bit_length" {
  inspect!(0N.bit_length(), content="0")
  inspect!(1N.bit_length(), content="1")
  inspect!((-1N).bit_length(), content="0")
  inspect!(16N.bit_length(), content="5")
  inspect!((-16N).bit_length(), content="4")
  inspect!(42N.bit_length(), content="6")
  inspect!((-42N).bit_length(), content="6")
  inspect!(1024N.bit_length(), content="11")
  inspect!(10000000N.bit_length(), content="24")
  inspect!((1N << 31).bit_length(), content="32")
  inspect!((1N << 63).bit_length(), content="64")
}

///|
test "BigInt::ctz" {
  inspect!(0N.ctz(), content="0")
  inspect!(1N.ctz(), content="0")
  inspect!(8N.ctz(), content="3") // 1000
  inspect!(12N.ctz(), content="2") // 1100
  inspect!(174056N.ctz(), content="3") // 101010011111101000
  inspect!((1N << 31).ctz(), content="31")
  inspect!((1N << 63).ctz(), content="63")
}

///|
test "BigInt::random" {
  let r = @random.new()
  inspect!(BigInt::random(r, 1), content="1")
  inspect!(BigInt::random(r, 3), content="0")
  inspect!(BigInt::random(r, 7), content="15")
  inspect!(BigInt::random(r, 8), content="145")
  inspect!(BigInt::random(r, 32), content="1419217390")
  inspect!(BigInt::random(r, 40), content="6565681667")
  inspect!(BigInt::random(r, 64), content="9321953011312286805")
  inspect!(
    BigInt::random(r, 128),
    content="300285818196408820232605922593694053217",
  )

  // with limit
  inspect!(BigInt::random(r, 8, limit=32), content="17")
  inspect!(BigInt::random(r, 32, limit=10000000), content="4407241")
}
