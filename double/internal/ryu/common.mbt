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

// Returns e == 0 ? 1 : ceil(log_2(5^e)); requires 0 <= e <= 3528.
fn pow5bits(e : Int) -> Int {
  ((e * 1217359).reinterpret_as_uint() >> 19).reinterpret_as_int() + 1
}

fn copy_special_str(sign : Bool, exponent : Bool, mantissa : Bool) -> String {
  if mantissa {
    return "NaN"
  }
  let s = if sign { "-" } else { "" }
  if exponent {
    return s + "Infinity"
  }
  return s + "0.0"
}

// Returns floor(log_10(5^e)); requires 0 <= e <= 2620.
fn log10Pow5(e : Int) -> Int {
  ((e * 732923).reinterpret_as_uint() >> 20).reinterpret_as_int()
}

// Returns floor(log_10(2^e)); requires 0 <= e <= 1650.
fn log10Pow2(e : Int) -> Int {
  ((e * 78913).reinterpret_as_uint() >> 18).reinterpret_as_int()
}
