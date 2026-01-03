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
fn[A : Leb128] @buffer.Buffer::test_leb128(self : Self, x : A) -> Unit {
  self.reset()
  self.write_leb128(x)
}

///|
test "write_leb128 Int" {
  let buffer = @buffer.new()
  buffer.test_leb128(0)
  inspect(
    buffer.to_bytes(),
    content=(
      #|b"\x00"
    ),
  )
  buffer.test_leb128(-1)
  inspect(
    buffer.to_bytes(),
    content=(
      #|b"\x7f"
    ),
  )
  buffer.test_leb128(-64)
  inspect(
    buffer.to_bytes(),
    content=(
      #|b"@"
    ),
  )
  buffer.test_leb128(@int.min_value)
  inspect(
    buffer.to_bytes(),
    content=(
      #|b"\x80\x80\x80\x80x"
    ),
  )
  buffer.test_leb128(128)
  assert_eq(buffer.to_bytes(), b"\x80\x01")
  buffer.test_leb128(129)
  assert_eq(buffer.to_bytes(), b"\x81\x01")
  buffer.test_leb128(16383)
  assert_eq(buffer.to_bytes(), b"\xff\xff\x00")
  buffer.test_leb128(16384)
  assert_eq(buffer.to_bytes(), b"\x80\x80\x01")
  buffer.test_leb128(2097151)
  assert_eq(buffer.to_bytes(), b"\xff\xff\xff\x00")
}

///|
test "write_leb128 Int64" {
  let buffer = @buffer.new()
  buffer.write_leb128(0L)
  assert_eq(buffer.to_bytes(), b"\x00")
  buffer.reset()
  buffer.write_leb128(127L)
  assert_eq(buffer.to_bytes(), b"\xff\x00")
  buffer.reset()
  buffer.write_leb128(128L)
  assert_eq(buffer.to_bytes(), b"\x80\x01")
  buffer.reset()
  buffer.write_leb128(129L)
  assert_eq(buffer.to_bytes(), b"\x81\x01")
  buffer.reset()
  buffer.write_leb128(16383L)
  assert_eq(buffer.to_bytes(), b"\xff\xff\x00")
  buffer.reset()
  buffer.write_leb128(16384L)
  assert_eq(buffer.to_bytes(), b"\x80\x80\x01")
  buffer.reset()
  buffer.write_leb128(2097151L)
  assert_eq(buffer.to_bytes(), b"\xff\xff\xff\x00")
}

///|
test "write_leb128 UInt" {
  let buffer = @buffer.new()
  // Test zero
  buffer.write_leb128(0U)
  assert_eq(buffer.to_bytes(), b"\x00")
  buffer.reset()

  // Test single byte values (0-127)
  buffer.write_leb128(1U)
  assert_eq(buffer.to_bytes(), b"\x01")
  buffer.reset()
  buffer.write_leb128(127U)
  assert_eq(buffer.to_bytes(), b"\x7f")
  buffer.reset()

  // Test two byte values (128-16383)
  buffer.write_leb128(128U)
  assert_eq(buffer.to_bytes(), b"\x80\x01")
  buffer.reset()
  buffer.write_leb128(129U)
  assert_eq(buffer.to_bytes(), b"\x81\x01")
  buffer.reset()
  buffer.write_leb128(16383U)
  assert_eq(buffer.to_bytes(), b"\xff\x7f")
  buffer.reset()

  // Test three byte values (16384-2097151)
  buffer.write_leb128(16384U)
  assert_eq(buffer.to_bytes(), b"\x80\x80\x01")
  buffer.reset()
  buffer.write_leb128(2097151U)
  assert_eq(buffer.to_bytes(), b"\xff\xff\x7f")
  buffer.reset()

  // Test four byte values (2097152-268435455)
  buffer.write_leb128(2097152U)
  assert_eq(buffer.to_bytes(), b"\x80\x80\x80\x01")
  buffer.reset()
  buffer.write_leb128(268435455U)
  assert_eq(buffer.to_bytes(), b"\xff\xff\xff\x7f")
  buffer.reset()

  // Test five byte values (268435456+)
  buffer.write_leb128(268435456U)
  assert_eq(buffer.to_bytes(), b"\x80\x80\x80\x80\x01")
  buffer.reset()
}

///|
test "write_leb128_edge_cases" {
  let buffer = @buffer.new()

  // Test boundary values for each byte length
  buffer.write_leb128(0U)
  assert_eq(buffer.to_bytes(), b"\x00")
  buffer.reset()
  buffer.write_leb128(0x7fU) // 127 (max 1 byte)
  assert_eq(buffer.to_bytes(), b"\x7f")
  buffer.reset()
  buffer.write_leb128(0x80U) // 128 (min 2 byte)
  assert_eq(buffer.to_bytes(), b"\x80\x01")
  buffer.reset()
  buffer.write_leb128(0x3fffU) // 16383 (max 2 byte)
  assert_eq(buffer.to_bytes(), b"\xff\x7f")
  buffer.reset()
  buffer.write_leb128(0x4000U) // 16384 (min 3 byte)
  assert_eq(buffer.to_bytes(), b"\x80\x80\x01")
  buffer.reset()
  buffer.write_leb128(0x1fffffU) // 2097151 (max 3 byte)
  assert_eq(buffer.to_bytes(), b"\xff\xff\x7f")
  buffer.reset()
  buffer.write_leb128(0x200000U) // 2097152 (min 4 byte)
  assert_eq(buffer.to_bytes(), b"\x80\x80\x80\x01")
  buffer.reset()
  buffer.write_leb128(0xfffffffU) // 268435455 (max 4 byte)
  assert_eq(buffer.to_bytes(), b"\xff\xff\xff\x7f")
  buffer.reset()
  buffer.write_leb128(0x10000000U) // 268435456 (min 5 byte)
  assert_eq(buffer.to_bytes(), b"\x80\x80\x80\x80\x01")
  buffer.reset()
}

