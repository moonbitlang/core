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
let is_windows : Bool = @event_loop.platform is Windows

///|
let shell : String = if is_windows { "powershell" } else { "sh" }

///|
let write_stdout : String = if is_windows {
  "Write-Host -NoNewline"
} else {
  "printf '%s'"
}

///|
let write_stderr : String = if is_windows {
  "& { [Console]::Error.Write($args[0]) }"
} else {
  "printf >&2 '%s'"
}

///|
let ls : String = if is_windows { "Get-ChildItem -Name" } else { "ls" }

///|
fn make_test_prog(name : String) -> @async.Lazy[String] {
  Lazy(() => @test_util.build_test_program(name))
}

///|
let sleep_prog : @async.Lazy[String] = make_test_prog("sleep")

///|
let dump_env_prog : @async.Lazy[String] = make_test_prog("dump_env")

///|
let cat : @async.Lazy[String] = make_test_prog("cat")

///|
let spawn_prog : @async.Lazy[String] = make_test_prog("spawn")
