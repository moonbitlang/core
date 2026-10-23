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
/// The suite runs the portable programs from `test_programs/` instead of
/// `printf`, `grep`, or `sh`, so every execution test exercises the same code
/// path on every platform. Building them goes through `@shell.Cmd` itself.
fn make_test_prog(name : String) -> @async.Lazy[String] {
  Lazy(() => @test_util.build_test_program(name))
}

///|
/// Copies stdin to stdout, or to stderr under `-stderr`.
let cat_prog : @async.Lazy[String] = make_test_prog("cat")

///|
/// Sleeps, reports a graceful termination signal, and can swallow it or exit
/// with a chosen code. See `test_programs/sleep`.
let sleep_prog : @async.Lazy[String] = make_test_prog("sleep")

///|
/// Prints its whole environment, one `NAME=value` line each.
let dump_env_prog : @async.Lazy[String] = make_test_prog("dump_env")

///|
/// Line-wise `grep`/`tr`/`head` stand-in. See `test_programs/filter`.
let filter_prog : @async.Lazy[String] = make_test_prog("filter")

///|
/// A payload of distinct lines: loss, duplication, and reordering all change
/// it, where a payload of identical lines would hide the latter two.
fn distinct_lines(count : Int32) -> String {
  let text = StringBuilder()
  for index in 0..<count {
    text.write_string("line-\{index}\n")
  }
  text.to_string()
}
