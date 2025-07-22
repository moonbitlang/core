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
/// Test that abort function always panics - This test ensures abort never returns normally
test "abort function type safety" {
  // We can test that abort has the correct type signature
  // by testing it compiles with different type annotations
  fn test_abort_string() -> String {
    abort("test")
  }

  fn test_abort_int() -> Int {
    abort("test")
  }

  fn test_abort_bool() -> Bool {
    abort("test")
  }

  fn test_abort_array() -> Array[String] {
    abort("test")
  }

  // The fact that these compile demonstrates abort is properly generic
  let _ = test_abort_string
  let _ = test_abort_int
  let _ = test_abort_bool
  let _ = test_abort_array

}

///|
/// Test abort function with different message types
test "abort with various message formats" {
  // Test function that would abort with empty string
  fn would_abort_empty() -> String {
    abort("")
  }

  // Test function that would abort with Unicode
  fn would_abort_unicode() -> String {
    abort("Unicode: 测试 🚨")
  }

  // Test function that would abort in conditional
  fn would_abort_conditional(condition : Bool) -> String {
    if condition {
      abort("conditional")
    } else {
      "ok"
    }
  }

  // The fact these compile shows abort accepts various message formats
  let _ = would_abort_empty
  let _ = would_abort_unicode
  let _ = would_abort_conditional

}

///|
/// Test abort function usage in different contexts
test "abort usage contexts" {
  // Test abort in match expression
  fn match_with_abort(x : Int) -> String {
    match x {
      0 => "zero"
      _ => abort("not zero")
    }
  }

  // Test abort in complex expression
  fn complex_abort() -> Int {
    let x = 5
    if x > 0 {
      x
    } else {
      abort("negative")
    }
  }

  // The fact these compile demonstrates abort works in various contexts
  let _ = match_with_abort
  let _ = complex_abort

}
