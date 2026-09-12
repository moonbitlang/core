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
#cfg(target="js")
extern "js" fn swap_process_argv(
  args : FixedArray[String],
) -> FixedArray[String] =
  #| (args) => { const previous = process.argv; process.argv = args; return previous; }

///|
#cfg(target="js")
test "default argv excludes the Node executable and script path" {
  let previous = swap_process_argv(["node", "demo.js", "--verbose"])
  let result = Command("demo", flags=[FlagArg("verbose", long="verbose")]).parse(
    env=Map([]),
  ) catch {
    error => {
      ignore(swap_process_argv(previous))
      fail(error.to_string())
    }
  }
  ignore(swap_process_argv(previous))
  assert_true(result.flags is { "verbose": true, .. })
}
