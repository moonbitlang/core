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
fn println_mono(s : String) -> Unit = "%println"

///|
fn any_to_string[T](any : T) -> String = "%any.to_string"

///|
pub fn println[T : Show](input : T) -> Unit {
  println_mono(input.to_string())
}

///|
/// @alert deprecated "Use `println` instead"
/// @coverage.skip
pub fn print[T : Show](input : T) -> Unit {
  println(input)
}

///|
/// Prints and returns the value of a given expression for quick and dirty debugging.
/// @alert deprecated "This function is for debugging only and should not be used in production"
pub fn dump[T](t : T, name? : String, loc~ : SourceLoc = _) -> T {
  let name = match name {
    Some(name) => name
    None => ""
  }
  println("dump(\{name}@\{loc}) = \{any_to_string(t)}")
  t
}

///|
pub(all) type! InspectError String

///|
pub fn inspect(
  obj : &Show,
  content~ : String = "",
  loc~ : SourceLoc = _,
  args_loc~ : ArgsLoc = _
) -> Unit!InspectError {
  let actual = obj.to_string()
  if actual != content {
    let loc = loc.to_string().escape()
    let args_loc = args_loc.to_json().escape()
    let expect = content.escape()
    let actual = obj.to_string().escape()
    raise InspectError(
      "@EXPECT_FAILED {\"loc\": \{loc}, \"args_loc\": \{args_loc}, \"expect\": \{expect}, \"actual\": \{actual}}",
    )
  }
}

///|
// Used by test driver
pub(all) type! SnapshotError String
