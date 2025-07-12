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

test "uint16_arithmetic_basic" {
  // Test basic arithmetic operations
  let a = 100.to_uint16()
  let b = 50.to_uint16()
  
  // Addition
  let sum = a + b
  assert_eq(sum.to_int(), 150)
  
  // Subtraction
  let diff = a - b
  assert_eq(diff.to_int(), 50)
  
  // Multiplication
  let product = 10.to_uint16() * 5.to_uint16()
  assert_eq(product.to_int(), 50)
  
  // Division
  let quotient = a / b
  assert_eq(quotient.to_int(), 2)
  
  // Modulo
  let remainder = a % 7.to_uint16()
  assert_eq(remainder.to_int(), 2)
}

test "uint16_comparison_basic" {
  // Test equality
  let a = 100.to_uint16()
  let b = 100.to_uint16()
  let c = 200.to_uint16()
  
  assert_eq(a == b, true)
  assert_eq(a == c, false)
  
  // Test comparison
  assert_eq(a.compare(b), 0)
  assert_eq(a.compare(c) < 0, true)
  assert_eq(c.compare(a) > 0, true)
}

test "uint16_hash_basic" {
  // Test hash function
  let a = 12345.to_uint16()
  let b = 12345.to_uint16()
  let c = 54321.to_uint16()
  
  assert_eq(a.hash(), b.hash())
  assert_ne(a.hash(), c.hash())
}

test "uint16_bitwise_basic" {
  // Test shift operations
  let one = 1.to_uint16()
  let shifted_left = one << 8
  assert_eq(shifted_left.to_int(), 256)
  
  let val = 256.to_uint16()
  let shifted_right = val >> 8
  assert_eq(shifted_right.to_int(), 1)
  
  // Test bitwise operations
  let a = 0x00FF.to_uint16()
  let b = 0xFF00.to_uint16()
  
  let or_result = a.lor(b)
  assert_eq(or_result.to_int(), 0xFFFF)
  
  let and_result = 0xFFFF.to_uint16().land(0x00FF.to_uint16())
  assert_eq(and_result.to_int(), 0x00FF)
  
  let xor_result = 0xFF00.to_uint16().lxor(0x00FF.to_uint16())
  assert_eq(xor_result.to_int(), 0xFFFF)
}

test "uint16_conversions_basic" {
  // Test conversions
  let val = 12345.to_uint16()
  
  assert_eq(val.to_uint().to_int(), 12345)
  assert_eq(val.to_uint64().to_int(), 12345)
  
  // Test JSON conversion
  let json_val = 42.to_uint16().to_json()
  match json_val {
    Json::number(n) => assert_eq(n, 42.0)
    _ => assert_eq(true, false)
  }
}

test "uint16_edge_cases" {
  // Test overflow/underflow
  let max_val = 65535.to_uint16()
  let min_val = 0.to_uint16()
  
  assert_eq((max_val + 1.to_uint16()).to_int(), 0) // overflow
  assert_eq((min_val - 1.to_uint16()).to_int(), 65535) // underflow
  
  // Test division and modulo edge cases
  assert_eq((max_val / max_val).to_int(), 1)
  assert_eq((max_val % 1.to_uint16()).to_int(), 0)
  
  // Test multiplication overflow
  let result = 256.to_uint16() * 257.to_uint16()
  assert_eq(result.to_int(), 0) // exactly 65536, should wrap to 0
}