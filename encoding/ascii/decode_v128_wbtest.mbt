// Copyright 2026 International Digital Economy Academy
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
fn v128_outcome(view : BytesView) -> (String?, Bytes?) {
  (Some(decode_v128(view)), None) catch {
    Malformed(rest) => (None, Some(rest.to_owned()))
  }
}

///|
fn scalar_outcome(view : BytesView) -> (String?, Bytes?) {
  (Some(decode_scalar(view)), None) catch {
    Malformed(rest) => (None, Some(rest.to_owned()))
  }
}

///|
/// The SIMD decoder must agree with the scalar decoder — same string on
/// success, same remaining view on failure — on arbitrary payloads seen
/// through views with arbitrary (unaligned) start offsets.
test "quickcheck: V128 decode agrees with scalar decode" {
  @quickcheck.check(count=300, (input : (Array[Int], Int, Bool)) => {
    let (seeds, pad_seed, all_valid) = input
    let payload = seeds.map(seed => {
      if all_valid || (seed & 0xF) != 0xF {
        (seed & 0x7F).to_byte()
      } else {
        (0x80 | (seed & 0x7F)).to_byte()
      }
    })
    let pad = pad_seed % 17
    let pad = if pad < 0 { pad + 17 } else { pad }
    let full : Array[Byte] = []
    for _ in 0..<pad {
      full.push(b'\xFF')
    }
    full.append(payload)
    for _ in 0..<16 {
      full.push(b'\xFF')
    }
    let view = Bytes::from_array(full)[pad:pad + payload.length()]
    v128_outcome(view) == scalar_outcome(view)
  })
}

///|
test "V128 decode handles a view and scalar tail" {
  let bytes = b"!0123456789ABCDEF?"
  inspect(decode_v128(bytes[1:]), content="0123456789ABCDEF?")
}

///|
test "V128 decode reports the first non-ASCII byte in a block" {
  let bytes = b"0123456789ABC\xffDEF"
  try {
    let _ = decode_v128(bytes)
    panic()
  } catch {
    Malformed(rest) =>
      inspect(
        rest,
        content=(
          #|b"\xffDEF"
        ),
      )
  }
}
