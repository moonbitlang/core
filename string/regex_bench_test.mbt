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
test "bench regex /aa?b/ on 1MB string" (it : @bench.T) {
  let re = re"aa?b"
  let one_mb_string : String = "a".repeat(1024 * 1024 - 1) + "b"
  it.bench(() => re.execute(one_mb_string) |> ignore)
}

///|
test "bench regex phone lines" (it : @bench.T) {
  let re = re"([(][0-9]{3}[)]|[0-9]{3}) [0-9]{3}[ \-][0-9]{4}"
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
  it.bench(() => {
    for line in phone_lines {
      re.execute(line) |> ignore
    }
  })
}

///|
test "bench regex large pattern" (it : @bench.T) {
  fn padded3(i : Int) -> String {
    "\{i}".pad_start(3, '0')
  }
  fn make_large_pattern() -> String {
    let parts = Array::new()
    for i in 0..<38 {
      let idx = padded3(i)
      parts.push(
        ".*(?:src_\{idx}|tmp_\{idx}|cache_\{idx})\\.(?:log|tmp|cache)$",
      )
    }
    parts.join("|")
  }
  fn make_filenames() -> Array[String] {
    let filenames = Array::new(capacity=20_000)
    for i in 0..<20_000 {
      if i % 5 == 0 {
        let idx = padded3(i % 38)
        let stem = if i % 3 == 0 {
          "src"
        } else if i % 3 == 1 {
          "tmp"
        } else {
          "cache"
        }
        let ext = if i % 3 == 0 {
          "log"
        } else if i % 3 == 1 {
          "tmp"
        } else {
          "cache"
        }
        filenames.push("repo/subdir/\{stem}_\{idx}.\{ext}")
      } else {
        filenames.push("repo/subdir/other_\{i}.txt")
      }
    }
    filenames
  }
  let re = try! @string.Regex::new(make_large_pattern())
  let filenames = make_filenames()
  it.bench(() => {
    for filename in filenames {
      re.execute(filename) |> ignore
    }
  })
}
