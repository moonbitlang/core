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

// This file is manually transpiled from the SHA1 C-implementation of
// the HACL* project:
// https://github.com/hacl-star/hacl-star/blob/150843809c5fdbc7dac0af395f7a1bb9606f9f96/dist/gcc-compatible/Hacl_Hash_SHA1.c
// Copyright of the origin:
// * Copyright (c) 2016-2022 INRIA, CMU and Microsoft Corporation
// * Copyright (c) 2022-2023 HACL* Contributors

let _h0 = [0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476, 0xc3d2e1f0]

struct SHA1 {
  block_state : Array[Int]
  buf : Bytes
  mut total_len : Int64
}

pub fn SHA1::make(~init : Bytes = Bytes::make(0, 0)) -> SHA1 {
  let block_state = _h0.map(fn { x => x })
  let buf = Bytes::make(64, 0)
  let total_len = 0L
  let rv = SHA1::{ block_state, buf, total_len }
  if init.length() > 0 {
    rv.update(init)
  }
  rv
}

fn update_multi(
  h : Array[Int],
  blocks : @bytes.BytesView,
  n_blocks : Int
) -> Unit {
  for i = 0; i < n_blocks; i = i + 1 {
    let l = (blocks[i * 64..]) as @mem.Loadable
    let [ ha, hb, hc, hd, he, .. ] = h
    let _w = Array::make(80, 0)
    for i = 0; i < 80; i = i + 1 {
      _w[i] = if i < 16 {
        l.load_int(i * 4, @mem.Endian::Big)
      } else {
        let wmit3 = _w[i - 3]
        let wmit8 = _w[i - 8]
        let wmit14 = _w[i - 14]
        let wmit16 = _w[i - 16]
        wmit3.lxor(wmit8.lxor(wmit14.lxor(wmit16))).lsl(1).lor(
          wmit3.lxor(wmit8.lxor(wmit14.lxor(wmit16))).lsr(31),
        )
      }
    }
    for i = 0; i < 80; i = i + 1 {
      let [ _a, _b, _c, _d, _e, .. ] = h
      let wmit = _w[i]
      let ite0 = if i < 20 {
        _b.land(_c).lxor(_b.lnot().land(_d))
      } else if 39 < i && i < 60 {
        _b.land(_c).lxor(_b.land(_d).lxor(_c.land(_d)))
      } else {
        _b.lxor(_c.lxor(_d))
      }
      let ite = if i < 20 {
        0x5a827999
      } else if i < 40 {
        0x6ed9eba1
      } else if i < 60 {
        0x8f1bbcdc
      } else {
        0xca62c1d6
      }
      h[0] = _a.lsl(5).lor(_a.lsr(27)) + ite0 + _e + ite + wmit
      h[1] = _a
      h[2] = _b.lsl(30).lor(_b.lsr(2))
      h[3] = _c
      h[4] = _d
    }
    for i = 0; i < 80; i = i + 1 {
      _w[i] = 0
    }
    h[0] += ha
    h[1] += hb
    h[2] += hc
    h[3] += hd
    h[4] += he
  }
}

fn update_last(
  s : Array[Int],
  prev_len : Int64,
  input : @bytes.BytesView,
  input_len : Int
) -> Unit {
  let blocks_n = input_len / 64
  let blocks_len = blocks_n * 64
  let rest_len = input_len - blocks_len
  update_multi(s, input, blocks_n)
  let total_input_len = prev_len + input_len.to_int64()
  let pad_len = 1 + (128 - (9 + (total_input_len % 64L).to_int())) % 64 + 8
  let tmp_len = rest_len + pad_len
  let tmp_twoblocks = Bytes::make(128, 0)
  @mem.copy(
    tmp_twoblocks,
    {
      input[blocks_len..]
    },
    rest_len,
  )
  pad(
    total_input_len,
    {
      tmp_twoblocks[rest_len..]
    },
  )
  update_multi(
    s,
    {
      tmp_twoblocks[..]
    },
    tmp_len / 64,
  )
}

