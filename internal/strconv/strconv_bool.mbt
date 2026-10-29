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
/// Parse a string and return the represented boolean value or an error.
pub fn parse_bool(str : StringView) -> Bool raise {
  lexmatch str with longest {
    re"^(true|TRUE|True|t|T|1)$" => true
    re"^(false|FALSE|False|f|F|0)$" => false
    _ => syntax_err()
  }
}
