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
test "bench single_bench minimal" {
  let summary = @bench.single_bench(
    () => {
      let mut x = 0
      x = x + 1
      ignore(x)
    },
    name="noop",
    count=1,
  )
  let json = ToJson::to_json(summary).stringify()
  inspect(json.contains("\"runs\""), content="true")
}

///|
test "bench buffer writes with multiple samples" {
  let bench = @bench.Bench::new()
  bench.bench(() => ignore(1 + 1), name="first", count=1)
  bench.bench(() => ignore(2 + 2), name="second", count=1)
  inspect(bench.dump_summaries().contains(","), content="true")
}
