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
extern "C" fn standard_handles_are_null() -> Int32 = "standard_handles_are_null"

///|
async fn main {
  assert_eq(standard_handles_are_null(), 1)
  guard @env.get_env_var("ASYNC_TEST_COMPLETION_FILE") is Some(completion_file) else {
    fail("missing completion file")
  }
  // Using process retains the stdio globals, but explicit redirection does not
  // require the GUI application's own standard handles to exist.
  let child = @process.run(
    "cmd.exe",
    ["/c", "exit", "0"],
    stdin=Empty,
    stdout=Collect,
    stderr=Collect,
  )
  assert_eq(child.exit_code, 0)
  @async.sleep(1)
  @fs.write_text(completion_file, "completed")
}
