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

test "random property tests" {
  run_test!(104UL, 10, 4)
  run_test!(503UL, 50, 3)
  run_test!(10002UL, 200, 2)
  run_test!(53UL, 4, 1)
}

///|
fn run_test(seed : UInt64, rep : Int, max_lvl : Int) -> Unit! {
  let rng = Random({ val: seed })
  let rs = random_test_gen(rng, rep, max_lvl)
  execute_array_test!(rs)
}
