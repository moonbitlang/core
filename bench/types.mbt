// Copyright 2025 International Digital Economy Academy
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
/// Opaque trait used to keep values alive across optimizations.
priv trait OpaqueValue {}

///|
/// Benchmark runner that collects summaries and JSON output.
///
/// Use `Bench::bench` to run named benchmarks, then `Bench::dump_summaries`
/// to export the collected results.
///
/// # Example
/// ```mbt check
/// test {
///   let bench = @bench.Bench::new()
///   bench.bench(() => ignore(1 + 1), count=1)
///   let dumped = bench.dump_summaries()
///   inspect(dumped.contains("\"runs\""), content="true")
/// }
/// ```
#alias(T)
struct Bench {
  buffer : StringBuilder
  summaries : Array[Summary]
  mut _storage : &OpaqueValue
}

///|
/// Create a new benchmark runner with empty state.
///
/// # Example
/// ```mbt check
/// test {
///   let bench = @bench.Bench::new()
///   inspect(bench.dump_summaries(), content="[]")
/// }
/// ```
#as_free_fn
pub fn Bench::new() -> Bench {
  let buffer = StringBuilder::new()
  let summaries = Array::new()
  { buffer, summaries, _storage: () }
}
