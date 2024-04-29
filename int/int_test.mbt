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


fn test_num[T : @num.Num + Debug + Default + Eq](
  x : T,
  y : T,
  x_plus_y : T,
  x_mul_y : T,
  x_minus_y : T,
  x_div_y : T,
  x_signum : T
) -> Result[Unit, String] {
  @assertion.assert_eq(x + y, x_plus_y)?
  @assertion.assert_eq(x * y, x_mul_y)?
  @assertion.assert_eq(x - y, x_minus_y)?
  @assertion.assert_eq(x / y, x_div_y)?
  @assertion.assert_eq(x.abs(), T::default() - x)?
  @assertion.assert_eq(x.signum(), x_signum)?
  Ok(())
}

test "int.num" {
  let x = -5
  let y = 7
  test_num(x, y, x + y, x * y, x - y, x / y, -1)?
}

test "int.into_byte_view(series)" {
  let test_bytes_eq = fn (l: Bytes, r: Bytes) -> Result[Unit, String] {
    if l.length() == r.length() {
      for i = 0; i < l.length(); i = i + 1 {
        if l[i] != r[i] {
          let (lv, rv) = (l[i], r[i])
          return Err("byte mismatch at \(i): \(lv) != \(rv)")
        }
      }
      Ok(())
    } else {
      let (ll, rl) = (l.length(), r.length())
      Err("length mismatch: \(ll) != \(rl)")
    }
  }

  let cases = [
    (
      0x07_06_05_04, 
      0, 
      Bytes::[0xcc, 0xcc, 0xcc, 0xcc, 0xcc, 0xcc],
      Bytes::[0x04, 0x05, 0x06, 0x07, 0xcc, 0xcc],
      Bytes::[0x07, 0x06, 0x05, 0x04, 0xcc, 0xcc],
    ),
    (
      0xff_0b_0c_0d, 
      1, 
      Bytes::[0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa],
      Bytes::[0xaa, 0x0d, 0x0c, 0x0b, 0xff, 0xaa], 
      Bytes::[0xaa, 0xff, 0x0b, 0x0c, 0x0d, 0xaa],
    ),
    (
      0x44_33_22_11, 
      2, 
      Bytes::[0xdf, 0xfd, 0xdf, 0xdf, 0xdf, 0xdf],
      Bytes::[0xdf, 0xfd, 0x11, 0x22, 0x33, 0x44],
      Bytes::[0xdf, 0xfd, 0x44, 0x33, 0x22, 0x11]
    ),
  ]

  for icase = 0; icase < cases.length(); icase = icase + 1 {
    let (input, pos, original, le_expected, be_expected) = cases[icase];

    let buffer = original.copy()
    let view = buffer[pos..(pos + 4)]
    input.into_byte_view(view, @representation.Endianness::LittleEndian)
    test_bytes_eq(buffer, le_expected)?
  
    let buffer = original.copy()
    let view = buffer[pos..(pos + 4)]
    input.into_byte_view(view, @representation.Endianness::BigEndian)
    test_bytes_eq(buffer, be_expected)?
  
    let buffer = original.copy()
    let view = buffer[pos..(pos + 4)]
    input.into_byte_view(view, @representation.Endianness::NetworkEndian)
    test_bytes_eq(buffer, be_expected)?
  
    let buffer = original.copy()
    let view = buffer[pos..(pos + 4)]
    input.into_byte_view_le(view)
    test_bytes_eq(buffer, le_expected)?

    let buffer = original.copy()
    let view = buffer[pos..(pos + 4)]
    input.into_byte_view_be(view)
    test_bytes_eq(buffer, be_expected)?
  }
}

test "int.from_byte_view(series)" {
  let input = Bytes::[0x7c, 0x47, 0x18, 0x49, 0xff, 0x6c]
  let cases = [
    (0, 0x49_18_47_7c, 0x7c_47_18_49), (1, 0xff_49_18_47, 0x47_18_49_ff), (2, 0x6c_ff_49_18, 0x18_49_ff_6c),
  ]
  for icase = 0; icase < cases.length(); icase = icase + 1 {
    let (pos, le_expected, be_expected) = cases[icase];
    let view = input[pos..(pos + 4)]
    
    @assertion.assert_eq(Int::from_byte_view(view, @representation.Endianness::LittleEndian), le_expected)?
    @assertion.assert_eq(Int::from_byte_view_le(view), le_expected)?
    @assertion.assert_eq(Int::from_byte_view(view, @representation.Endianness::BigEndian), be_expected)?
    @assertion.assert_eq(Int::from_byte_view(view, @representation.Endianness::NetworkEndian), be_expected)?
    @assertion.assert_eq(Int::from_byte_view_be(view), be_expected)?
  }
}
