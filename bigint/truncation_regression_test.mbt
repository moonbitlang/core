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

// Regression tests for moonbitlang/core#4050 — the non-js
// `to_uint`/`to_uint64` (and hence `to_int`/`to_int64`) added one
// modulus and read sign-magnitude limbs, which is wrong whenever the
// sum is still negative, i.e. for negative values with |x| > 2^32
// (resp. 2^64) — already -(2^32 + 1) was mishandled; only exact
// multiples of the modulus and scattered coincidental residues came out
// right. js was already correct via `BigInt.asUintN`.

///|
test "to_uint truncates large negatives to two's complement" {
  // the failure region starts right past one modulus:
  // x mod 2^32 for x = -(2^32 + 1) is 2^32 - 1
  inspect((-(1N << 32) - 1N).to_uint(), content="4294967295")
  // x mod 2^32 for x = -(2^33 + 5) is 2^32 - 5 (js oracle: BigInt.asUintN)
  inspect((-(1N << 33) - 5N).to_uint(), content="4294967291")
  inspect((-(1N << 34)).to_uint(), content="0")
  inspect((-(1N << 33) - 4294967295N).to_uint(), content="1")
  inspect((-(1N << 80) - 5N).to_uint(), content="4294967291")
  // reinterpretation must follow
  inspect((-(1N << 33) - 5N).to_int(), content="-5")
  // still-correct cases within one modulus
  inspect((-5N).to_uint(), content="4294967291")
  inspect((-4294967296N).to_uint(), content="0")
}

///|
test "to_uint64 truncates large negatives to two's complement" {
  // the failure region starts right past one modulus:
  // y mod 2^64 for y = -(2^64 + 1) is 2^64 - 1
  inspect((-(1N << 64) - 1N).to_uint64(), content="18446744073709551615")
  // y mod 2^64 for y = -(2^65 + 5) is 2^64 - 5
  inspect((-(1N << 65) - 5N).to_uint64(), content="18446744073709551611")
  inspect((-(1N << 66)).to_uint64(), content="0")
  inspect((-(1N << 80) - 5N).to_uint64(), content="18446744073709551611")
  inspect((-(1N << 65) - 5N).to_int64(), content="-5")
  // still-correct cases within one modulus
  inspect((-5N).to_uint64(), content="18446744073709551611")
  inspect((-(1N << 64)).to_uint64(), content="0")
}
