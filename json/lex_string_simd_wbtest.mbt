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

// Tests for the string lexer's run scan (`find_string_special_long`, SIMD on
// native and wasm, where the lexer switches to it after checking 16 code units
// one at a time, or 17 after an escape): the lexer must agree with a
// one-code-unit-at-a-time reference on results, errors, error positions, and
// the final offset, at every position around those switch points and the
// 8-unit SIMD blocks, and inside views that start and end in the middle of a
// larger string.

///|
/// The string lexer as it was before the run scan: one code unit at a time in
/// the fast path, one character at a time via `read_char` after an escape.
fn ParseContext::lex_string_reference(
  ctx : ParseContext,
) -> String raise ParseError {
  let string_start = ctx.offset
  for i in string_start..<ctx.end_offset {
    let c = ctx.input.unsafe_get(i)
    if c == '"' {
      ctx.offset = i + 1
      let base = ctx.input.start_offset()
      return ctx.input
        .data()
        .unsafe_substring(start=base + string_start, end=base + i)
    } else if c == '\\' {
      return ctx.lex_string_slow_reference()
    } else if c < ' ' {
      ctx.offset = i + 1
      ctx.invalid_char(shift=-1)
    }
  }
  raise InvalidEof
}

///|
fn ParseContext::lex_string_slow_reference(
  ctx : ParseContext,
) -> String raise ParseError {
  let buf = StringBuilder()
  let mut start = ctx.offset
  fn flush(end : Int) {
    if start > 0 && end > start {
      buf.write_view(ctx.input[start:end])
    }
  }

  for ;; {
    match ctx.read_char() {
      Some('"') => {
        flush(ctx.offset - 1)
        break
      }
      Some('\\') => {
        flush(ctx.offset - 1)
        match ctx.read_char() {
          Some('b') => buf.write_char('\b')
          Some('f') => buf.write_char('\u{0C}')
          Some('n') => buf.write_char('\n')
          Some('r') => buf.write_char('\r')
          Some('t') => buf.write_char('\t')
          Some('"') => buf.write_char('"')
          Some('\\') => buf.write_char('\\')
          Some('/') => buf.write_char('/')
          Some('u') => {
            let escape_start = ctx.offset - 2
            let c = ctx.lex_hex_digits(4)
            if c is (0xD800..=0xDBFF) {
              match ctx.read_char() {
                Some('\\') => ()
                Some(_) => ctx.unpaired_surrogate(escape_start)
                None => raise InvalidEof
              }
              match ctx.read_char() {
                Some('u') => ()
                Some(_) => ctx.unpaired_surrogate(escape_start)
                None => raise InvalidEof
              }
              let c2 = ctx.lex_hex_digits(4)
              if c2 is (0xDC00..=0xDFFF) {
                let combined = (c << 10) + c2 - 0x35fdc00
                buf.write_char(combined.unsafe_to_char())
              } else {
                ctx.unpaired_surrogate(escape_start)
              }
            } else if c is (0xDC00..=0xDFFF) {
              ctx.unpaired_surrogate(escape_start)
            } else {
              buf.write_char(c.unsafe_to_char())
            }
          }
          Some(c) => ctx.invalid_char(shift=-c.utf16_len())
          None => raise InvalidEof
        }
        start = ctx.offset
      }
      Some(ch) =>
        if ch.to_int() < 32 {
          ctx.invalid_char(shift=-1)
        } else {
          continue
        }
      None => raise InvalidEof
    }
  }
  buf.to_string()
}

///|
/// Lexes the string whose opening quote is the first code unit of `input`,
/// returning the result and the offset the lexer stopped at.
///
/// The offset is reported as -1 after `InvalidEof`: that error carries no
/// position and the parser discards the context, and the reference itself
/// leaves different offsets behind depending on which path ran out of input.
fn lex_string_outcome(
  input : StringView,
  reference~ : Bool,
) -> (Result[String, ParseError], Int) {
  let ctx = ParseContext::make(input)
  ctx.offset = 1
  let result = Ok(
    if reference {
      ctx.lex_string_reference()
    } else {
      ctx.lex_string()
    },
  ) catch {
    err => Err(err)
  }
  (result, if result is Err(InvalidEof) { -1 } else { ctx.offset })
}

