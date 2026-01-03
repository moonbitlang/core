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
#doc(hidden)
struct MatchResult(@regex_impl.MatchResult, @regex_impl.Regexp)

///|
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn MatchResult::before(self : Self) -> StringView {
  self.0.before()
}

///|
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn MatchResult::after(self : Self) -> StringView {
  self.0.after()
}

///|
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn MatchResult::content(self : Self) -> StringView {
  self.0.get(0).unwrap()
}

///|
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn MatchResult::group(self : Self, index : Int) -> StringView? {
  self.0.get(index)
}

///|
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn MatchResult::named_group(self : Self, name : String) -> StringView? {
  if self.1.group_by_name(name) is Some(index) {
    self.0.get(index)
  } else {
    None
  }
}

///|
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
struct Regex(@regex_impl.Regexp)

///|
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn compile(pattern : StringView) -> Regex raise {
  @regex_impl.compile(pattern)
}

///|
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn Regex::execute(self : Self, input : StringView) -> MatchResult? {
  match self.0.match_(input) {
    None => None
    Some(result) => Some(MatchResult(result, self.0))
  }
}
