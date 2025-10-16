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
  // Use a fixed-size buffer to collect digits, then write them in reverse order
  let buffer : FixedArray[Byte] = FixedArray::make(70, b'0') // 70 is max size for any radix
  let mut num = if self < 0L { 0L - self } else { self }
  let radix_i64 : Int64 = radix.to_int64()
  let mut idx = 0

  // Collect digits in reverse order
  while true {
    let digit = num % radix_i64
    let digit_abs = if digit < 0L { 0L - digit } else { digit }
    buffer[idx] = ALPHABET.charcode_at(digit_abs.to_int()).to_byte()
    idx += 1
    num = num / radix_i64
    if num == 0L {
      break
    }
  }

  // Write the sign if negative
  if self < 0L {
    logger.write_char('-')
  }

  // Write digits in correct order (reverse of how we collected them)
  for i = idx - 1; i >= 0; i = i - 1 {
    logger.write_char(buffer[i].to_char())
  }
}

///|
fn Int::output(self : Int, logger : &Logger, radix? : Int = 10) -> Unit {
  // Use a fixed-size buffer to collect digits, then write them in reverse order
  let buffer : FixedArray[Byte] = FixedArray::make(36, b'0') // 36 is max size for any radix
  let mut num = if self < 0 { 0 - self } else { self }
  let mut idx = 0

  // Collect digits in reverse order
  while true {
    let digit = num % radix
    buffer[idx] = ALPHABET[if digit < 0 { 0 - digit } else { digit }].to_byte()
    idx += 1
    num = num / radix
    if num == 0 {
      break
    }
  }

  // Write the sign if negative
  if self < 0 {
    logger.write_char('-')
  }

  // Write digits in correct order (reverse of how we collected them)
  for i = idx - 1; i >= 0; i = i - 1 {
    logger.write_char(buffer[i].to_char())
  }
}

///|
fn UInt::output(self : UInt, logger : &Logger, radix? : Int = 10) -> Unit {
  // Use a fixed-size buffer to collect digits, then write them in reverse order
  let buffer : FixedArray[Byte] = FixedArray::make(36, b'0') // 36 is max size for any radix
  let radix_u : UInt = radix.reinterpret_as_uint()
  let mut num = self
  let mut idx = 0

  // Collect digits in reverse order
  while true {
    let digit = (num % radix_u).reinterpret_as_int()
    buffer[idx] = ALPHABET.charcode_at(digit).to_byte()
    idx += 1
    num = num / radix_u
    if num == 0U {
      break
    }
  }

  // Write digits in correct order (reverse of how we collected them)
  for i = idx - 1; i >= 0; i = i - 1 {
    logger.write_char(buffer[i].to_char())
  }
}

///|
fn UInt64::output(self : UInt64, logger : &Logger, radix? : Int = 10) -> Unit {
  // Use a fixed-size buffer to collect digits, then write them in reverse order
  let buffer : FixedArray[Byte] = FixedArray::make(70, b'0') // 70 is max size for any radix
  let radix_u64 : UInt64 = radix.to_uint64()
  let mut num = self
  let mut idx = 0

  // Collect digits in reverse order
  while true {
    let digit = (num % radix_u64).to_int()
    buffer[idx] = ALPHABET.charcode_at(digit).to_byte()
    idx += 1
    num = num / radix_u64
    if num == 0UL {
      break
    }
  }

  // Write digits in correct order (reverse of how we collected them)
  for i = idx - 1; i >= 0; i = i - 1 {
    logger.write_char(buffer[i].to_char())
  }
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
