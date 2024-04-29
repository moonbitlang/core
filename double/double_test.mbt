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

test "double.num" {
  let x = -500.0
  let y = 792.0
  test_num(x, y, x + y, x * y, x - y, x / y, -1.0)?
}

test "double.into_byte_view(series)" {
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
      -5.882781560676213e+94, // 0xd39c33c7f8175d9c (IEEE 754)
      0, 
      Bytes::[0xcc, 0xcc, 0xcc, 0xcc, 0xcc, 0xcc, 0xcc, 0xcc, 0xcc, 0xcc],
      Bytes::[0x9c, 0x5d, 0x17, 0xf8, 0xc7, 0x33, 0x9c, 0xd3, 0xcc, 0xcc],
      Bytes::[0xd3, 0x9c, 0x33, 0xc7, 0xf8, 0x17, 0x5d, 0x9c, 0xcc, 0xcc],
    ),
    (
      5.2795633159472795e-219, // 0x129dd1b1e9f37d1a (IEEE 754)
      1, 
      Bytes::[0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa],
      Bytes::[0xaa, 0x1a, 0x7d, 0xf3, 0xe9, 0xb1, 0xd1, 0x9d, 0x12, 0xaa],
      Bytes::[0xaa, 0x12, 0x9d, 0xd1, 0xb1, 0xe9, 0xf3, 0x7d, 0x1a, 0xaa],
    ),
    (
      -2.752623365577015e-164, // 0x9df95caf8b51fc5e (IEEE 754)
      2, 
      Bytes::[0xdf, 0xfd, 0xdf, 0xdf, 0xdf, 0xdf, 0xdf, 0xdf, 0xdf, 0xdf],
      Bytes::[0xdf, 0xfd, 0x5e, 0xfc, 0x51, 0x8b, 0xaf, 0x5c, 0xf9, 0x9d],
      Bytes::[0xdf, 0xfd, 0x9d, 0xf9, 0x5c, 0xaf, 0x8b, 0x51, 0xfc, 0x5e],
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

test "double.from_byte_view(series)" {
  let input = Bytes::[0x23, 0xb6, 0x1e, 0xc2, 0xa3, 0xbb, 0x19, 0x0f, 0x6d, 0x27]
  let cases = [
    (0, 6.322855833834645e-236, 1.1888038185948251e-136), 
    (1, 2.144245627950293e+217, -5.261764689278282e-48), 
    (2, 9.002687664123903e-119, 1.657251015555868e-160),
  ]
  for icase = 0; icase < cases.length(); icase = icase + 1 {
    let (pos, le_expected, be_expected) = cases[icase];
    let view = input[pos..(pos + 8)]
    
    @assertion.assert_eq(Double::from_byte_view(view, @representation.Endianness::LittleEndian), le_expected)?
    @assertion.assert_eq(Double::from_byte_view_le(view), le_expected)?
    @assertion.assert_eq(Double::from_byte_view(view, @representation.Endianness::BigEndian), be_expected)?
    @assertion.assert_eq(Double::from_byte_view(view, @representation.Endianness::NetworkEndian), be_expected)?
    @assertion.assert_eq(Double::from_byte_view_be(view), be_expected)?
  }
}
