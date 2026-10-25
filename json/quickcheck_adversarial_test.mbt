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

// Adversarial property-based tests for the json package, complementing
// `quickcheck_test.mbt`:
//
// - well-formed strings built from adversarial characters (every control
//   character, JSON syntax characters, astral pairs), used both as values
//   and as object keys;
// - the fully `\uXXXX`-escaped spelling of those strings;
// - *lone surrogates* injected as `\uXXXX` escapes into such strings,
//   which the parser must always reject with a clean parse error (strings
//   stay Unicode well-formed) and never abort on;
// - textual zero literals (`-0`, `-0.0e7`, ...) which must preserve the
//   IEEE-754 sign of zero;
// - integer literals across the full Int64/UInt64 range, whose text must be
//   preserved exactly by `stringify` (via `repr`) beyond 2^53;
// - random legal whitespace inserted between tokens;
// - objects spelled with duplicate keys (last occurrence wins);
// - single-character deletions/replacements of valid documents, which must
//   never make the parser panic and must keep `parse` consistent with
//   `valid`.

///|
/// Characters drawn from pools that stress every branch of the escaper and
/// the string lexer: control characters (escaped as `\uXXXX` or short
/// escapes), JSON syntax characters, BMP boundary values, and astral code
/// points (surrogate pairs in UTF-16). Only Unicode scalar values appear
/// here — MoonBit strings stay Unicode well-formed, so unpaired surrogates
/// are spelled as ASCII escapes and asserted to be *rejected* by the parser.
fn adversarial_char_gen() -> @quickcheck.Generator[Char] {
  @quickcheck.frequency([
    // Every control character U+0000..U+001F.
    (3, @quickcheck.int_range(0, 0x20).map(i => i.unsafe_to_char())),
    // Characters that interact with JSON syntax and escaping.
    (
      3,
      @quickcheck.elements(['"', '\\', '/', '{', '}', '[', ']', ',', ':', ' ']),
    ),
    // BMP boundaries and astral code points (encoded as surrogate pairs).
    (
      2,
      @quickcheck.elements([
        '\u{7F}', '\u{80}', '\u{7FF}', '\u{800}', '\u{D7FF}', '\u{E000}', '\u{FFFD}',
        '\u{FFFF}', '\u{10000}', '\u{1F600}', '\u{10FFFF}',
      ]),
    ),
    // Ordinary ASCII so escapes sit inside unescaped runs.
    (3, @quickcheck.char_range('a', 'z')),
  ])
}

///|
fn adversarial_string_gen() -> @quickcheck.Generator[String] {
  @quickcheck.int_range(0, 24)
  .flat_map(n => adversarial_char_gen().array_with_size(n))
  .map(chars => String::from_array(chars))
}

///|
priv struct AdvString(String) derive(@debug.Debug)

///|
impl @quickcheck.Arbitrary for AdvString with fn arbitrary(size, state) {
  AdvString(adversarial_string_gen().run(size, state))
}

///|
/// Shrinks by dropping one character at a time. Working at the `Char` level
/// keeps every candidate Unicode well-formed, so a shrunk counterexample
/// fails for the same reason as the original instead of tripping the
/// parser's unpaired-surrogate rejection.
impl @shrink.Shrink for AdvString with fn shrink(self) {
  let chars = self.0.to_array()
  let n = chars.length()
  if n == 0 {
    return Iter::empty()
  }
  Iter::singleton(AdvString("")).concat(
    (0)
    .until(n)
    .map(i => {
      let copy = chars.copy()
      ignore(copy.remove(i))
      AdvString(String::from_array(copy))
    }),
  )
}

