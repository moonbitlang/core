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

let k = 55

pub fn RandomState::new() -> RandomState {
  { state: FixedArray::make(k, 0), index: 0 }
}

pub fn RandomState::init_state(~seed : Int = 0) -> RandomState {
  let state = FixedArray::make(k, 0)
  state[0] = seed
  for i = 1; i < k; i = i + 1 {
    state[i] = (1812433253 * state[i - 1].lxor(state[i - 1].asr(30)) + i).land(
      0xffffffff,
    )
  }
  { state, index: 0 }
}

fn bits(self : RandomState) -> Int {
  self.index = self.index % k
  let curval = self.state[self.index]
  let newval = self.state[(self.index + 24) % k] + curval.lxor(
      curval.lsr(25).land(0x1f),
    )
  let newval30 = newval.land(0x3fffffff)
  self.state[self.index] = newval30
  newval30
}

pub fn gen_int(self : RandomState) -> Int {
  self.bits()
}

pub fn gen_int64(self : RandomState) -> Int64 {
  let b1 = Int64::from_int(self.bits())
  let b2 = b1.lsl(30)
  let b3 = Int64::from_int(self.bits().land(7)).lsl(60)
  b1.lor(b2.lor(b3))
}

pub fn gen_double(self : RandomState) -> Double {
  let scale = 1073741824.0
  let r1 = Double::from_int(self.bits())
  let r2 = Double::from_int(self.bits())
  (r1 / scale + r2) / scale
}
