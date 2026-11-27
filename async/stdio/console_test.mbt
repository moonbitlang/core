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
async test "console Unicode safety" {
  let pty_path = @test_util.build_test_program("pty")
  let program_path = @test_util.build_test_program("console_stdio_unicode")
  @async.with_task_group() <| group => {
    let pty = @process.spawn(
      group,
      pty_path,
      [program_path],
      stdin=FeedFromParent,
      stdout=Collect,
      stderr=Collect,
    )
    defer pty.stdin.close()
    defer pty.stdout.close()
    defer pty.stderr.close()
    guard pty.stderr.text.read_line() is Some("ok") else {
      fail("pty failed to start")
    }
    async fn assert_line(suffix : String) -> Unit {
      guard @async.with_timeout(3000, () => pty.stdout.text.read_line())
        is Some(line) else {
        raise Failure("unexpected EOF")
      }
      // On Windows, the console may output extra escape sequence
      guard line.has_suffix(suffix) else {
        raise Failure(
          "unexpected output \{Repr(line)}, expected \{Repr(suffix)}",
        )
      }
    }
    assert_line("console ready: 准备好 👋")
    let input = @utf8.encode("console input: 中文 😀\r")
    pty.stdin.text.write("input \{@base64.encode(input)}\n")
    // input echo from the console itself
    assert_line("console input: 中文 😀")
    assert_line("console output: 日本語 🚀")
    let finish = @utf8.encode("\r")
    pty.stdin.text.write("input \{@base64.encode(finish)}\n")
    guard pty.wait() is 0 else { fail("pty process failed") }
    inspect(pty.stderr.text.read_all().trim(), content="exit 0")
  }
}
