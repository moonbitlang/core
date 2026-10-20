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
  let mut duration = 500
  let mut file = None
  let mut kind = None
  for args = @env.args()[1:] {
    match args {
      ["-duration", .. rest] => {
        guard rest is [t, .. rest] else {
          fail("expected duration value after `-duration`")
        }
        duration = @string.parse_int(t)
        continue rest
      }
      ["-shared", .. rest] => {
        kind = Some(@fs.Shared)
        continue rest
      }
      ["-exclusive", .. rest] => {
        kind = Some(Exclusive)
        continue rest
      }
      [['-', ..] as opt, ..] => fail("unknown argument \{opt}")
      [f, .. rest] => {
        guard file is None else { fail("too many files specified") }
        file = Some(f)
        continue rest
      }
      [] => break
    }
  }
  guard file is Some(file) else { fail("no file specified") }
  guard kind is Some(kind) else { fail("no lock kind specified") }
  let file = @fs.open(
    file,
    create_mode=OpenOrCreate,
    mode=if kind is Shared { ReadOnly } else { ReadWrite },
  )
  defer file.close()
  file.lock(kind)
  defer file.unlock()
  @stdio.stdout.text.write("acquired lock\n")
  @async_io.sleep(duration)
  @stdio.stdout.text.write("releasing lock\n")
}
