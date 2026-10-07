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
/// The digits of a printed number without leading and trailing zeros, and
/// the decimal exponent of the last one.
fn digits_of(text : String) -> (String, Int) {
  let text = if text is ['-', .. rest] { rest } else { text }
  let (mantissa, exponent) = if text.find("e") is Some(i) {
    (text[:i], @string.parse_int(text[i + 1:]) catch { _ => panic() })
  } else {
    (text, 0)
  }
  let (int, frac) = if mantissa.find(".") is Some(i) {
    (mantissa[:i], mantissa[i + 1:])
  } else {
    (mantissa, "")
  }
  let digits = "\{int}\{frac}".to_array()
  let mut exp = exponent - frac.length()
  while digits.length() > 1 && digits[digits.length() - 1] == '0' {
    digits.unsafe_pop() |> ignore
    exp += 1
  }
  while digits.length() > 1 && digits[0] == '0' {
    digits.remove(0) |> ignore
  }
  (String::from_array(digits), exp)
}

///|
test "Float::to_string writes the shortest digits, like ryu" {
  for case in ryu_cases[:] {
    let (bits, digits, exponent) = case
    let x = Float::reinterpret_from_uint(bits)
    let text = x.to_string()
    if digits_of(text) != (digits, exponent) {
      fail("\{bits.to_string(radix=16)}: \{text}, ryu: \{digits}e\{exponent}")
    }
    // The text reads back as the same value,
    let double = @string.parse_double(text) catch { _ => panic() }
    assert_eq(Float::from_double(double).reinterpret_as_uint(), bits)
    // and it is laid out as `Double` lays out the same decimal.
    assert_eq(double.to_string(), text)
  }
  inspect(ryu_cases.length(), content="3181")
}

///|
test "Float::to_string" {
  let values : Array[Float] = [
    0.1, 1.1, 0.5, 1.0, -2.0, 100.0, 1.0e10, 16777216.0, 123.456, 3.4028235e38, 1.0e-45,
    1.0e21, 1.0e20, 1.5e-7, 0.000001, 2147483648.0, 0.0, -0.0,
  ]
  inspect(
    values.map(x => x.to_string()).join(" "),
    content=(
      #|0.1 1.1 0.5 1 -2 100 10000000000 16777216 123.456 3.4028235e+38 1e-45 1e+21 100000000000000000000 1.5e-7 0.000001 2147483600 0 0
    ),
  )
  inspect(
    [@float.infinity, @float.neg_infinity, @float.not_a_number]
    .map(x => x.to_string())
    .join(" "),
    content=(
      #|Infinity -Infinity NaN
    ),
  )
}

///|
test "Float::to_string rounds an exact tie to the even digit" {
  // Exactly halfway between two eight-digit decimals that both read back.
  let values : Array[Float] = [142.203125, 198.203125, 242.953125, 454.890625]
  inspect(
    values.map(x => x.to_string()).join(" "),
    content=(
      #|142.20312 198.20312 242.95312 454.89062
    ),
  )
}
