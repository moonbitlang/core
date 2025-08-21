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
#callsite(autofill(loc))
#deprecated("Use built-in `assert_eq` instead")
#coverage.skip
pub fn[T : Show + Eq] eq(a : T, b : T, loc~ : SourceLoc) -> Unit raise {
  if a != b {
    let a = debug_string(a)
    let b = debug_string(b)
    fail("`\{a} == \{b}`", loc~)
  }
}

///|
#callsite(autofill(loc))
#deprecated("Use built-in `assert_not_eq` instead")
#coverage.skip
pub fn[T : Show + Eq] ne(a : T, b : T, loc~ : SourceLoc) -> Unit raise {
  if !(a != b) {
    let a = debug_string(a)
    let b = debug_string(b)
    fail("`\{a} != \{b}`", loc~)
  }
}

///|
#callsite(autofill(loc))
#deprecated("Use built-in `assert_true` instead")
#coverage.skip
pub fn is_true(x : Bool, loc~ : SourceLoc) -> Unit raise {
  if !x {
    let x = debug_string(x)
    fail("`\{x}` is not true", loc~)
  }
}

///|
#callsite(autofill(loc))
#deprecated("Use built-in `assert_false` instead")
#coverage.skip
pub fn is_false(x : Bool, loc~ : SourceLoc) -> Unit raise {
  if x {
    let x = debug_string(x)
    fail("`\{x}` is not false", loc~)
  }
}

///|
#deprecated("Use `@bench.single_bench` instead")
pub fn bench(
  self : T,
  f : () -> Unit,
  count? : UInt = 10,
) -> Unit raise BenchError {
  ignore(self)
  let summary = @bench.single_bench(f, count~)
  raise BenchError("@BENCH \{summary.to_json().stringify()}\n")
}
