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

/// @alert deprecated "Use `inspect!(buf) directly instead of buf.expect!()"
pub fn expect(
  self : Buffer,
  ~content : String = "",
  ~loc : SourceLoc = _,
  ~args_loc : ArgsLoc = _
) -> Unit!InspectError {
  let current = self.to_string()
  self.reset()
  if current != content {
    fn repr(s : String) -> String {
      let buf = StringBuilder::new()
      Show::output(s, buf)
      buf.to_string()
    }

    let loc = repr(loc.to_string())
    let args_loc = repr(args_loc.to_json())
    let expect = repr(content)
    let actual = repr(current)
    raise InspectError(
      "@EXPECT_FAILED {\"loc\": \{loc}, \"args_loc\": \{args_loc}, \"expect\": \{expect}, \"actual\": \{actual}}",
    )
  }
}
