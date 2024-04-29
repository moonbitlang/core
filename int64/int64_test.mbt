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

test "int64.num" {
  let x = -500L
  let y = 792L
  test_num(x, y, x + y, x * y, x - y, x / y, -1L)?
}

test "int64.into_byte_view(series)" {
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
      0xff_01_02_03_04_05_06_07_L, 
      0, 
      Bytes::[0xcc, 0xcc, 0xcc, 0xcc, 0xcc, 0xcc, 0xcc, 0xcc, 0xcc, 0xcc],
      Bytes::[0x07, 0x06, 0x05, 0x04, 0x03, 0x02, 0x01, 0xff, 0xcc, 0xcc],
      Bytes::[0xff, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0xcc, 0xcc],
    ),
    (
      0x01_02_03_04_05_06_07_ff_L, 
      1, 
      Bytes::[0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa],
      Bytes::[0xaa, 0xff, 0x07, 0x06, 0x05, 0x04, 0x03, 0x02, 0x01, 0xaa],
      Bytes::[0xaa, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0xff, 0xaa],
    ),
    (
      0xd3_9c_33_c7_f8_17_5d_9c_L, 
      2, 
      Bytes::[0xdf, 0xfd, 0xdf, 0xdf, 0xdf, 0xdf, 0xdf, 0xdf, 0xdf, 0xdf],
      Bytes::[0xdf, 0xfd, 0x9c, 0x5d, 0x17, 0xf8, 0xc7, 0x33, 0x9c, 0xd3],
      Bytes::[0xdf, 0xfd, 0xd3, 0x9c, 0x33, 0xc7, 0xf8, 0x17, 0x5d, 0x9c],
    ),
  ]

  for icase = 0; icase < cases.length(); icase = icase + 1 {
    let (input, pos, original, le_expected, be_expected) = cases[icase];

    let buffer = original.copy()
    let view = buffer[pos..(pos + 8)]
    input.into_byte_view(view, @representation.Endianness::LittleEndian)
    test_bytes_eq(buffer, le_expected)?
  
    let buffer = original.copy()
    let view = buffer[pos..(pos + 8)]
    input.into_byte_view(view, @representation.Endianness::BigEndian)
    test_bytes_eq(buffer, be_expected)?
  
    let buffer = original.copy()
    let view = buffer[pos..(pos + 8)]
    input.into_byte_view(view, @representation.Endianness::NetworkEndian)
    test_bytes_eq(buffer, be_expected)?
  
    let buffer = original.copy()
    let view = buffer[pos..(pos + 8)]
    input.into_byte_view_le(view)
    test_bytes_eq(buffer, le_expected)?

    let buffer = original.copy()
    let view = buffer[pos..(pos + 8)]
    input.into_byte_view_be(view)
    test_bytes_eq(buffer, be_expected)?
  }
}
test "int64.from_byte_view(series)" {
  let input = Bytes::[0x83, 0xe7, 0x4c, 0xcb, 0x8e, 0x35, 0x1c, 0xc5, 0xa4, 0x4e]
  let cases = [
    (0, 0xc5_1c_35_8e_cb_4c_e7_83_L, 0x83_e7_4c_cb_8e_35_1c_c5_L), 
    (1, 0xa4_c5_1c_35_8e_cb_4c_e7_L, 0xe7_4c_cb_8e_35_1c_c5_a4_L), 
    (2, 0x4e_a4_c5_1c_35_8e_cb_4c_L, 0x4c_cb_8e_35_1c_c5_a4_4e_L),
  ]
  for icase = 0; icase < cases.length(); icase = icase + 1 {
    let (pos, le_expected, be_expected) = cases[icase];
    let view = input[pos..(pos + 8)]
    
    @assertion.assert_eq(Int64::from_byte_view(view, @representation.Endianness::LittleEndian), le_expected)?
    @assertion.assert_eq(Int64::from_byte_view_le(view), le_expected)?
    @assertion.assert_eq(Int64::from_byte_view(view, @representation.Endianness::BigEndian), be_expected)?
    @assertion.assert_eq(Int64::from_byte_view(view, @representation.Endianness::NetworkEndian), be_expected)?
    @assertion.assert_eq(Int64::from_byte_view_be(view), be_expected)?
  }
}
