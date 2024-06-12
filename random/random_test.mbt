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

test "int64" {
  let rng = init_state(seed=42)
  inspect(rng.gen_int64(), content="3641984065037120728")?
  inspect(rng.gen_int64(), content="7467187585727798831")?
  inspect(rng.gen_int64(), content="8986548099352266632")?
}

test "int32" {
  let rng = init_state(seed=37)
  inspect(rng.gen_int(), content="547383987")?
  inspect(rng.gen_int(), content="21026097")?
  inspect(rng.gen_int(), content="568410047")?
}

test "double" {
  let rng = init_state(seed=37)
  inspect(rng.gen_double(), content="0.019582079266934716")?
  inspect(rng.gen_double(), content="0.039164123618391444")?
  inspect(rng.gen_double(), content="0.05874619777217056")?
}
