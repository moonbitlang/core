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
test "resolve_help_target merges inherited globals by name" {
  let leaf = Command("leaf")
  let mid = Command(
    "mid",
    options=[Option("mode", long="mid-mode", global=true)],
    subcommands=[leaf],
  )
  let root = Command(
    "demo",
    options=[Option("mode", long="root-mode", global=true)],
    subcommands=[mid],
  )

  let (target, globals, path) = resolve_help_target(
    root,
    ["mid", "leaf"],
    true,
    true,
    [],
    "demo",
  ) catch {
    _ => panic()
  }
  let help = render_help_for_context(target, globals, path)
  assert_true(help.contains("--mid-mode <mode>"))
  assert_true(!help.contains("--root-mode <mode>"))
}
