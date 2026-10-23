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
async fn main {
  let args = match @env.args()[1:] {
    ["-no-stdio", .. rest] => {
      remove_standard_handles()
      rest
    }
    args => args
  }
  let (is_orphan, args) = match args {
    ["-orphan", .. rest] => (true, rest)
    args => (false, args)
  }
  guard args is [cmd, .. args] else { fail("invalid argument") }
  if is_orphan {
    let proc = @process.spawn_orphan(cmd, args)
    defer proc.close()
    ignore(proc.wait())
  } else {
    ignore(@process.run(cmd, args))
  }
}

///|
extern "C" fn remove_standard_handles() = "remove_standard_handles"
