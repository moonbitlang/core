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
/// Verify Unicode input through console stdin, then write different Unicode
/// text through console stdout. This program is run by the `async/stdio` tests
/// under `test_programs/pty`.
async fn main {
  @stdio.stdout.text.write("console ready: 准备好 👋\n")
  guard @stdio.stdin.text.read_line() is Some(input) else {
    fail("unexpected console input")
  }
  assert_true(input == "console input: 中文 😀")
  @stdio.stdout.text.write("console output: 日本語 🚀\n")
  // Keep the console alive until the test has observed ConPTY's asynchronous
  // rendering of the output above.
  ignore(@stdio.stdin.text.read_line())
}
