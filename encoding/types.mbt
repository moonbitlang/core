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

///|
typealias Cont = (Decoder) -> Decode

///|
pub(all) enum Encoding {
  UTF8
  UTF16
  UTF16BE
  UTF16LE
}

// Decoder

///|
priv struct Decoder {
  mut i : @buffer.T
  mut i_pos : Int
  mut i_max : Int
  t : @buffer.T
  mut t_len : Int
  mut t_need : Int
  mut k : Cont
}

///|
priv enum Decode {
  End
  Malformed(String)
  Uchar(Char)
}

///|
fn malformed(buf : @buffer.T, offset : Int, length : Int) -> Decode {
  Malformed(buf.to_unchecked_string(offset~, length~))
}

///|
fn malformed_pair(
  be : Bool,
  hi : Int,
  buf : @buffer.T,
  offset : Int,
  length : Int
) -> Decode {
  let bs1 = buf.to_unchecked_string(offset~, length~).to_bytes()
  let bs0 = @buffer.new(size_hint=2)
  let (j0, j1) = if be { (0, 1) } else { (1, 0) }
  bs0[j0] = (hi >> 8).to_byte()
  bs0[j1] = hi.land(0xFF).to_byte()
  let arr = bs0.to_array()
  arr.append(bs1.to_array())
  let bs = @buffer.from_array(arr)
  Malformed(bs.to_unchecked_string(offset=0, length=bs.length()))
}

// Stream

///|
struct Stream {
  decoder : Decoder
  lossy : Bool
}

///|
pub fn iter(self : Stream) -> Iter[Char] {
  Iter::new(
    fn(yield_) {
      loop self.decoder.decode() {
        Uchar(u) => {
          if yield_(u) == IterEnd {
            break IterEnd
          }
          continue self.decoder.decode()
        }
        Malformed(s) => {
          if not(self.lossy) {
            abort(s)
          }
          if yield_(U_REP) == IterEnd {
            break IterEnd
          }
          continue self.decoder.decode()
        }
        End => break IterEnd
      }
    },
  )
}
