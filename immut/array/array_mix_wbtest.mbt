// Copyright 2024 International Digital Economy Academy
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

/// The naming of test follows the format
///   random seed - number of operations - maximum level of the tree
/// If the given random seed is shorter than 32, it will be repeated
/// up to 32 chars.

test "DEADBEEF-10-4" {
  run_test!("DEADBEEF", 10, 4)
}

test "LIVEBEEF-50-3" {
  run_test!("LIVEBEEF", 50, 3)
}

test "HAPPYDOG-1000-2" {
  run_test!("HAPPYDOG", 200, 2)
}

test "HELLOWOLRD-5-3" {
  run_test!("HELLOWOLRD", 4, 1)
}

///|
fn run_test(seed : String, rep : Int, max_lvl : Int) -> Unit! {
  let seed = repeat_up_to_32(seed)
  let rng = @random.new(seed~)
  let rs = random_test_gen(rng, rep, max_lvl)
  execute_array_test!(rs)
}