fn pad(len : Int64, dst : @mem.Storable) -> Unit {
  dst[0] = 0x80
  for i = 0; i < (128 - (9 + (len % 64L).to_int())) % 64; i = i + 1 {
    dst[i + 1] = 0
  }
  dst.store_int64(
    1 + (128 - (9 + (len % 64L).to_int())) % 64,
    len.lsl(3),
    @mem.Endian::Big,
  )
}

fn finish(s : Array[Int]) -> Bytes {
  for rv = Bytes::make(20, 0), i = 0; i < 5; i = i + 1 {
    (rv as @mem.Storable).store_int(i * 4, s[i], @mem.Endian::Big)
  } else {
    rv
  }
}

pub fn update(self : SHA1, chunk : Bytes) -> Unit {
  let total_len = self.total_len
  let chunk_len = chunk.length()
  if chunk_len.to_int64() > 2305843009213693951L - total_len {
    abort("Maximum length exceeded")
  }
  let sz = {
    let remainder = (total_len % 64L).to_int()
    if remainder == 0 && total_len > 0L {
      64
    } else {
      remainder
    }
  }
  if chunk_len <= 64 - sz {
    @mem.copy(
      {
        self.buf[sz..]
      },
      chunk,
      chunk_len,
    )
    self.total_len += chunk_len.to_int64()
  } else if sz == 0 {
    let ite = {
      let remainder = chunk_len % 64
      if remainder == 0 && chunk_len > 0 {
        64
      } else {
        remainder
      }
    }
    let n_blocks = (chunk_len - ite) / 64
    let data1_len = n_blocks * 64
    let data2_len = chunk_len - data1_len
    update_multi(
      self.block_state,
      {
        chunk[..]
      },
      n_blocks,
    )
    @mem.copy(
      self.buf,
      {
        chunk[data1_len..]
      },
      data2_len,
    )
    self.total_len += chunk_len.to_int64()
  } else {
    let diff = 64 - sz
    @mem.copy(
      {
        self.buf[sz..]
      },
      chunk,
      diff,
    )
    let total_len = total_len + diff.to_int64()
    self.total_len = total_len
    update_multi(
      self.block_state,
      {
        self.buf[..]
      },
      1,
    )
    let chunk_len = chunk_len - diff
    let ite = {
      let remainder = chunk_len % 64
      if remainder == 0 && chunk_len > 0 {
        64
      } else {
        remainder
      }
    }
    let n_blocks = (chunk_len - ite) / 64
    let data1_len = n_blocks * 64
    let data2_len = chunk_len - data1_len
    update_multi(
      self.block_state,
      {
        chunk[diff..]
      },
      n_blocks,
    )
    @mem.copy(
      self.buf,
      {
        chunk[diff + data1_len..]
      },
      data2_len,
    )
    self.total_len += chunk_len.to_int64()
  }
}

pub fn digest(self : SHA1) -> Bytes {
  let total_len = self.total_len
  let r = {
    let remainder = (total_len % 64L).to_int()
    if remainder == 0 && total_len > 0L {
      64
    } else {
      remainder
    }
  }
  let tmp_block_state = self.block_state.map(fn { x => x })
  update_last(
    tmp_block_state,
    total_len - r.to_int64(),
    {
      self.buf[..]
    },
    r,
  )
  finish(tmp_block_state)
}

test "basic" {
  let h = SHA1::make(init=Bytes::[1, 2, 3, 4, 5])
  h.update(Bytes::[6, 7, 8, 9, 10])
  inspect(
    h.digest(),
    content=Bytes::[
      197, 57, 30, 48, 138, 242, 91, 66, 213, 147, 77, 106, 32, 26, 52, 232, 152,
      210, 85, 198,
    ].to_string(),
  )?
}
