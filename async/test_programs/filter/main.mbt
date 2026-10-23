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
/// A portable stand-in for the small text tools a shell pipeline test needs
/// (`grep`, `tr '[a-z]' '[A-Z]'`, `head`), so tests behave the same on every
/// platform.
///
/// Reads stdin line by line and writes matching lines to stdout:
///
///   -upper           uppercase each emitted line
///   -keep <substr>   only emit lines containing <substr>
///   -head <n>        exit right after emitting <n> lines, without draining
///                    stdin, so an upstream writer observes a closed pipe
///   -stderr <msg>    write <msg> to stderr before exiting
///   -exit-code <n>   exit with status <n>
///   -print-cwd       print the working directory and exit; stdin is not read
extern "C" fn exit(code : Int32) = "exit"

///|
async fn main {
  let mut upper = false
  let mut keep = None
  let mut head = None
  let mut stderr_msg = None
  let mut exit_code = 0
  let mut print_cwd = false
  for args = @env.args()[1:] {
    match args {
      [] => break
      ["-upper", .. rest] => {
        upper = true
        continue rest
      }
      ["-keep", substr, .. rest] => {
        keep = Some(substr)
        continue rest
      }
      ["-head", n, .. rest] => {
        head = Some(@string.parse_int(n))
        continue rest
      }
      ["-stderr", msg, .. rest] => {
        stderr_msg = Some(msg)
        continue rest
      }
      ["-exit-code", n, .. rest] => {
        exit_code = @string.parse_int(n)
        continue rest
      }
      ["-print-cwd", .. rest] => {
        print_cwd = true
        continue rest
      }
      _ => fail("invalid arguments")
    }
  }
  if print_cwd {
    guard @env.current_dir() is Some(cwd) else { fail("no working directory") }
    @stdio.stdout.text.write("\{cwd}\n")
  } else {
    let mut emitted = 0
    while @stdio.stdin.text.read_until("\n") is Some(line) {
      let line = line.trim_end(chars="\r").to_owned()
      if keep is Some(substr) && !line.contains(substr) {
        continue
      }
      let line = if upper { line.to_upper() } else { line }
      @stdio.stdout.text.write("\{line}\n")
      emitted += 1
      if head is Some(limit) && emitted >= limit {
        break
      }
    }
  }
  if stderr_msg is Some(msg) {
    @stdio.stderr.text.write(msg)
  }
  exit(exit_code)
}
