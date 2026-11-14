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
/// Run the program at the only argument on a fresh pseudo terminal of 24 x 80.
/// The `@tty` tests drive `ttyd` through it.
///
/// - stdout is what the terminal displays.
/// - stdin takes one command per line. `input <base64>` types the bytes into
///   the terminal, and `resize <rows> <cols>` resizes it. Once stdin closes,
///   the terminal is closed, which kills the program.
/// - stderr has a line `ok` once the program is started and after each
///   `resize`, and `exit <code>` once it exits, with the code `wait_pid`
///   reports. An error is reported there instead.
async fn main {
  guard @env.args() is [_, path] else { fail("usage: pty <path>") }
  let pty = spawn(path)
  defer pty.close()
  @stdio.stderr.write(b"ok\n")
  @async.with_task_group(group => {
    group.spawn_bg(no_wait=true, () => {
      while pty.read_some() is Some(bytes) {
        @stdio.stdout.write(bytes)
      }
    })
    group.spawn_bg(no_wait=true, () => {
      while @stdio.stdin.read_until(b"\n") is Some(line) {
        run_command(pty, @utf8.decode(line))
      }
      pty.close()
    })
    let exit_code = pty.wait()
    @stdio.stderr.write(@utf8.encode("exit \{exit_code}\n"))
  })
}

///|
async fn run_command(pty : Pty, command : String) -> Unit {
  match command.split(" ").collect() {
    ["input", bytes] => pty.write(@base64.decode(bytes))
    ["resize", rows, cols] => {
      pty.resize(rows=@string.parse_int(rows), cols=@string.parse_int(cols))
      @stdio.stderr.write(b"ok\n")
    }
    _ => fail("unknown command: \{command}")
  }
}
