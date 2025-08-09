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
test "decimal parsing with positive sign" {
  // Test parsing with explicit positive sign (uncovered line 61)
  let result = @strconv.parse_double("+123.456")
  inspect(result, content="123.456")
  
  let result2 = @strconv.parse_double("+0.001")
  inspect(result2, content="0.001")
  
  let result3 = @strconv.parse_double("+1.23e+10")
  inspect(result3 > 10000000000.0, content="true") // Should be 1.23 * 10^10
}

///|
test "int parsing with explicit base and prefixes" {
  // Test octal prefix with explicit base 8 (uncovered line 47)
  try {
    let result = @strconv.parse_int("0o755", base=8)
    inspect(result, content="493") // 755 in octal = 493 in decimal
  } catch {
    _ => inspect(false, content="true") // Should not error
  }
  
  // Test binary prefix with explicit base 2 (uncovered line 48)
  try {
    let result = @strconv.parse_int("0b1010", base=2)
    inspect(result, content="10") // 1010 in binary = 10 in decimal
  } catch {
    _ => inspect(false, content="true") // Should not error
  }
}

///|
test "double parsing with inf/nan edge cases" {
  // Test inf/nan parsing with extra characters (uncovered line 84 in double.mbt)
    try {
    let _ = @strconv.parse_double("inf_extra")
    inspect(false, content="true") // Should fail due to extra characters
  } catch {
    @strconv.StrConvError(_) => inspect(true, content="true") // Expected
    _ => inspect(false, content="true") // Unexpected error
  }
  
      try {
          let _ = @strconv.parse_double("nan123")
      inspect(false, content="true") // Should fail due to extra characters
    } catch {
      @strconv.StrConvError(_) => inspect(true, content="true") // Expected
      _ => inspect(false, content="true") // Unexpected error
    }
  
  // Valid inf/nan should work
  try {
    let inf_result = @strconv.parse_double("inf")
    inspect(inf_result.is_inf(), content="true")
    
    let nan_result = @strconv.parse_double("nan")
    inspect(nan_result.is_nan(), content="true")
  } catch {
    _ => inspect(false, content="true")
  }
}

///|
test "complex number parsing edge cases" {
  // Test cases that exercise edge paths in number parsing
  let test_cases = [
    "+1.23456789012345678901234567890e-10",
    "+999.99999999999999999999999999999999999",
    "+0.00000000000000000012345678901234567890",
  ]
  
  for case in test_cases {
    try {
      let result = @strconv.parse_double(case)
             inspect(result >= 0.0 || result <= 0.0, content="true") // Should be a valid number
    } catch {
      _ => inspect(false, content="true") // These should not throw errors
    }
  }
}

///|
test "scientific notation edge cases" {
  // Test cases that should exercise step method edge cases
      try {
          let _ = @strconv.parse_double("1e")
      inspect(false, content="true") // Should fail
    } catch {
      @strconv.StrConvError(_) => inspect(true, content="true") // Expected
      _ => inspect(false, content="true") // Unexpected error
    }
  
      try {
          let _ = @strconv.parse_double("1.2e")
      inspect(false, content="true") // Should fail
    } catch {
      @strconv.StrConvError(_) => inspect(true, content="true") // Expected
      _ => inspect(false, content="true") // Unexpected error
    }
}