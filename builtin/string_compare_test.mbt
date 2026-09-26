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

// Differential tests for the code-unit ordering behind `Compare for String`,
// `Compare for StringView` and `StringView::lexical_compare`: every
// result must match a plain code-unit model, including for units above 0x7FFF
// (a signed lane compare would misorder them) and for views whose start and
// end sit inside a larger backing string.

///|
/// Builds a string with exactly these code units; a unit below 0x10000 is
/// written as one code unit even when it is a lone surrogate.
fn cmp_test_string(units : Array[UInt16]) -> String raise {
  let s = String::from_array(units.map(u => u.to_int().unsafe_to_char()))
  assert_eq(s.length(), units.length())
  s
}

///|
fn cmp_model_lexical(x : Array[UInt16], y : Array[UInt16]) -> Int {
  let n = if x.length() < y.length() { x.length() } else { y.length() }
  for i in 0..<n {
    if x[i] < y[i] {
      return -1
    }
    if x[i] > y[i] {
      return 1
    }
  }
  x.length().compare(y.length())
}

///|
fn cmp_model_shortlex(x : Array[UInt16], y : Array[UInt16]) -> Int {
  match x.length().compare(y.length()) {
    0 => cmp_model_lexical(x, y)
    order => order
  }
}

///|
/// Pairs `(lo, hi)` with `lo < hi` in code-unit order that the mismatch sweeps
/// plant: ASCII, the 0x7FFF/0x8000 sign boundary, surrogates against the BMP
/// private-use area above them, and the extremes.
let cmp_mismatch_pairs : Array[(UInt16, UInt16)] = [
  (0x61, 0x62),
  (0x7FFF, 0x8000),
  (0x61, 0xFFFF),
  (0x0000, 0xFFFF),
  (0xD83D, 0xE000),
  (0xDBFF, 0xDC00),
  (0x7F, 0xFFFE),
]

///|
/// A background unit for position `i`, varied so that equal blocks are not all
/// one repeated value.
fn cmp_fill(i : Int) -> UInt16 {
  match i % 5 {
    0 => 0x41
    1 => 0x8001
    2 => 0xD83D
    3 => 0xDE00
    _ => (0x61 + i % 26).to_uint16()
  }
}

///|
/// Checks all three entry points on strings `x`, `y` and on views of the same
/// contents at non-zero, different start offsets whose ends sit inside a
/// larger backing string, against the model.
fn cmp_check_all(x : Array[UInt16], y : Array[UInt16]) -> Unit raise {
  let sx = cmp_test_string(x)
  let sy = cmp_test_string(y)
  let shortlex = cmp_model_shortlex(x, y)
  let lexical = cmp_model_lexical(x, y)
  assert_eq(sx.compare(sy), shortlex)
  assert_eq(sy.compare(sx), -shortlex)
  assert_eq(sx.lexical_compare(sy), lexical)
  assert_eq(sy.lexical_compare(sx), -lexical)
  // Both views start at a shared 0x8000 unit placed just before the contents,
  // so they compare like `x` and `y` while starting at different offsets (and
  // `exact_view` never starts on a trailing surrogate). The trailing units
  // differ between the sides, so an over-read past a view end would change the
  // result.
  let px : Array[UInt16] = [0xFFFF, 0x0000, 0x8000]
  let py : Array[UInt16] = [0x0001, 0x8000]
  let bx = cmp_test_string(px + x + [0x0000, 0x0000, 0x0000, 0x0000])
  let by = cmp_test_string(py + y + [0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF])
  let vx = bx.exact_view(start=px.length() - 1, end=px.length() + x.length())
  let vy = by.exact_view(start=py.length() - 1, end=py.length() + y.length())
  assert_eq(vx.compare(vy), shortlex)
  assert_eq(vy.compare(vx), -shortlex)
  assert_eq(vx.lexical_compare(vy), lexical)
  assert_eq(vy.lexical_compare(vx), -lexical)
}

///|
test "string compare: mismatch at every position" {
  for len in 1..<=41 {
    let base = Array::makei(len, cmp_fill)
    for pos in 0..<len {
      for pair in cmp_mismatch_pairs {
        let (lo, hi) = pair
        let x = base.copy()
        let y = base.copy()
        x[pos] = lo
        y[pos] = hi
        cmp_check_all(x, y)
      }
    }
  }
}

