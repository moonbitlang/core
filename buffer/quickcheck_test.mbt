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

// A byte-level reference model for `Buffer`: every write op appends its
// documented encoding to a plain `Array[Byte]`, and `contents()` must agree
// with the model exactly.

///|
fn model_push_bytes(model : Array[Byte], bytes : BytesView) -> Unit {
  for b in bytes {
    model.push(b)
  }
}

///|
fn model_push_uint16_le(model : Array[Byte], value : Int) -> Unit {
  model.push((value & 0xFF).to_byte())
  model.push(((value >> 8) & 0xFF).to_byte())
}

///|
fn model_push_uint16_be(model : Array[Byte], value : Int) -> Unit {
  model.push(((value >> 8) & 0xFF).to_byte())
  model.push((value & 0xFF).to_byte())
}

///|
fn model_push_uint_le(model : Array[Byte], value : UInt) -> Unit {
  model.push(value.to_byte())
  model.push((value >> 8).to_byte())
  model.push((value >> 16).to_byte())
  model.push((value >> 24).to_byte())
}

///|
fn model_push_uint_be(model : Array[Byte], value : UInt) -> Unit {
  model.push((value >> 24).to_byte())
  model.push((value >> 16).to_byte())
  model.push((value >> 8).to_byte())
  model.push(value.to_byte())
}

///|
fn model_push_uint64_le(model : Array[Byte], value : UInt64) -> Unit {
  for i in 0..<8 {
    model.push((value >> (8 * i)).to_byte())
  }
}

///|
fn model_push_uint64_be(model : Array[Byte], value : UInt64) -> Unit {
  for i in 0..<8 {
    model.push((value >> (8 * (7 - i))).to_byte())
  }
}

///|
/// UTF-16LE: each code unit is written low byte first; supplementary
/// characters are already surrogate pairs in the code-unit sequence.
fn model_push_string_utf16le(model : Array[Byte], s : String) -> Unit {
  for cu in s.code_units() {
    model_push_uint16_le(model, cu.to_int())
  }
}

///|
fn model_bytes(model : Array[Byte]) -> Bytes {
  Bytes::from_array(model)
}

///|
/// Deterministic pseudo-random payload so op-driven tests can request
/// payloads of any size from a single Int seed.
fn payload(seed : Int, len : Int) -> Bytes {
  Bytes::makei(len, i => ((seed + i * 131) & 0xFF).to_byte())
}

///|
/// Sample strings for the op interpreter: empty, ASCII, 2-byte and 3-byte
/// UTF-8 range chars, and a supplementary-plane char (surrogate pair).
let sample_strings : Array[String] = [
  "", "hello", "héllo wörld", "中文字符串", "a𝄞b🎸c",
]

///|
test "quickcheck: op sequences agree with an Array[Byte] model" {
  @quickcheck.check(
    (ops : Array[(Int, Int)]) => {
      let buf = Buffer()
      let model : Array[Byte] = []
      for op in ops {
        let x = op.1
        match op.0 & 7 {
          0 => {
            buf.write_byte(x.to_byte())
            model.push(x.to_byte())
          }
          1 => {
            // Payload lengths 0..=511 mixed with single-byte ops walk the
            // capacity-doubling path repeatedly.
            let data = payload(x, x & 0x1FF)
            buf.write_bytes(data)
            model_push_bytes(model, data)
          }
          2 => {
            let s = sample_strings[(x & 0x7FFFFFFF) % sample_strings.length()]
            buf.write_string_utf16le(s)
            model_push_string_utf16le(model, s)
          }
          3 => {
            buf.write_int_le(x)
            model_push_uint_le(model, x.reinterpret_as_uint())
          }
          4 => {
            buf.write_int_be(x)
            model_push_uint_be(model, x.reinterpret_as_uint())
          }
          5 => {
            buf.write_uint16_le(x.to_uint16())
            model_push_uint16_le(model, x.to_uint16().to_int())
            buf.write_uint16_be(x.to_uint16())
            model_push_uint16_be(model, x.to_uint16().to_int())
          }
          6 => {
            buf.write_int64_be(x.to_int64() * 0x9E3779B97F4A7C15L)
            model_push_uint64_be(
              model,
              (x.to_int64() * 0x9E3779B97F4A7C15L).reinterpret_as_uint64(),
            )
          }
          _ => {
            buf.write_double_le(x.to_double() * 0.001)
            model_push_uint64_le(
              model,
              (x.to_double() * 0.001).reinterpret_as_uint64(),
            )
          }
        }
        // Length must be tracked correctly after EVERY op.
        guard buf.length() == model.length() &&
          buf.is_empty() == model.is_empty() else {
          return false
        }
      }
      buf.contents() == model_bytes(model)
    },
    count=300,
  )
}

