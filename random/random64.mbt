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

let n64 : Int = 312

let m64 : Int = 156

let matrix_a_64 : Int64 = 0xB5026F5AA96619E9L

let upper_mask_64 : Int64 = 0xFFFFFFFF80000000L

let lower_mask_64 : Int64 = 0x7FFFFFFFL

struct RandomInt64 {
  state : Array[Int64]
  mut index : Int
}

struct RandomDouble {
  i64 : RandomInt64
}

/// Creates a randint64 summoner.
/// 
/// # Example
/// ```
/// let summoner = RandomInt64::new(114514)
/// ```
pub fn RandomInt64::new(seed : Int) -> RandomInt64 {
  let state = Array::make(n64, 0L)
  state[0] = seed.to_int64()
  for i = 1; i < n64; i = i + 1 {
    state[i] = (6364136223846793005L * state[i - 1].lxor(state[i - 1].asr(62)) +
    i.to_int64()).land(0xffffffffffffffffL)
  }
  RandomInt64::{ state, index: n64 }
}

/// Creates a randdouble summoner.
/// 
/// # Example
/// ```
/// let summoner = RandomDouble::new(114514)
/// ```
pub fn RandomDouble::new(seed : Int) -> RandomDouble {
  RandomDouble::{ i64: RandomInt64::new(seed) }
}

fn twist(self : RandomInt64) -> Unit {
  for i = 0; i < n64; i = i + 1 {
    let x = self.state[i].land(upper_mask_64).lor(
      self.state[(i + 1) % n64].land(lower_mask_64),
    )
    self.state[i] = self.state[(i + m64) % m64].lxor(x.asr(1))
    if x % 2L != 0L {
      self.state[i] = self.state[i].lxor(matrix_a_64)
    }
  }
  self.index = 0
}

/// summon a random float number in the [0.0,1.0]
/// 
/// # Example
/// ```
/// let summoner = RandomDouble::new(114514)
/// summoner.summon()
/// ```
pub fn summon(self : RandomDouble) -> Double {
  self.i64.summon().to_double() / (9223372036854775807L).to_double()
}

/// summon a random integer number in the Int64 range
/// 
/// # Example
/// ```
/// let summoner = RandomInt64::new(114514)
/// summoner.summon()
/// ```
pub fn summon(self : RandomInt64) -> Int64 {
  if self.index >= n64 {
    self.twist()
  }
  let mut y = self.state[self.index]
  y = y.lxor(y.asr(29).land(0x5555555555555555L))
  y = y.lxor(y.lsl(17).land(0x71D67FFFEDA60000L))
  y = y.lxor(y.lsl(37).land(0xFFF7EEE000000000L))
  y = y.lxor(y.asr(43))
  self.index += 1
  y
}

test "rand_int64" {
  let summoner = RandomInt64::new(114514)
  let a = summoner.summon()
  let b = summoner.summon()
  let c = summoner.summon()
  @test.is_true(a != b && a != c && b != c)?
}

test "rand_double" {
  let summoner = RandomDouble::new(114514)
  let a = summoner.summon()
  let b = summoner.summon()
  let c = summoner.summon()
  @test.is_true(a != b && a != c && b != c)?
}
