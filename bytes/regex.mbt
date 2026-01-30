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
struct BytesRegex(@re.Regex)

///|
#internal(experimental, "subject to breaking change without notice")
struct MatchResult {
  input : BytesView
  group_names : ReadOnlyArray[String?]
  result : @re.MatchResult
}

///|
#internal(experimental, "subject to breaking change without notice")
pub fn MatchResult::before(self : MatchResult) -> BytesView {
  guard self.result.group(0) is Some((start, _end)) else { panic() }
  self.input[0:start]
}

///|
#internal(experimental, "subject to breaking change without notice")
pub fn MatchResult::after(self : MatchResult) -> BytesView {
  guard self.result.group(0) is Some((_start, end)) else { panic() }
  self.input[end:self.input.length()]
}

///|
#internal(experimental, "subject to breaking change without notice")
pub fn MatchResult::content(self : MatchResult) -> BytesView {
  guard self.result.group(0) is Some((start, end)) else { panic() }
  self.input[start:end]
}

///|
#internal(experimental, "subject to breaking change without notice")
pub fn MatchResult::group(self : MatchResult, group_index : Int) -> BytesView? {
  match self.result.group(group_index) {
    None => None
    Some((start, end)) => Some(self.input[start:end])
  }
}

///|
#internal(experimental, "subject to breaking change without notice")
pub fn MatchResult::named_group(
  self : MatchResult,
  name : String,
) -> BytesView? {
  match self.group_names.search(Some(name)) {
    None => None
    Some(index) => self.group(index)
  }
}

///|
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn BytesRegex::internal_compile_pattern(pat : @re.Pattern) -> BytesRegex {
  @re.compile(profile=re_profile, pat)
}

///|
#internal(experimental, "subject to breaking change without notice")
pub fn BytesRegex::execute(
  self : BytesRegex,
  input : BytesView,
  last_index? : Int = 0,
) -> MatchResult? {
  match self.0.execute(input, last_index) {
    None => None
    Some(result) =>
      Some(MatchResult::{ input, group_names: self.0.group_names(), result })
  }
}
