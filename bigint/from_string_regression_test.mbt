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

// Regression tests for moonbitlang/core#4345: on wasm-gc,
// `from_string_dec` sized its limb array with `len / 0.302` bits, below
// the log2(10) ≈ 3.32193 bits a decimal digit can need, and dropped the
// carry out of the last limb. Runs of nines were first misparsed at 3150
// digits, intermittently up to 5982 digits, and at every length from 5983
// on. The other backends were already correct.

///|
/// Returns 10^n - 1 built by multiplication, independent of `from_string`.
fn nines(n : Int) -> @bigint.BigInt {
  let mut acc = 1N
  for _ in 0..<n {
    acc = acc * 10N
  }
  acc - 1N
}

///|
test "from_string parses long runs of nines exactly" {
  // lengths around the old failure pattern: 3150, 3179, 3584 and 3998
  // failed while 3149, 3151 and 3997 did not; every length from 5983 failed
  for n in [3149, 3150, 3151, 3179, 3584, 3997, 3998, 4096, 5982, 5983, 8192] {
    let digits = "9".repeat(n)
    let expected = nines(n)
    let parsed = @bigint.BigInt::from_string(digits)
    assert_eq(parsed, expected)
    assert_eq(parsed.to_string(), digits)
    assert_eq(@bigint.BigInt::from_string("-" + digits), -expected)
  }
}

///|
test "from_string parses long decimal strings of other digits exactly" {
  let n = 4000
  let sevens = nines(n) / 9N * 7N
  assert_eq(@bigint.BigInt::from_string("7".repeat(n)), sevens)
  // a non-repeating pattern round-trips through to_string
  let buf = StringBuilder()
  for i in 0..<6007 {
    buf.write_char(Int::unsafe_to_char('0' + (i * 7 + i / 13) % 10))
  }
  let digits = "1" + buf.to_string()
  assert_eq(@bigint.BigInt::from_string(digits).to_string(), digits)
}

///|
test "parse_bigint agrees with from_string on long inputs" {
  let digits = "9".repeat(6000)
  assert_eq(@bigint.parse_bigint(digits), nines(6000))
}

///|
test "from_string handles every chunk length, leading zeros and signs" {
  // the parser consumes 9-digit chunks with a shorter first chunk, so cover
  // every remainder modulo 9 and several chunk counts
  for n in 1..<=200 {
    let buf = StringBuilder()
    buf.write_char('1')
    for i in 1..<n {
      buf.write_char(Int::unsafe_to_char('0' + (i * 3 + 1) % 10))
    }
    let digits = buf.to_string()
    let parsed = @bigint.BigInt::from_string(digits)
    assert_eq(parsed.to_string(), digits)
    assert_eq(@bigint.BigInt::from_string("-" + digits), -parsed)
    assert_eq(@bigint.BigInt::from_string("000" + digits), parsed)
    assert_eq(nines(n), @bigint.BigInt::from_string("9".repeat(n)))
  }
  inspect(@bigint.BigInt::from_string("0"), content="0")
  inspect(@bigint.BigInt::from_string("-0"), content="0")
  inspect(@bigint.BigInt::from_string("0".repeat(30)), content="0")
  inspect(@bigint.BigInt::from_string("-" + "0".repeat(30)), content="0")
  inspect(
    @bigint.BigInt::from_string("1000000000000000000"),
    content="1000000000000000000",
  )
  inspect(@bigint.BigInt::from_string("4294967296"), content="4294967296")
}
