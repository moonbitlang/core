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
/// A published portable utility, run through `moonx`, joins a pipeline like
/// any other program. `bobzhang/jq` is itself a MoonBit program, so the same
/// stage runs on every platform — the test needs no host `jq`, `sed`, or
/// `awk` — and the version is pinned so the run is reproducible. The first
/// use fetches and builds the package; `moonx` caches it after that, so the
/// generous timeout only covers a cold cache. The timeout stays well inside
/// the CI job's own ten-minute budget, so a hung registry fails this test
/// rather than the whole job.
async test "a published tool runs as a pipeline stage via moonx" {
  let record =
    #|{"tool":"moonbit","tags":["async","shell"]}
  let output = @shell.Pipeline([
    Cmd(cat_prog.wait(), [], stdin=Text(record)),
    Cmd("moonx", ["bobzhang/jq@0.1.1", "-r", ".tags[1]"]),
  ]).output(timeout_ms=300_000)
  inspect(output.stderr(), content="")
  inspect(output.exit_code(), content="0")
  inspect(output.stdout().replace_all(old="\r\n", new="\n"), content="shell\n")
}
