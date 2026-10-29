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

// Each benchmark runs `BytesRegex` and `@string.Regex` on the same ASCII
// pattern and input, so the pairs measure what the byte automaton saves.

///|
fn bench_pair(
  it : @bench.T,
  name : String,
  pattern : String,
  inputs : Array[String],
) -> Unit {
  let s_re = try! @string.Regex(pattern)
  let b_re = try! @bytes.BytesRegex(pattern)
  let b_inputs = inputs.map(ascii_bytes)
  it.bench(name="\{name}/string", () => {
    for input in inputs {
      it.keep(s_re.execute(input))
    }
  })
  it.bench(name="\{name}/bytes", () => {
    for input in b_inputs {
      it.keep(b_re.execute(input))
    }
  })
}

///|
test "bench regex /aa?b/ on 1MB" (it : @bench.T) {
  bench_pair(it, "aa?b 1MB", "aa?b", ["a".repeat(1024 * 1024 - 1) + "b"])
}

///|
test "bench regex word boundary scan 1MB" (it : @bench.T) {
  let text = "the quick brown fox jumps over the lazy dog, ".repeat(23302)
  bench_pair(it, "\\bzebra\\b 1MB", "\\bzebra\\b", [text])
}

///|
test "bench regex key=value groups" (it : @bench.T) {
  let lines = Array::makei(2000, i => {
    "ts=\{i} level=info msg=\"request served\" path=/api/v1/items/\{i * 7} status=200 dur=\{i % 97}ms"
  })
  bench_pair(
    it, "key=value", "path=(?<path>[^ ]+) status=(?<status>[[:digit:]]{3}) dur=(?<dur>[[:digit:]]+)ms",
    lines,
  )
}

///|
test "bench regex phone lines" (it : @bench.T) {
  let phone_lines = [
    "datafile for regex matching of phone numbers test", "", "the following numbers should match:",
    "", "(111) 111 1111", "111 222-2222", "(111) 333-3333", "111 444 4444", "", "foo (111) 555 5555",
    "foo 111 666-6666", "foo (111) 777-7777", "foo 111 888 8888", "", "foo (111) 999 9999 bar",
    "foo 111 000-0000 bar", "foo (111) 232-1111 bar", "foo 111 242 1111 bar", "",
    "The following should fail to match:", "", "2(212) 222 2222", "2232 222-2222",
    "(242) 222-22222", "2252 222 2222", "", "foo (262) 2222222", "foo 272 2222222",
    "foo (282) 222-22227", "foo 292 222 22222", "", "foo (202).222 2222 bar", "foo 211@22222222 bar",
    "foo (213 222-2222 bar", "foo 214) 222 2222 bar",
  ]
  bench_pair(
    it, "phone", "([(][0-9]{3}[)]|[0-9]{3}) [0-9]{3}[ \\-][0-9]{4}", phone_lines,
  )
}

///|
test "bench regex large pattern" (it : @bench.T) {
  let parts = Array::makei(38, i => {
    let idx = "\{i}".pad_start(3, '0')
    ".*(?:src_\{idx}|tmp_\{idx}|cache_\{idx})\\.(?:log|tmp|cache)$"
  })
  let filenames = Array::makei(20_000, i => {
    if i % 5 == 0 {
      let idx = "\{i % 38}".pad_start(3, '0')
      let (stem, ext) = [("src", "log"), ("tmp", "tmp"), ("cache", "cache")][i %
        3]
      "repo/subdir/\{stem}_\{idx}.\{ext}"
    } else {
      "repo/subdir/other_\{i}.txt"
    }
  })
  bench_pair(it, "large pattern", parts.join("|"), filenames)
}

///|
test "bench regex periodic literal n=300, fresh regex" (it : @bench.T) {
  // A fresh regex on every sample measures parsing and state construction.
  let literal = "ab".repeat(300)
  let pattern = literal + "c"
  let no_match = literal + literal
  let with_match = "ab" + literal + "c"
  let b_no_match = ascii_bytes(no_match)
  let b_with_match = ascii_bytes(with_match)
  it.bench(name="periodic literal/string", () => {
    let re = try! @string.Regex(pattern)
    it.keep(re.execute(no_match))
    it.keep(re.execute(with_match))
  })
  it.bench(name="periodic literal/bytes", () => {
    let re = try! @bytes.BytesRegex(pattern)
    it.keep(re.execute(b_no_match))
    it.keep(re.execute(b_with_match))
  })
}