///|
/// Checks `lex_string` against the reference on `"` + `body`, both as a whole
/// string and as a view that starts at an odd offset and ends just before a
/// suffix containing a closing quote, a backslash and a control character,
/// which a scan reading past the view end would find.
#callsite(autofill(loc))
fn check_lex_string(body : String, loc~ : SourceLoc) -> Unit raise {
  let whole = "\"" + body
  @debug.assert_eq(
    lex_string_outcome(whole, reference=false),
    lex_string_outcome(whole, reference=true),
    loc~,
  )
  let padded = "xyz" + whole + "\"\\\n\"abcdefghijklmnop"
  let view = padded.exact_view(start=3, end=3 + whole.length())
  @debug.assert_eq(
    lex_string_outcome(view, reference=false),
    lex_string_outcome(view, reference=true),
    loc~,
  )
}

///|
/// Units that end a run, and units that must not: the neighbours of each
/// special unit, and units whose high or low byte is a special byte, which a
/// signed or 8-bit-lane comparison would misclassify.
let special_units : Array[UInt16] = ['"', '\\', '\n', 0x00, 0x1F]

///|
let near_miss_units : Array[UInt16] = [
  ' ', '!', '#', '[', ']', 0x7F, 0x8000, 0xFFFF, 0xFF22, 0x225C, 0x2200, 0x0120,
  0x805C, 0xE01F,
]

///|
fn string_of_units(units : Array[UInt16]) -> String {
  let buf = StringBuilder(size_hint=units.length())
  for unit in units {
    buf.write_char(unit.unsafe_to_char())
  }
  buf.to_string()
}

///|
test "lex_string: a special unit at every position" {
  for len in 0..<=40 {
    let plain = "a".repeat(len)
    // Unterminated: `InvalidEof`, and no reading past the view end.
    check_lex_string(plain)
    check_lex_string(plain + "\"")
    for pos in 0..<len {
      for special in special_units {
        let units = Array::make(len, ('a' : UInt16))
        units[pos] = special
        let body = string_of_units(units)
        check_lex_string(body)
        check_lex_string(body + "\"")
      }
      for unit in near_miss_units {
        let units = Array::make(len, ('a' : UInt16))
        units[pos] = unit
        check_lex_string(string_of_units(units) + "\"")
      }
    }
  }
}

///|
test "lex_string: escapes and runs after them at every position" {
  // After an escape the slow path scans again from just past it, so plant the
  // escape at every position and the terminator or error at every distance.
  let escapes = ["\\n", "\\\"", "\\u0041", "\\uD83D\\uDE00", "\\x", "\\uD800x"]
  for pos in 0..<=24 {
    for escape in escapes {
      for gap in 0..<=24 {
        let head = "a".repeat(pos) + escape + "b".repeat(gap)
        check_lex_string(head)
        check_lex_string(head + "\"")
        check_lex_string(head + "\n\"")
        check_lex_string(head + "\\t" + "c".repeat(20) + "\"")
      }
    }
  }
}

///|
test "lex_string: surrogate pairs straddling scan boundaries" {
  // Pairs are copied raw; place one across every prefix/block boundary.
  for pos in 0..<=40 {
    let body = "a".repeat(pos) + "\u{1F600}" + "b".repeat(40 - pos)
    check_lex_string(body + "\"")
    check_lex_string(body + "\\n\"")
    check_lex_string("\\n" + body + "\"")
    check_lex_string(body + "\n\"")
    check_lex_string(body)
  }
  // Raw unpaired surrogates in escape-free strings are preserved as they are.
  for pos in 0..<=24 {
    for unit in [(0xD800 : UInt16), 0xDBFF, 0xDC00, 0xDFFF] {
      let units = Array::make(32, ('a' : UInt16))
      units[pos] = unit
      let body = string_of_units(units)
      check_lex_string(body + "\"")
      let (result, _) = lex_string_outcome("\"" + body + "\"", reference=false)
      guard result is Ok(s) && s == body else { fail("expected \{body}") }
    }
  }
}