///|
/// The fully `\uXXXX`-escaped spelling of a string: every UTF-16 code unit
/// as a hex escape, with the digit case alternating per position.
fn fully_escaped(s : String) -> String {
  let hex_lower = "0123456789abcdef".to_array()
  let hex_upper = "0123456789ABCDEF".to_array()
  let buf = StringBuilder()
  buf.write_char('"')
  for i, unit in s.code_units() {
    let code = unit.to_int()
    let hex = if i % 2 == 0 { hex_lower } else { hex_upper }
    buf.write_char('\\')
    buf.write_char('u')
    buf.write_char(hex[(code >> 12) & 0xF])
    buf.write_char(hex[(code >> 8) & 0xF])
    buf.write_char(hex[(code >> 4) & 0xF])
    buf.write_char(hex[code & 0xF])
  }
  buf.write_char('"')
  buf.to_string()
}

///|
test "adversarial strings roundtrip as values and as object keys" {
  @quickcheck.check((input : (AdvString, AdvString, Int32, Bool)) => {
    let (key, value, raw_indent, escape_slash) = input
    let doc = Json::object(Map([(key.0, Json::array([Json::string(value.0)]))]))
    let text = doc.stringify(indent=wrap_index(raw_indent, 5), escape_slash~)
    @json.parse(text) == doc
  })
}

///|
/// Spells every UTF-16 code unit of the string as a `\uXXXX` escape
/// (alternating hex-digit case) and checks the parser reassembles the exact
/// original string — including surrogate pairs split across two escapes.
test "fully \\uXXXX-escaped strings parse back to the original" {
  @quickcheck.check((s : AdvString) => {
    @json.parse(fully_escaped(s.0)) == Json::string(s.0)
  })
}

///|
/// A lone surrogate spelled as a `\uXXXX` escape injected at any
/// position of an otherwise hostile string must always be rejected with a
/// clean parse error (`parse` raises, `valid` is false, nothing aborts):
/// parsed strings stay Unicode well-formed. The surrounding prefix/suffix
/// supply nearby escapes, astral pairs, and control characters, exercising
/// the slow path of the string lexer. The JSON source itself remains
/// well-formed UTF-16; no invalid Char or String is constructed.
test "escaped lone surrogates are rejected in every position" {
  @quickcheck.check((input : (AdvString, AdvString, Int32, Bool)) => {
    let (prefix, suffix, raw_unit, escape_surroundings) = input
    let unit = 0xD800 + wrap_index(raw_unit, 0x800)
    let before = if escape_surroundings {
      fully_escaped(prefix.0)
    } else {
      Json(prefix.0).stringify()
    }
    let after = if escape_surroundings {
      fully_escaped(suffix.0)
    } else {
      Json(suffix.0).stringify()
    }
    // Surrogate values always have exactly four hexadecimal digits.
    let text = before[:before.length() - 1].to_owned() +
      "\\u" +
      unit.to_string(radix=16) +
      after[1:].to_owned()
    parse_succeeds(text) == false && @json.valid(text) == false
  })
}

///|
/// Every spelling of zero (`-0`, `-0.00`, `-0e13`, `0.0E-7`, ...) must parse
/// to an IEEE-754 zero whose sign bit matches the literal's sign. The
/// integer spelling `-0` used to lose the sign because the integer fast path
/// negated an `Int64` (where `-0 == 0`) before converting to `Double`.
test "zero literals preserve the sign of zero" {
  @quickcheck.check((input : (Bool, Int32, Int32, Int32)) => {
    let (negative, raw_frac, raw_exp_kind, raw_exp) = input
    let text = StringBuilder()
    if negative {
      text.write_char('-')
    }
    text.write_char('0')
    let frac_digits = wrap_index(raw_frac, 4)
    if frac_digits > 0 {
      text.write_char('.')
      text.write_string("0".repeat(frac_digits))
    }
    match wrap_index(raw_exp_kind, 4) {
      0 => ()
      1 => text.write_string("e" + wrap_index(raw_exp, 400).to_string())
      2 => text.write_string("E+" + wrap_index(raw_exp, 400).to_string())
      _ => text.write_string("e-" + wrap_index(raw_exp, 400).to_string())
    }
    guard @json.parse(text.to_string()) is Number(n, ..) else { return false }
    n == 0.0 && (n.reinterpret_as_int64() < 0L) == negative
  })
}

