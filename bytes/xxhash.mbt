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

let gPRIME1 = -1640531535

let gPRIME2 = -2048144777

let gPRIME3 = -1028477379

let gPRIME4 = 668265263

let gPRIME5 = 374761393

fn xxhash32(input : Bytes, seed : Int) -> Int {
  let len = input.length()
  let h = if len >= 16 { h16bytes(input, 0, len, seed) } else { seed + gPRIME5 } +
    len
  finalize(h, input, len.land(-16), len.land(0xF))
}

pub fn hash(self : Bytes) -> Int {
  xxhash32(self, 0)
}

fn rotl(x : Int, r : Int) -> Int {
  x.lsl(r).lor(x.lsr(32 - r))
}

fn round(acc : Int, input : Int) -> Int {
  rotl(acc + input * gPRIME2, 13) * gPRIME1
}

fn avalanche_step(h : Int, rshift : Int, prime : Int) -> Int {
  h.lxor(h.lsr(rshift)) * prime
}

fn avalanche(h : Int) -> Int {
  avalanche_step(
    avalanche_step(avalanche_step(h, 15, gPRIME2), 13, gPRIME3),
    16,
    1,
  )
}

fn endian32(input : Bytes, cur : Int) -> Int {
  input[cur + 0].to_int().lor(
    input[cur + 1].to_int().lsl(8).lor(
      input[cur + 2].to_int().lsl(16).lor(input[cur + 3].to_int().lsl(24)),
    ),
  )
}

fn fetch32(input : Bytes, cur : Int, v : Int) -> Int {
  round(v, endian32(input, cur))
}

fn finalize(h : Int, input : Bytes, cur : Int, remain : Int) -> Int {
  if remain >= 4 {
    finalize(
      rotl(h + endian32(input, cur) * gPRIME3, 17) * gPRIME4,
      input,
      cur + 4,
      remain - 4,
    )
  } else if remain > 0 {
    finalize(
      rotl(h + input[cur].to_int() * gPRIME5, 11) * gPRIME1,
      input,
      cur + 1,
      remain - 1,
    )
  } else {
    avalanche(h)
  }
}

fn _h16bytes(
  input : Bytes,
  cur : Int,
  remain : Int,
  v1 : Int,
  v2 : Int,
  v3 : Int,
  v4 : Int
) -> Int {
  if remain >= 16 {
    _h16bytes(
      input,
      cur + 16,
      remain - 16,
      fetch32(input, cur, v1),
      fetch32(input, cur + 4, v2),
      fetch32(input, cur + 8, v3),
      fetch32(input, cur + 12, v4),
    )
  } else {
    rotl(v1, 1) + rotl(v2, 7) + rotl(v3, 12) + rotl(v4, 18)
  }
}

fn h16bytes(input : Bytes, cur : Int, len : Int, seed : Int) -> Int {
  _h16bytes(
    input,
    cur,
    len,
    seed + gPRIME1 + gPRIME2,
    seed + gPRIME2,
    seed,
    seed - gPRIME1,
  )
}
