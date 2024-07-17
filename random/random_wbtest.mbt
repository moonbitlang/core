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
  inspect!(rng.gen_int64(), content="8084403149060065107")
  inspect!(rng.gen_int64(), content="2279609739787318250")
  inspect!(rng.gen_int64(), content="2226638563751653351")
}

test "int32" {
  let rng = init_state(seed=37)
  inspect!(rng.gen_int(), content="1686431524")
  inspect!(rng.gen_int(), content="1962882487")
  inspect!(rng.gen_int(), content="1104074260")
}

test "double" {
  let rng = init_state(seed=37)
  inspect!(rng.gen_double(), content="1.8280767729232197")
  inspect!(rng.gen_double(), content="0.21014593823649855")
  inspect!(rng.gen_double(), content="1.9690294691898182")
}

test "FixedArray::make with zero initialization" {
  let k = 5
  let arr = FixedArray::make(k, 0)
  for i = 0; i < k; i = i + 1 {
    @test.eq(arr[i], 0)!
  }
}

test "FixedArray::make with non-zero initialization" {
  let k = 5
  let init_value = 42
  let arr = FixedArray::make(k, init_value)
  for i = 0; i < k; i = i + 1 {
    @test.eq(arr[i], init_value)!
  }
}

test "RandomState::new initializes state array correctly" {
  let rs = RandomState::new()
  for i = 0; i < n32; i = i + 1 {
    @test.eq(rs.state[i], 0)!
  }
  @test.eq(rs.index, 0)!
}