///|
/// Integer literals over the full Int64/UInt64 range: `parse` must produce
/// the correctly rounded double, and `stringify` must reproduce the source
/// text exactly — beyond 2^53 that requires the preserved `repr`.
test "integer literals roundtrip through parse and stringify textually" {
  @quickcheck.check((x : Int64) => {
    let text = x.to_string()
    let parsed = @json.parse(text)
    parsed == Json::number(x.to_double()) && parsed.stringify() == text
  })
  @quickcheck.check((x : UInt64) => {
    let text = x.to_string()
    let parsed = @json.parse(text)
    parsed == Json::number(x.to_double()) && parsed.stringify() == text
  })
}

///|
/// Inserting random legal whitespace (space, tab, CR, LF) around structural
/// tokens never changes the parsed value.
test "whitespace between tokens does not change the parsed value" {
  @quickcheck.check((input : (ArbJson, UInt64)) => {
    let (json, seed) = input
    let rng = @quickcheck.RandomState(seed~)
    let ws : ReadOnlyArray[Char] = [' ', '\t', '\n', '\r']
    let text = json.0.stringify()
    let buf = StringBuilder()
    fn maybe_ws() {
      if rng.next_uint() % 2 == 0 {
        let n = (rng.next_uint() % 3).reinterpret_as_int()
        for _ in 0..<(n + 1) {
          buf.write_char(ws[(rng.next_uint() % 4).reinterpret_as_int()])
        }
      }
    }

    maybe_ws()
    let mut in_string = false
    let mut escaped = false
    for c in text {
      buf.write_char(c)
      if in_string {
        if escaped {
          escaped = false
        } else if c == '\\' {
          escaped = true
        } else if c == '"' {
          in_string = false
          maybe_ws()
        }
      } else {
        match c {
          '"' => in_string = true
          '[' | ']' | '{' | '}' | ',' | ':' => maybe_ws()
          _ => ()
        }
      }
    }
    maybe_ws()
    @json.parse(buf.to_string()) == json.0
  })
}

///|
/// Objects spelled with duplicate keys parse with the last occurrence of
/// each key winning, matching `Map` insert semantics.
test "duplicate object keys: last occurrence wins" {
  @quickcheck.check((entries : Array[(Int32, Int32)]) => {
    let text = StringBuilder()
    text.write_char('{')
    let expected : Map[String, Json] = Map([])
    for i, entry in entries {
      let (raw_key, value) = entry
      // A pool of three keys guarantees duplicates in most runs.
      let key = "k" + wrap_index(raw_key, 3).to_string()
      if i > 0 {
        text.write_char(',')
      }
      text.write_string("\"" + key + "\":" + value.to_string())
      expected[key] = Json::number(value.to_double())
    }
    text.write_char('}')
    @json.parse(text.to_string()) == Json::object(expected)
  })
}

///|
/// Deleting or replacing one Unicode scalar value of a valid document must keep
/// the parser total: it either succeeds or raises a parse error (`valid`
/// agrees with `parse`), and when the mutant still parses, the parsed value
/// is a fixed point of restringify-and-reparse.
///
/// Mutations preserve the well-formed UTF-16 contract of String/StringView,
/// even when the document contains astral characters.
test "parse stays total under single character deletion and replacement" {
  @quickcheck.check((input : (ArbJson, Int32, Char)) => {
    let (json, position, replacement) = input
    let chars = json.0.stringify().to_array()
    guard chars.length() > 0 else { return true }
    let idx = wrap_index(position, chars.length())
    let deleted = StringBuilder()
    let replaced = StringBuilder()
    for i, c in chars {
      if i != idx {
        deleted.write_char(c)
        replaced.write_char(c)
      } else {
        replaced.write_char(replacement)
      }
    }
    for mutant in [deleted.to_string(), replaced.to_string()] {
      guard parse_succeeds(mutant) == @json.valid(mutant) else { return false }
      if @json.valid(mutant) {
        let value = @json.parse(mutant)
        guard @json.parse(value.stringify()) == value else { return false }
      }
    }
    true
  })
}

