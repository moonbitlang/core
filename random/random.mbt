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

let n32 : Int = 624

let m32 : Int = 397

let matrix_a_32 : Int = 0x9908b0df

let upper_mask_32 : Int = 0x80000000

let lower_mask_32 : Int = 0x7fffffff

pub fn RandomState::new() -> RandomState {
  { state: FixedArray::make(n32, 0), index: 0 }
}

pub fn RandomState::init_state(~seed : Int = 0) -> RandomState {
  let state = FixedArray::make(n32, 0)
  state[0] = seed
  for i = 1; i < n32; i = i + 1 {
    state[i] = (1812433253 * state[i - 1].lxor(state[i - 1].asr(30)) + i).land(
      0xffffffff,
    )
  }
  RandomState::{ state, index: n32 }
}

fn twist(self : RandomState) -> Unit {
  for i = 0; i < n32; i = i + 1 {
    let x = self.state[i]
      .land(upper_mask_32)
      .lor(self.state[(i + 1) % n32].land(lower_mask_32))
    self.state[i] = self.state[(i + m32) % m32].lxor(x.asr(1))
    if x % 2 != 0 {
      self.state[i] = self.state[i].lxor(matrix_a_32)
    }
  }
  self.index = 0
}

pub fn gen_int(self : RandomState) -> Int {
  if self.index >= n32 {
    self.twist()
  }
  let mut y = self.state[self.index]
  y = y.lxor(y.asr(11))
  y = y.lxor(y.lsl(7).land(0x9d2c5680))
  y = y.lxor(y.lsl(15).land(0xefc60000))
  y = y.lxor(y.asr(18))
  self.index += 1
  y
}

pub fn gen_int64(self : RandomState) -> Int64 {
  let b1 = Int64::from_int(self.gen_int())
  let b2 = b1.lsl(30)
  let b3 = Int64::from_int(self.gen_int().land(7)).lsl(60)
  b1.lor(b2.lor(b3))
}

pub fn gen_double(self : RandomState) -> Double {
  let scale = 1073741824.0
  let r1 = Double::from_int(self.gen_int())
  let r2 = Double::from_int(self.gen_int())
  (r1 / scale + r2) / scale
}

test "RandomState::new initializes state array correctly" {
  let rs = RandomState::new()
  for i = 0; i < n32; i = i + 1 {
    @test.eq!(rs.state[i], 0)
  }
  @test.eq!(rs.index, 0)
}