///|
/// Builds a string body from `seeds`: long literal runs that reach the SIMD
/// loop, mixed with escapes (valid and invalid), raw control characters,
/// quotes, surrogate pairs and near-miss units.
fn lex_string_body(seeds : Array[Int]) -> String {
  let buf = StringBuilder()
  for seed in seeds {
    let payload = (seed >> 5) & 0x7FFF
    match seed & 0x1F {
      0 => buf.write_char('"')
      1 => buf.write_char('\\')
      2 => buf.write_string("\\n")
      3 => buf.write_string("\\\"")
      4 => buf.write_string("\\u0041")
      5 => buf.write_string("\\uD83D\\uDE00")
      6 => buf.write_char('\n')
      7 => buf.write_char('\u{1F}')
      8 => buf.write_char('\u{00}')
      9 => buf.write_char(' ')
      10 => buf.write_char('\u{1F600}')
      11 => buf.write_char('\u{FF22}')
      12 => buf.write_char('\u{225C}')
      13 => buf.write_char('\u{805C}')
      14 => buf.write_char('\u{7F}')
      15 => buf.write_string("\\x")
      16 => buf.write_string("\\uD800x")
      17 => buf.write_string("\\u12")
      _ => {
        let c = (('a' : Int) + payload % 26).unsafe_to_char()
        for _ in 0..<(payload % 70) {
          buf.write_char(c)
        }
      }
    }
  }
  buf.to_string()
}

///|
test "quickcheck: lex_string agrees with the reference lexer" {
  @quickcheck.check(count=500, (seeds : Array[Int]) => {
    let body = lex_string_body(seeds)
    let whole = "\"" + body
    guard lex_string_outcome(whole, reference=false) ==
      lex_string_outcome(whole, reference=true) else {
      return false
    }
    let padded = "xyz" + whole + "\"\\\n"
    let view = padded.exact_view(start=3, end=3 + whole.length())
    lex_string_outcome(view, reference=false) ==
    lex_string_outcome(view, reference=true)
  })
}

///|
test "find_string_special_long agrees with the scalar reference" {
  // Every start and end of a backing string of near-miss units with a few
  // special units, so ranges end both just before and a few units before a
  // special unit, and long clean runs reach the SIMD blocks.
  let units = []
  for i in 0..<64 {
    units.push(
      if i is (5 | 26 | 27 | 43 | 52 | 63) {
        special_units[i % special_units.length()]
      } else {
        near_miss_units[i * 7 % near_miss_units.length()]
      },
    )
  }
  let backing = string_of_units(units)
  for start in 0..<=backing.length() {
    for end in start..<=backing.length() {
      @debug.assert_eq(
        find_string_special_long(backing, start, end),
        find_string_special_scalar(backing, start, end),
      )
    }
  }
}

///|
/// Calls the SIMD scan directly on the backends that have it, so its blocks,
/// lane selection and tail are tested without going through the scalar
/// prefix. (It checks results only; it cannot tell a scalar body apart.)
#cfg(any(target="native", target="wasm"))
test "find_string_special_long SIMD blocks and scalar tail" {
  for len in 0..<=40 {
    // The end is inside the backing string, with special units starting 0-3
    // units past it: never report a unit at or past the end.
    for gap in 0..<=3 {
      let plain = "a".repeat(len + gap) + "\"\\\n"
      for start in 0..<=len {
        @debug.assert_eq(find_string_special_long(plain, start, len), len)
      }
    }
    for pos in 0..<len {
      for special in special_units {
        let units = Array::make(len, ('a' : UInt16))
        units[pos] = special
        let str = string_of_units(units)
        for start in 0..<=pos {
          @debug.assert_eq(find_string_special_long(str, start, len), pos)
        }
      }
      for unit in near_miss_units {
        let units = Array::make(len, ('a' : UInt16))
        units[pos] = unit
        @debug.assert_eq(
          find_string_special_long(string_of_units(units), 0, len),
          len,
        )
      }
    }
  }
}
