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
#internal(experimental, "subject to breaking change without notice")
struct Regex(@re.Regex)

///|
#internal(experimental, "subject to breaking change without notice")
struct MatchResult {
  input : StringView
  group_names : ReadOnlyArray[String?]
  result : @re.MatchResult
}

///|
#internal(experimental, "subject to breaking change without notice")
pub fn MatchResult::before(self : MatchResult) -> StringView {
  guard self.result.group(0) is Some((start, _end)) else { panic() }
  try! self.input[0:start]
}

///|
#internal(experimental, "subject to breaking change without notice")
pub fn MatchResult::after(self : MatchResult) -> StringView {
  guard self.result.group(0) is Some((_start, end)) else { panic() }
  try! self.input[end:self.input.length()]
}

///|
#internal(experimental, "subject to breaking change without notice")
pub fn MatchResult::content(self : MatchResult) -> StringView {
  guard self.result.group(0) is Some((start, end)) else { panic() }
  try! self.input[start:end]
}

///|
#internal(experimental, "subject to breaking change without notice")
pub fn MatchResult::group(self : MatchResult, group_index : Int) -> StringView? {
  match self.result.group(group_index) {
    None => None
    Some((start, end)) => Some(try! self.input[start:end])
  }
}

///|
#internal(experimental, "subject to breaking change without notice")
pub fn MatchResult::named_group(
  self : MatchResult,
  name : String,
) -> StringView? {
  match self.group_names.search(Some(name)) {
    None => None
    Some(index) => self.group(index)
  }
}

///|
#internal(internal, "not intended for public use")
#doc(hidden)
pub fn Regex::internal_compile_pattern(pat : Pattern) -> Regex {
  let pat = re_lower_to_utf16(pat.0)
  @re.compile(profile=re_profile_utf16, pat)
}

///|
#internal(experimental, "subject to breaking change without notice")
pub fn Regex::execute(
  self : Regex,
  input : StringView,
  lastIndex? : Int = 0,
) -> MatchResult? {
  match self.0.execute(input, lastIndex) {
    None => None
    Some(result) =>
      Some(MatchResult::{ input, group_names: self.0.group_names(), result })
  }
}