///|
test "string compare: equal contents" {
  for len in 0..<=41 {
    let x = Array::makei(len, cmp_fill)
    cmp_check_all(x, x.copy())
    // Distinct strings with the same contents: no physical-equality shortcut.
    let s = cmp_test_string(x)
    let t = cmp_test_string(x.copy())
    assert_eq(s.compare(t), 0)
    assert_eq(s.lexical_compare(t), 0)
    assert_eq(s[:].compare(t), 0)
  }
}

///|
test "string compare: prefixes" {
  // `lexical_compare` of a string with its proper prefix, and shortlex order
  // between different lengths, for prefix lengths around the block sizes.
  for len in 0..<=41 {
    let long = Array::makei(len + 1 + len % 9, cmp_fill)
    let short = long[:len].to_owned()
    cmp_check_all(short, long)
  }
}

///|
test "string compare: views of one backing string" {
  // Views that overlap in one backing string, compared at every relative
  // shift; the reference is the model on the copied-out units.
  let units : Array[UInt16] = Array::makei(80, i => {
    if i % 7 == 3 {
      0xFFFF
    } else {
      0x61
    }
  })
  let s = cmp_test_string(units)
  for len in [0, 1, 7, 8, 9, 15, 16, 17, 24, 33, 40] {
    for a in 0..<(80 - len) {
      for b in [0, 1, 7, 8, 9, a] {
        guard b + len <= 80 else { continue }
        let x = units[a:a + len].to_owned()
        let y = units[b:b + len].to_owned()
        let va = s.exact_view(start=a, end=a + len)
        let vb = s.exact_view(start=b, end=b + len)
        assert_eq(va.compare(vb), cmp_model_shortlex(x, y))
        assert_eq(va.lexical_compare(vb), cmp_model_lexical(x, y))
      }
    }
  }
}

///|
test "string compare: code-unit order, not code-point order" {
  // U+E000 is one unit 0xE000; U+1F600 is the pair 0xD83D 0xDE00. Code-unit
  // order puts the pair first even though its code point is larger.
  let pua = "\u{E000}" + "x".repeat(20)
  let emoji = "😀" + "x".repeat(19)
  assert_eq(pua.length(), emoji.length())
  inspect(emoji.compare(pua), content="-1")
  inspect(pua.compare(emoji), content="1")
  inspect(emoji.lexical_compare(pua), content="-1")
  let long_prefix = "p".repeat(30)
  inspect(
    (long_prefix + "😀").lexical_compare(long_prefix + "\u{E000}"),
    content="-1",
  )
}

///|
/// Units for generated strings: few enough that long common prefixes are
/// frequent, including both sides of the 0x7FFF/0x8000 boundary and
/// surrogates.
fn cmp_alphabet(seed : Int) -> UInt16 {
  match seed & 7 {
    0 => 0x61
    1 => 0x62
    2 => 0x7FFF
    3 => 0x8000
    4 => 0xD800
    5 => 0xDC00
    6 => 0xFFFF
    _ => 0xE000
  }
}

///|
test "quickcheck: string compare agrees with the code-unit model" {
  @quickcheck.check(count=500, (
    input : (Array[Int], Array[Int], Array[Int], UInt),
  ) => {
    let (prefix_seeds, x_seeds, y_seeds, shape) = input
    // A common part of 17..80 units reaches the vector loop. With different
    // tails, the first mismatch (or the length difference) lands after it;
    // with one changed unit, it lands anywhere, including inside it.
    let prefix_len = 17 + ((shape >> 1) % 64).reinterpret_as_int()
    let prefix = Array::makei(prefix_len, i => {
      if prefix_seeds.is_empty() {
        cmp_alphabet(i)
      } else {
        cmp_alphabet(prefix_seeds[i % prefix_seeds.length()])
      }
    })
    let x = prefix + x_seeds.map(cmp_alphabet)
    let y = if (shape & 1) == 0 {
      prefix + y_seeds.map(cmp_alphabet)
    } else {
      // Same length as `x`, so shortlex order also reaches the unit loop.
      let y = x.copy()
      if !y_seeds.is_empty() && !y.is_empty() {
        let pos = (y_seeds[0] & 0x7FFFFFFF) % y.length()
        y[pos] = cmp_alphabet(y_seeds[0] >> 3)
      }
      y
    }
    cmp_check_all(x, y) catch {
      _ => return false
    }
    true
  })
}
