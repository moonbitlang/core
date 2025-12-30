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
/// A snapshot test helper that accumulates output before comparison.
///
/// Use `Test::new` to create a value, then call `write`/`writeln` and
/// `snapshot` to compare the buffer against the stored snapshot.
///
/// # Example
/// ```mbt check
/// test {
///   let t = @test.new("sample")
///   inspect(t.name(), content="sample")
/// }
/// ```
#alias(T, deprecated)
struct Test {
  name : String
  buffer : StringBuilder
}

///|
/// Create a new snapshot test helper with the given name.
///
/// # Example
/// ```mbt check
/// test {
///   let t = @test.new("case")
///   inspect(t.name(), content="case")
/// }
/// ```
#as_free_fn
pub fn Test::new(name : String) -> Test {
  { name, buffer: StringBuilder::new() }
}
