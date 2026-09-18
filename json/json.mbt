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
pub using @builtin {type Replacer}

///|
/// Inspect JSON value with snapshot-friendly formatting.
#callsite(autofill(args_loc, loc))
#alias(inspect, deprecated="Use `json_inspect` without package name instead.")
pub fn json_inspect(
  obj : &ToJson,
  content? : Json,
  loc~ : SourceLoc,
  args_loc~ : ArgsLoc,
) -> Unit raise InspectError {
  let loc = loc.to_json_string()
  let args_loc = args_loc.to_json()
  let actual = obj.to_json().stringify(escape_slash=false)
  let want = match content {
    Some(x) | (None with x = "".to_json()) => x.stringify(escape_slash=false)
  }
  if actual != want {
    raise InspectError(
      (
        $|@EXPECT_FAILED {"loc": \{loc}, "args_loc": \{args_loc}, "expect": \{want.escape()}, "actual": \{actual.escape()}, "mode": "json"}
      ),
    )
  }
}
