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

test "to_lower_no_uppercase" {
  // Test strings with no uppercase letters - should return same string
  assert_eq("hello".to_lower(), "hello")
  assert_eq("world123".to_lower(), "world123")
  assert_eq("".to_lower(), "")
  assert_eq("!@#$%^&*()".to_lower(), "!@#$%^&*()")
  assert_eq("123456".to_lower(), "123456")
  assert_eq("hello world!".to_lower(), "hello world!")
  
  // Test view versions
  assert_eq("hello"[:].to_lower(), "hello")
  assert_eq("world123"[:].to_lower(), "world123")
  assert_eq(""[:].to_lower(), "")
  assert_eq("!@#$%^&*()"[:].to_lower(), "!@#$%^&*()")
}

test "to_upper_no_lowercase" {
  // Test strings with no lowercase letters - should return same string
  assert_eq("HELLO".to_upper(), "HELLO")
  assert_eq("WORLD123".to_upper(), "WORLD123")
  assert_eq("".to_upper(), "")
  assert_eq("!@#$%^&*()".to_upper(), "!@#$%^&*()")
  assert_eq("123456".to_upper(), "123456")
  assert_eq("HELLO WORLD!".to_upper(), "HELLO WORLD!")
  
  // Test view versions
  assert_eq("HELLO"[:].to_upper(), "HELLO")
  assert_eq("WORLD123"[:].to_upper(), "WORLD123")
  assert_eq(""[:].to_upper(), "")
  assert_eq("!@#$%^&*()"[:].to_upper(), "!@#$%^&*()")
}

test "to_lower_with_uppercase" {
  // Test mixed case strings
  assert_eq("Hello World".to_lower(), "hello world")
  assert_eq("ABC123def".to_lower(), "abc123def")
  assert_eq("MiXeD cAsE".to_lower(), "mixed case")
  assert_eq("A".to_lower(), "a")
  assert_eq("Z".to_lower(), "z")
  
  // Test view versions
  assert_eq("Hello World"[:].to_lower(), "hello world")
  assert_eq("ABC123def"[:].to_lower(), "abc123def")
  assert_eq("MiXeD cAsE"[:].to_lower(), "mixed case")
}

test "to_upper_with_lowercase" {
  // Test mixed case strings
  assert_eq("Hello World".to_upper(), "HELLO WORLD")
  assert_eq("abc123DEF".to_upper(), "ABC123DEF")
  assert_eq("MiXeD cAsE".to_upper(), "MIXED CASE")
  assert_eq("a".to_upper(), "A")
  assert_eq("z".to_upper(), "Z")
  
  // Test view versions  
  assert_eq("Hello World"[:].to_upper(), "HELLO WORLD")
  assert_eq("abc123DEF"[:].to_upper(), "ABC123DEF")
  assert_eq("MiXeD cAsE"[:].to_upper(), "MIXED CASE")
}

test "fold_comprehensive" {
  // Test fold with various operations
  assert_eq("hello".fold(init=0, (acc, c) => acc + c.to_int()), 532)
  assert_eq("abc".fold(init=0, (acc, _c) => acc + 1), 3)
  assert_eq("".fold(init=42, (acc, c) => acc + c.to_int()), 42)
  
  // Test fold collecting characters
  assert_eq("hello".fold(init=[], (acc, c) => { acc.push(c); acc }), 
           ['h', 'e', 'l', 'l', 'o'])
  
  // Test fold with string concatenation
  assert_eq("abc".fold(init="", (acc, c) => acc + c.to_string()), "abc")
  
  // Test fold with multiplication
  assert_eq("123".fold(init=1, (acc, c) => acc * (c.to_int() - 48)), 6)
  
  // Test view version
  assert_eq("hello"[:].fold(init=0, (acc, c) => acc + c.to_int()), 532)
  assert_eq("abc"[:].fold(init=[], (acc, c) => { acc.push(c); acc }), 
           ['a', 'b', 'c'])
}

test "rev_fold_comprehensive" {
  // Test rev_fold with various operations  
  assert_eq("hello".rev_fold(init=0, (acc, c) => acc + c.to_int()), 532)
  assert_eq("abc".rev_fold(init=0, (acc, _c) => acc + 1), 3)
  assert_eq("".rev_fold(init=42, (acc, c) => acc + c.to_int()), 42)
  
  // Test rev_fold collecting characters (should be reversed)
  assert_eq("hello".rev_fold(init=[], (acc, c) => { acc.push(c); acc }), 
           ['o', 'l', 'l', 'e', 'h'])
  
  // Test rev_fold with string concatenation (should be reversed)
  assert_eq("abc".rev_fold(init="", (acc, c) => acc + c.to_string()), "cba")
  
  // Test rev_fold with multiplication (same result as fold)
  assert_eq("123".rev_fold(init=1, (acc, c) => acc * (c.to_int() - 48)), 6)
  
  // Test view version
  assert_eq("hello"[:].rev_fold(init=0, (acc, c) => acc + c.to_int()), 532)
  assert_eq("abc"[:].rev_fold(init=[], (acc, c) => { acc.push(c); acc }), 
           ['c', 'b', 'a'])
}

test "fold_edge_cases" {
  // Test single character
  assert_eq("a".fold(init=0, (acc, c) => acc + c.to_int()), 97)
  assert_eq("a".rev_fold(init=0, (acc, c) => acc + c.to_int()), 97)
  
  // Test Unicode characters
  assert_eq("🌟".fold(init=0, (acc, _c) => acc + 1), 1)
  assert_eq("🌟".rev_fold(init=0, (acc, _c) => acc + 1), 1)
  
  // Test with non-character accumulator
  let double_result = "abc".fold(init=10.0, (acc, c) => acc + c.to_int().to_double())
  assert_eq(double_result == 10.0 + 97.0 + 98.0 + 99.0, true)
  
  // Test boolean accumulator
  assert_eq("Hello".fold(init=false, (acc, c) => acc || c.is_ascii_uppercase()), true)
  assert_eq("hello".fold(init=false, (acc, c) => acc || c.is_ascii_uppercase()), false)
}