///|
/// The default nesting limit is exactly 1024: a document 1024 levels deep
/// parses (and roundtrips), 1025 levels raises `DepthLimitExceeded`, for
/// both arrays and objects. Also pins that `stringify` itself is iterative
/// and survives a 1024-deep tree on every backend.
test "default nesting limit boundary at depth 1024" {
  fn outcome(text : String) -> String {
    try {
      ignore(@json.parse(text))
      "parsed"
    } catch {
      DepthLimitExceeded => "depth limit"
      _ => "other error"
    }
  }

  let deep_array = "[".repeat(1024) + "0" + "]".repeat(1024)
  assert_eq(outcome(deep_array), "parsed")
  let too_deep_array = "[".repeat(1025) + "0" + "]".repeat(1025)
  assert_eq(outcome(too_deep_array), "depth limit")
  let deep_object = "{\"k\":".repeat(1024) + "0" + "}".repeat(1024)
  assert_eq(outcome(deep_object), "parsed")
  let too_deep_object = "{\"k\":".repeat(1025) + "0" + "}".repeat(1025)
  assert_eq(outcome(too_deep_object), "depth limit")
  inspect(@json.parse(deep_array).stringify() == deep_array, content="true")
  inspect(@json.parse(deep_object).stringify() == deep_object, content="true")
  let mut tree : Json = Json::number(0.0)
  for _ in 0..<1024 {
    tree = Json::array([tree])
  }
  assert_true(@json.parse(tree.stringify()) == tree)
}

///|
/// Deterministic pins for the surrogate cases the properties above explore
/// randomly, so a regression shows up with a readable diff. Parsed strings
/// stay Unicode well-formed: every unpaired surrogate escape is
/// a clean parse error, never an abort and never an ill-formed string.
test "surrogate handling pins" {
  // Escaped lone surrogates.
  assert_false(@json.valid("\"\\uD800\""))
  assert_false(@json.valid("\"\\uDC00\""))
  assert_false(@json.valid("\"\\uD800\\uD800\""))
  assert_false(@json.valid("\"\\uDC00\\uD800\""))
  // A complete raw pair cannot supply the missing escaped half.
  assert_false(@json.valid("\"\\uD800😀\""))
  assert_false(@json.valid("\"😀\\uDC00\""))
  // Well-formed pairs still parse, raw or escaped.
  assert_true(@json.parse("\"\\uD83D\\uDE00\"") == Json::string("\u{1F600}"))
  assert_true(@json.parse("\"\u{1F600}\"") == Json::string("\u{1F600}"))
}

///|
/// Astral pairs and escapes near the scalar/SIMD thresholds must survive
/// both ordinary parsing and parsing a view with a nonzero start offset.
test "long adversarial strings roundtrip across scan and view boundaries" {
  for
    padding in [
      0, 1, 7, 8, 15, 16, 30, 31, 32, 33, 126, 127, 128, 129, 255, 256, 257,
    ] {
    for
      middle in [
        "😀", "😀\\\n", "\\\n😀", "\u{10FFFF}\u{0}\u{D7FF}\u{E000}",
      ] {
      let s = "x".repeat(padding) + middle + "y".repeat(260 - padding)
      let doc = Json::object(Map([(s, Json(s))]))
      let text = doc.stringify()
      assert_eq(@json.parse(text), doc)
      let padded = "😀abc" + text + "xyz😀"
      assert_eq(@json.parse(padded[5:5 + text.length()]), doc)
      assert_eq(@json.parse(fully_escaped(s)), Json(s))
    }
  }
}