///|
test "write_leb128_consecutive_writes" {
  let buffer = @buffer.new()

  // Test writing multiple values consecutively
  buffer.write_leb128(1U)
  buffer.write_leb128(127U)
  buffer.write_leb128(128U)
  buffer.write_leb128(16384U)
  let expected = b"\x01\x7f\x80\x01\x80\x80\x01"
  assert_eq(buffer.to_bytes(), expected)
}

///|
test "write_leb128_negative_values" {
  let buffer = @buffer.new()

  // Test negative values for SLEB128
  buffer.write_leb128(-1)
  assert_eq(buffer.to_bytes(), b"\x7f")
  buffer.reset()
  buffer.write_leb128(-64)
  assert_eq(buffer.to_bytes(), b"\x40")
  buffer.reset()
  buffer.write_leb128(-65)
  assert_eq(buffer.to_bytes(), b"\xbf\x7f")
  buffer.reset()
  buffer.write_leb128(-128)
  assert_eq(buffer.to_bytes(), b"\x80\x7f")
  buffer.reset()
  buffer.write_leb128(-129)
  assert_eq(buffer.to_bytes(), b"\xff\x7e")
  buffer.reset()
}

///|
test "write_leb128_negative_Int64" {
  let buffer = @buffer.new()

  // Test negative Int64 values for SLEB128
  buffer.write_leb128(-1L)
  assert_eq(buffer.to_bytes(), b"\x7f")
  buffer.reset()
  buffer.write_leb128(-64L)
  assert_eq(buffer.to_bytes(), b"\x40")
  buffer.reset()
  buffer.write_leb128(-65L)
  assert_eq(buffer.to_bytes(), b"\xbf\x7f")
  buffer.reset()
  buffer.write_leb128(-128L)
  assert_eq(buffer.to_bytes(), b"\x80\x7f")
  buffer.reset()
  buffer.write_leb128(-129L)
  assert_eq(buffer.to_bytes(), b"\xff\x7e")
  buffer.reset()

  // Test large negative values
  buffer.write_leb128(-9223372036854775808L) // Int64 minimum
  assert_eq(buffer.to_bytes(), b"\x80\x80\x80\x80\x80\x80\x80\x80\x80\x7f")
  buffer.reset()
}

// Concrete counterexample: -65
// 	•	First step:
// 	•	b = (-65 & 0x7F) = 0x3F → signBit = 0
// 	•	v >>= 7 → -1
// 	•	If you stopped here using only v == -1, you’d emit just [0x3F].
// 	•	Decoder sees final byte with signBit = 0 → zero-extends → decodes to +63, not -65 ❌
// 	•	Correct behavior: because signBit == 0, you must continue:
// 	•	Emit 0x3F | 0x80 = 0xBF, then next step yields final byte 0x7F
// 	•	Correct encoding: [0xBF, 0x7F] ✅

// When v == -1 is enough

// For values whose current 7-bit chunk already has signBit == 1, e.g. -1 .. -64, stopping is correct:
// 	•	-1 → b=0x7F (signBit=1), v>>=7 → -1 → stop → [0x7F]
// 	•	-2 → b=0x7E (signBit=1) … → stop → [0x7E]
// 	•	-64 → b=0x40 (signBit=1) … → stop → [0x40]

// TL;DR
// 	•	Need both: stop when (v == -1 && signBit == 1) for negatives.
// 	•	This ensures the final byte encodes the sign, so the decoder sign-extends and you get the correct (and minimal) result.

///|
test {
  let buffer = @buffer.new()
  buffer.write_leb128(-65)
  assert_eq(buffer.to_bytes(), b"\xbf\x7f")
}

///|
test "write_leb128 UInt64" {
  let buffer = @buffer.new()
  buffer.write_leb128(0UL)
  assert_eq(buffer.to_bytes(), b"\x00")
  buffer.reset()
  buffer.write_leb128(127UL)
  assert_eq(buffer.to_bytes(), b"\x7f")
  buffer.reset()
  buffer.write_leb128(128UL)
  assert_eq(buffer.to_bytes(), b"\x80\x01")
  buffer.reset()
  buffer.write_leb128(129UL)
  assert_eq(buffer.to_bytes(), b"\x81\x01")
  buffer.reset()
  buffer.write_leb128(16383UL)
  assert_eq(buffer.to_bytes(), b"\xff\x7f")
  buffer.reset()
  buffer.write_leb128(16384UL)
  assert_eq(buffer.to_bytes(), b"\x80\x80\x01")
  buffer.reset()
  buffer.write_leb128(2097151UL)
  assert_eq(buffer.to_bytes(), b"\xff\xff\x7f")
  buffer.reset()
}

///|
test "write_leb128 UInt64 large values" {
  let buffer = @buffer.new()
  buffer.write_leb128(0xFFFFFFFFUL)
  assert_eq(buffer.to_bytes(), b"\xff\xff\xff\xff\x0f")
  buffer.reset()
  buffer.write_leb128(0x100000000UL)
  assert_eq(buffer.to_bytes(), b"\x80\x80\x80\x80\x10")
  buffer.reset()
}
