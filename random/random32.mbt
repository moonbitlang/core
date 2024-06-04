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

struct RandomInt {
  state : FixedArray[Int]
  mut index : Int
}

/// Creates a randint summoner.
/// 
/// # Example
/// ```
/// let summoner = RandomInt::new(seed=3) 
/// ```
pub fn RandomInt::new(~seed : Int = 0) -> RandomInt {
  let state = FixedArray::make(n32, 0)
  state[0] = seed
  for i = 1; i < n32; i = i + 1 {
    state[i] = (1812433253 * state[i - 1].lxor(state[i - 1].asr(30)) + i).land(
      0xffffffff,
    )
  }
  RandomInt::{ state, index: n32 }
}

fn twist(self : RandomInt) -> Unit {
  for i = 0; i < n32; i = i + 1 {
    let x = self.state[i].land(upper_mask_32).lor(
      self.state[(i + 1) % n32].land(lower_mask_32),
    )
    self.state[i] = self.state[(i + m32) % m32].lxor(x.asr(1))
    if x % 2 != 0 {
      self.state[i] = self.state[i].lxor(matrix_a_32)
    }
  }
  self.index = 0
}

/// summon a random integer number in the Int range
/// 
/// # Example
/// ```
/// let summoner = RandomInt::new(114514)
/// summoner.summon()
/// ```
pub fn summon(self : RandomInt) -> Int {
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

test "rand_int" {
  let summoner = RandomInt::new(seed=33)
  let a = summoner.summon()
  let b = summoner.summon()
  let c = summoner.summon()
  @assertion.assert_true(a != b && a != c && b != c)?
}
