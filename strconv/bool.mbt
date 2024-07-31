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

/// Parse a string and return the represented boolean value or an error.
pub fn parse_bool(str : String) -> Bool!StrConvError {
  match str {
    "1" | "t" | "T" | "true" | "TRUE" | "True" => true
    "0" | "f" | "F" | "false" | "FALSE" | "False" => false
    _ => syntax_err!()
  }
}

test "parse_bool" {
  let tests : Array[(String, Result[Bool, String])] = [
    ("", Err(syntax_err_str)),
    ("zutomayo", Err(syntax_err_str)),
    ("0", Ok(false)),
    ("f", Ok(false)),
    ("F", Ok(false)),
    ("FALSE", Ok(false)),
    ("false", Ok(false)),
    ("False", Ok(false)),
    ("1", Ok(true)),
    ("t", Ok(true)),
    ("T", Ok(true)),
    ("TRUE", Ok(true)),
    ("true", Ok(true)),
    ("True", Ok(true)),
  ]
  for i = 0; i < tests.length(); i = i + 1 {
    let t = tests[i]
    @test.eq!(
      try {
        Result::Ok(parse_bool!(t.0))
      } catch {
        StrConvError(err) => Err(err)
      },
      t.1,
    )
  }
}
