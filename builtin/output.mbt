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
fn Int64::output(self : Int64, logger : &Logger, radix? : Int = 10) -> Unit {
  fn abs(n : Int64) -> Int64 {
    if n < 0L {
      0L - n
    } else {
      n
    }
  }

  if self < 0L {
    logger.write_char('-')
  }
  let radix : Int64 = radix.to_int64()
  fn write_digits(num : Int64) {
    let num2 = num / radix
    if num2 != 0L {
      write_digits(num2)
    }
    logger.write_char(
      ALPHABET.charcode_at(abs(num % radix).to_int()).unsafe_to_char(),
    )
  }

  write_digits(abs(self))
}

///|
fn Int::output(self : Int, logger : &Logger, radix? : Int = 10) -> Unit {
  fn abs(n : Int) -> Int {
    if n < 0 {
      0 - n
    } else {
      n
    }
  }

  if self < 0 {
    logger.write_char('-')
  }
  fn write_digits(num : Int) {
    let num2 = num / radix
    if num2 != 0 {
      write_digits(num2)
    }
    logger.write_char(ALPHABET.charcode_at(abs(num % radix)).unsafe_to_char())
  }

  write_digits(abs(self))
}

///|
fn UInt::output(self : UInt, logger : &Logger, radix? : Int = 10) -> Unit {
  let radix : UInt = radix.reinterpret_as_uint()
  fn write_digits(num : UInt) {
    let num2 = num / radix
    if num2 != 0U {
      write_digits(num2)
    }
    logger.write_char(
      ALPHABET.charcode_at((num % radix).reinterpret_as_int()).unsafe_to_char(),
    )
  }

  write_digits(self)
}

///|
fn UInt64::output(self : UInt64, logger : &Logger, radix? : Int = 10) -> Unit {
  let radix : UInt64 = radix.to_uint64()
  fn write_digits(num : UInt64) {
    let num2 = num / radix
    if num2 != 0UL {
      write_digits(num2)
    }
    logger.write_char(
      ALPHABET.charcode_at((num % radix).to_int()).unsafe_to_char(),
    )
  }

  write_digits(self)
}

///|
fn Int64::output_size_hint(radix? : Int = 10) -> Int {
  match radix {
    2..<7 => 70 // max length is 64, 70 is enough
    8..<15 => 30 // max length is 23, 30 is enough
    16..=36 => 20 // max length is 17, 20 is enough
    _ => abort("radix must be between 2 and 36")
  }
}

///|
fn Int::output_size_hint(radix? : Int = 10) -> Int {
  match radix {
    2..<7 => 36 // max length is 32, 36 is enough
    8..<15 => 18 // max length is 12, 18 is enough
    16..=36 => 10 // max length is 8, 10 is enough
    _ => abort("radix must be between 2 and 36")
  }
}

///|
fn UInt::output_size_hint(radix? : Int = 10) -> Int {
  Int::output_size_hint(radix~)
}

///|
fn UInt64::output_size_hint(radix? : Int = 10) -> Int {
  Int64::output_size_hint(radix~)
}