///|
test "quickcheck: multi-width integer writes reconstruct the original value" {
  @quickcheck.check(
    (input : (Int, Int64, UInt, Double)) => {
      let (i, l, u, d) = input
      let buf = Buffer()
      buf.write_int_le(i)
      buf.write_int_be(i)
      buf.write_int64_le(l)
      buf.write_int64_be(l)
      buf.write_uint_le(u)
      buf.write_uint_be(u)
      buf.write_double_le(d)
      buf.write_double_be(d)
      buf.write_uint16_le(i.to_uint16())
      buf.write_uint16_be(i.to_uint16())
      guard buf.length() == 4 + 4 + 8 + 8 + 4 + 4 + 8 + 8 + 2 + 2 else {
        return false
      }
      let b = buf.contents()
      fn u32_le(off : Int) -> UInt {
        b[off].to_uint() |
        (b[off + 1].to_uint() << 8) |
        (b[off + 2].to_uint() << 16) |
        (b[off + 3].to_uint() << 24)
      }

      fn u32_be(off : Int) -> UInt {
        (b[off].to_uint() << 24) |
        (b[off + 1].to_uint() << 16) |
        (b[off + 2].to_uint() << 8) |
        b[off + 3].to_uint()
      }

      fn u64_le(off : Int) -> UInt64 {
        let mut acc : UInt64 = 0
        for k in 0..<8 {
          acc = acc | (b[off + k].to_uint64() << (8 * k))
        }
        acc
      }

      fn u64_be(off : Int) -> UInt64 {
        let mut acc : UInt64 = 0
        for k in 0..<8 {
          acc = (acc << 8) | b[off + k].to_uint64()
        }
        acc
      }

      // A byte-order or sign-extension bug in any variant shows here.
      u32_le(0).reinterpret_as_int() == i &&
      u32_be(4).reinterpret_as_int() == i &&
      u64_le(8).reinterpret_as_int64() == l &&
      u64_be(16).reinterpret_as_int64() == l &&
      u32_le(24) == u &&
      u32_be(28) == u &&
      u64_le(32) == d.reinterpret_as_uint64() &&
      u64_be(40) == d.reinterpret_as_uint64() &&
      (b[48].to_int() | (b[49].to_int() << 8)) == i.to_uint16().to_int() &&
      ((b[50].to_int() << 8) | b[51].to_int()) == i.to_uint16().to_int()
    },
    count=300,
  )
}

///|
test "quickcheck: write_bytesview of any slice equals writing the sliced copy" {
  @quickcheck.check(
    (input : (Bytes, Int, Int)) => {
      let (data, a, b) = input
      let n = data.length()
      // Derive an arbitrary valid (offset, length) pair, including empty
      // slices at every position.
      let start = (a & 0x7FFFFFFF) % (n + 1)
      let len = (b & 0x7FFFFFFF) % (n - start + 1)
      let buf = Buffer()
      buf.write_bytesview(data[start:start + len])
      let model : Array[Byte] = []
      for i in start..<(start + len) {
        model.push(data[i])
      }
      buf.length() == len && buf.contents() == model_bytes(model)
    },
    count=300,
  )
}

///|
test "quickcheck: utf16le string writes concatenate like their model" {
  @quickcheck.check(
    (input : (String, String)) => {
      let (s1, s2) = input
      let buf = Buffer()
      buf.write_string_utf16le(s1)
      guard buf.length() == s1.length() * 2 else { return false }
      buf.write_string_utf16le(s2)
      let model : Array[Byte] = []
      model_push_string_utf16le(model, s1)
      model_push_string_utf16le(model, s2)
      buf.length() == (s1.length() + s2.length()) * 2 &&
      buf.contents() == model_bytes(model)
    },
    count=300,
  )
}

///|
test "quickcheck: reset makes the buffer behave as fresh" {
  @quickcheck.check(
    (input : (Bytes, Bytes)) => {
      let (pre, post) = input
      let buf = Buffer()
      buf.write_bytes(pre)
      buf.write_double_be(1.5)
      buf.reset()
      guard buf.length() == 0 &&
        buf.is_empty() &&
        buf.contents() == b"" &&
        buf.view().length() == 0 else {
        return false
      }
      // Writes after reset must be indistinguishable from a fresh buffer.
      buf.write_bytes(post)
      buf.length() == post.length() && buf.contents() == post
    },
    count=200,
  )
}

///|
test "quickcheck: size_hint never affects observable contents" {
  @quickcheck.check(
    (chunks : Array[Bytes]) => {
      let hints = [0, 1, 7, 4096]
      let results : Array[Bytes] = []
      for hint in hints {
        let buf = Buffer(size_hint=hint)
        for chunk in chunks {
          buf.write_bytes(chunk)
          buf.write_byte(b'\xAB')
        }
        results.push(buf.contents())
      }
      for r in results {
        if r != results[0] {
          return false
        }
      }
      true
    },
    count=200,
  )
}

///|
test "quickcheck: contents() is non-destructive and writes append after it" {
  @quickcheck.check(
    (input : (Bytes, Bytes)) => {
      let (first, second) = input
      let buf = Buffer()
      buf.write_bytes(first)
      let c1 = buf.contents()
      let c2 = buf.contents()
      guard c1 == first && c2 == first && buf.length() == first.length() else {
        return false
      }
      // Further writes append correctly after an observation.
      buf.write_bytes(second)
      let model : Array[Byte] = []
      model_push_bytes(model, first)
      model_push_bytes(model, second)
      buf.contents() == model_bytes(model) && c1 == first
    },
    count=200,
  )
}
