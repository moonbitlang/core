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
  let rng = init_state(state=123)
  inspect(rng.gen_int64(), content="6263409555191053425")?
  inspect(rng.gen_int64(), content="6977323705266507947")?
  inspect(rng.gen_int64(), content="5817029148242976666")?
}

test "int32" {
  let rng = init_state(state=123)
  inspect(rng.gen_int(), content="1458313678")?
  inspect(rng.gen_int(), content="1624534769")?
  inspect(rng.gen_int(), content="1354382640")?
}

test "double" {
  let rng = init_state(state=123)
  inspect(rng.gen_double(), content="0.6790802246904607")?
  inspect(rng.gen_double(), content="0.7564829519384557")?
  inspect(rng.gen_double(), content="0.6306835639936539")?
}
