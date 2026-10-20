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
  let mut out_channel = @stdio.stdout
  let mut timeout = None
  for args = @env.args()[1:] {
    match args {
      ["-stderr", .. rest] => {
        out_channel = @stdio.stderr
        continue rest
      }
      ["-stdout", .. rest] => {
        out_channel = @stdio.stdout
        continue rest
      }
      ["-timeout", .. rest] => {
        guard rest is [t, .. rest] else { fail("invalid argument") }
        timeout = Some(@string.parse_int(t))
        continue rest
      }
      [] => break
      _ => fail("invalid arguments")
    }
  }
  async fn work() {
    out_channel.write_reader(@stdio.stdin)
  }
  if timeout is Some(t) {
    @async_io.with_timeout(t, work)
  } else {
    work()
  }
}
