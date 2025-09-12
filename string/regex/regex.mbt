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
#internal(experimental, "subject to breaking change without notice")
struct MatchResult(@regex_impl.MatchResult)

///|
#internal(experimental, "subject to breaking change without notice")
pub fn MatchResult::before(self : Self) -> @string.View {
  self.0.before()
}

///|
#internal(experimental, "subject to breaking change without notice")
pub fn MatchResult::after(self : Self) -> @string.View {
  self.0.after()
}

///|
#internal(experimental, "subject to breaking change without notice")
pub fn MatchResult::content(self : Self) -> @string.View {
  self.0.get(0).unwrap()
}

///|
#internal(experimental, "subject to breaking change without notice")
pub fn MatchResult::group(self : Self, index : Int) -> @string.View? {
  self.0.get(index)
}

///|
#internal(experimental, "subject to breaking change without notice")
pub fn MatchResult::named_group(self : Self, name : String) -> @string.View? {
  guard self.0.names.get(name) is Some(index) else { None }
  self.0.get(index)
}

///|
#internal(experimental, "subject to breaking change without notice")
struct Regex(@regex_impl.Regexp)

///|
#internal(experimental, "subject to breaking change without notice")
pub fn compile(pattern : @string.View) -> Regex raise {
  @regex_impl.compile(pattern)
}

///|
#internal(experimental, "subject to breaking change without notice")
pub fn Regex::execute(self : Self, input : @string.View) -> MatchResult? {
  match self.0.match_(input) {
    None => None
    Some(result) => Some(MatchResult(result))
  }
}
