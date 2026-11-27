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
fn main {
  guard stdin.text.read_line() is Some(first_line) else {
    raise Failure("unexpected EOF")
  }
  guard first_line == "first line" else {
    raise Failure("unexpected content \{Repr(first_line)}, expected \"first line\"")
  }
  let result = @async.with_timeout_opt(500, () => stdin.text.read_line())
  if result is Some(result) {
    let result = result.unwrap_or("EOF")
    raise Failure("expected timeout, but `read_line` completed with \{result}")
  }
  stdout.text.write("timeout\n")
  guard stdin.text.read_line() is Some(second_line) else {
    raise Failure("unexpected EOF")
  }
  guard second_line == "second line" else {
    raise Failure("unexpected content \{Repr(second_line)}, expected \"second line\"")
  }
  ignore(stdin.read())
}
