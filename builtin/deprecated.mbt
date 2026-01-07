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
#deprecated("check `@encoding/utf8.encode`")
#coverage.skip
pub fn Bytes::of_string(str : String) -> Bytes {
  FixedArray::make(str.length() * 2, Byte::default())
  ..blit_from_string(0, str, 0, str.length())
  .unsafe_reinterpret_as_bytes()
}

///|
#deprecated("Bytes are immutable. Use `FixedArray::blit_from_bytes` if it's really necessary.")
pub fn Bytes::copy(self : Bytes) -> Bytes {
  Bytes::makei(self.length(), i => self[i])
}

///|
/// positions.
///
/// Parameters:
///
/// - `byte_value` : The `Byte` value whose bits are to be shifted.
/// - `shift_count` : The number of bit positions to shift the `byte_value` to
///   the left.
///
/// Returns the resulting `Byte` value after the bitwise left shift operation.
///
#deprecated("Use infix operator `<<` instead")
#coverage.skip
pub fn Byte::lsl(self : Byte, count : Int) -> Byte {
  (self.to_int() << count).to_byte()
}

///|
/// bits.
///
/// Parameters:
///
/// - `value` : The `Byte` value to be shifted.
/// - `count` : The number of bits to shift the `value` to the right.
///
/// Returns the result of the logical shift right operation as a `Byte`.
///
#deprecated("Use infix operator `>>` instead")
#coverage.skip
pub fn Byte::lsr(self : Byte, count : Int) -> Byte {
  (self.to_uint() >> count).reinterpret_as_int().to_byte()
}

///|
/// Prints and returns the value of a given expression for quick and dirty debugging.
/// This could also be useful to print some logs to trace the progress.
/// For example, you can put `dump(())` in each line, the execution will print the line number
/// when it reaches that line.
#callsite(autofill(loc))
#deprecated("This function is for debugging only and should not be used in production", skip_current_package=true)
pub fn[T] dump(t : T, name? : String, loc~ : SourceLoc) -> T {
  let name = match name {
    Some(name) => name
    None => ""
  }
  println("dump(\{name}@\{loc}) = \{any_to_string(t)}")
  t
}

///|
test "dump" {
  let x = 42
  if false {
    dump(()) // never reached here
    assert_eq(dump(x) + x, 84)
  }
}

///|
/// Returns the Unicode code point at the given index without bounds checking.
#deprecated("Use `s.get_char(i).unwrap()` instead", skip_current_package=true)
pub fn String::unsafe_char_at(self : String, index : Int) -> Char {
  let c1 = self.unsafe_get(index)
  if c1.is_leading_surrogate() {
    let c2 = self.unsafe_get(index + 1)
    code_point_of_surrogate_pair(c1.to_int(), c2.to_int())
  } else {
    c1.unsafe_to_char()
  }
}
