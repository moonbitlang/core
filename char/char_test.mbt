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
test "to_string" {
  inspect('a'.to_string(), content="a")
}

///|
test "show output" {
  fn repr(chr) {
    let buf = StringBuilder::new(size_hint=0)
    Show::output(chr, buf)
    buf.to_string()
  }

  inspect(repr('a'), content="'a'")
  inspect(repr('\''), content="'\\''")
  inspect(repr('"'), content="'\"'")
  inspect(repr('\\'), content="'\\\\'")
  inspect(repr('\n'), content="'\\n'")
  inspect(repr('\r'), content="'\\r'")
  inspect(repr('\b'), content="'\\b'")
  inspect(repr('\t'), content="'\\t'")
  assert_eq(repr((0).unsafe_to_char()), "'\\u{00}'")
}

///|
struct TestHash {
  x : Char
} derive(Hash, Eq, Show)

///|
test "Char hash function with struct" {
  let m = {}
  m[{ x: 'a' }] = '3'
  m[{ x: 'b' }] = '3'
  inspect(m, content="{{x: 'a'}: '3', {x: 'b'}: '3'}")
}

///|
test "Char hash" {
  let m = {}
  m['a'] = '3'
  m['b'] = '3'
  inspect(m, content="{'a': '3', 'b': '3'}")
}

///|
test "is_ascii" {
  let ascii = 'a'
  let non_ascii = '❤'
  assert_true(ascii.is_ascii())
  assert_false(non_ascii.is_ascii())
}

///|
test "is_ascii_alphabetic" {
  let uppercase_a = 'A'
  let uppercase_g = 'G'
  let a = 'a'
  let g = 'g'
  let zero = '0'
  let percent = '%'
  let space = ' '
  let lf = '\n'
  let esc = '\u{1B}'
  assert_true(uppercase_a.is_ascii_alphabetic())
  assert_true(uppercase_g.is_ascii_alphabetic())
  assert_true(a.is_ascii_alphabetic())
  assert_true(g.is_ascii_alphabetic())
  assert_false(zero.is_ascii_alphabetic())
  assert_false(percent.is_ascii_alphabetic())
  assert_false(space.is_ascii_alphabetic())
  assert_false(lf.is_ascii_alphabetic())
  assert_false(esc.is_ascii_alphabetic())
}

///|
test "is_ascii_control" {
  let uppercase_a = 'A'
  let uppercase_g = 'G'
  let a = 'a'
  let g = 'g'
  let zero = '0'
  let percent = '%'
  let space = ' '
  let lf = '\n'
  let esc = '\u{1B}'
  assert_false(uppercase_a.is_ascii_control())
  assert_false(uppercase_g.is_ascii_control())
  assert_false(a.is_ascii_control())
  assert_false(g.is_ascii_control())
  assert_false(zero.is_ascii_control())
  assert_false(percent.is_ascii_control())
  assert_false(space.is_ascii_control())
  assert_true(lf.is_ascii_control())
  assert_true(esc.is_ascii_control())
}

///|
test "is_ascii_graphic" {
  let uppercase_a = 'A'
  let uppercase_g = 'G'
  let a = 'a'
  let g = 'g'
  let zero = '0'
  let percent = '%'
  let space = ' '
  let lf = '\n'
  let esc = '\u{1B}'
  assert_true(uppercase_a.is_ascii_graphic())
  assert_true(uppercase_g.is_ascii_graphic())
  assert_true(a.is_ascii_graphic())
  assert_true(g.is_ascii_graphic())
  assert_true(zero.is_ascii_graphic())
  assert_true(percent.is_ascii_graphic())
  assert_false(space.is_ascii_graphic())
  assert_false(lf.is_ascii_graphic())
  assert_false(esc.is_ascii_graphic())
}

///|
test "is_ascii_hexdigit" {
  let uppercase_a = 'A'
  let uppercase_g = 'G'
  let a = 'a'
  let g = 'g'
  let zero = '0'
  let percent = '%'
  let space = ' '
  let lf = '\n'
  let esc = '\u{1B}'
  assert_true(uppercase_a.is_ascii_hexdigit())
  assert_false(uppercase_g.is_ascii_hexdigit())
  assert_true(a.is_ascii_hexdigit())
  assert_false(g.is_ascii_hexdigit())
  assert_true(zero.is_ascii_hexdigit())
  assert_false(percent.is_ascii_hexdigit())
  assert_false(space.is_ascii_hexdigit())
  assert_false(lf.is_ascii_hexdigit())
  assert_false(esc.is_ascii_hexdigit())
}

///|
test "is_ascii_lowercase" {
  let uppercase_a = 'A'
  let uppercase_g = 'G'
  let a = 'a'
  let g = 'g'
  let zero = '0'
  let percent = '%'
  let space = ' '
  let lf = '\n'
  let esc = '\u{1B}'
  assert_false(uppercase_a.is_ascii_lowercase())
  assert_false(uppercase_g.is_ascii_lowercase())
  assert_true(a.is_ascii_lowercase())
  assert_true(g.is_ascii_lowercase())
  assert_false(zero.is_ascii_lowercase())
  assert_false(percent.is_ascii_lowercase())
  assert_false(space.is_ascii_lowercase())
  assert_false(lf.is_ascii_lowercase())
  assert_false(esc.is_ascii_lowercase())
}

///|
test "is_ascii_octdigit" {
  let uppercase_a = 'A'
  let a = 'a'
  let zero = '0'
  let seven = '7'
  let nine = '9'
  let percent = '%'
  let lf = '\n'
  assert_false(uppercase_a.is_ascii_octdigit())
  assert_false(a.is_ascii_octdigit())
  assert_true(zero.is_ascii_octdigit())
  assert_true(seven.is_ascii_octdigit())
  assert_false(nine.is_ascii_octdigit())
  assert_false(percent.is_ascii_octdigit())
  assert_false(lf.is_ascii_octdigit())
}

///|
test "is_ascii_punctuation" {
  let uppercase_a = 'A'
  let uppercase_g = 'G'
  let a = 'a'
  let g = 'g'
  let zero = '0'
  let percent = '%'
  let space = ' '
  let lf = '\n'
  let esc = '\u{1B}'
  assert_false(uppercase_a.is_ascii_punctuation())
  assert_false(uppercase_g.is_ascii_punctuation())
  assert_false(a.is_ascii_punctuation())
  assert_false(g.is_ascii_punctuation())
  assert_false(zero.is_ascii_punctuation())
  assert_true(percent.is_ascii_punctuation())
  assert_false(space.is_ascii_punctuation())
  assert_false(lf.is_ascii_punctuation())
  assert_false(esc.is_ascii_punctuation())
}

///|
test "is_ascii_uppercase" {
  let uppercase_a = 'A'
  let uppercase_g = 'G'
  let a = 'a'
  let g = 'g'
  let zero = '0'
  let percent = '%'
  let space = ' '
  let lf = '\n'
  let esc = '\u{1B}'
  assert_true(uppercase_a.is_ascii_uppercase())
  assert_true(uppercase_g.is_ascii_uppercase())
  assert_false(a.is_ascii_uppercase())
  assert_false(g.is_ascii_uppercase())
  assert_false(zero.is_ascii_uppercase())
  assert_false(percent.is_ascii_uppercase())
  assert_false(space.is_ascii_uppercase())
  assert_false(lf.is_ascii_uppercase())
  assert_false(esc.is_ascii_uppercase())
}

///|
test "is_ascii_whitespace" {
  let uppercase_a = 'A'
  let uppercase_g = 'G'
  let a = 'a'
  let g = 'g'
  let zero = '0'
  let percent = '%'
  let space = ' '
  let tab = '\t'
  let lf = '\n'
  let vt = '\u{0B}' // vertical tab
  let ff = '\u{0C}' // form feed
  let cr = '\r'
  let esc = '\u{1B}'
  assert_false(uppercase_a.is_ascii_whitespace())
  assert_false(uppercase_g.is_ascii_whitespace())
  assert_false(a.is_ascii_whitespace())
  assert_false(g.is_ascii_whitespace())
  assert_false(zero.is_ascii_whitespace())
  assert_false(percent.is_ascii_whitespace())
  assert_true(space.is_ascii_whitespace())
  assert_true(tab.is_ascii_whitespace())
  assert_true(lf.is_ascii_whitespace())
  assert_true(vt.is_ascii_whitespace())
  assert_true(ff.is_ascii_whitespace())
  assert_true(cr.is_ascii_whitespace())
  assert_false(esc.is_ascii_whitespace())
}

///|
test "is_control" {
  assert_true(''.is_control())
  assert_false('q'.is_control())
}

///|
test "is_digit" {
  inspect('a'.is_digit(11), content="true")
  inspect('a'.is_digit(12), content="true")
  inspect('a'.is_digit(13), content="true")
  inspect('a'.is_digit(14), content="true")
  inspect('a'.is_digit(15), content="true")
  inspect('a'.is_digit(16), content="true")
  inspect('A'.is_digit(11), content="true")
  inspect('B'.is_digit(12), content="true")
  inspect('C'.is_digit(13), content="true")
  inspect('D'.is_digit(14), content="true")
  inspect('E'.is_digit(15), content="true")
  inspect('F'.is_digit(16), content="true")
  inspect('A'.is_digit(8), content="false")
  inspect('1'.is_digit(2), content="true")
  inspect('z'.is_digit(36), content="true")
}

///|
test "panic on invalid radix" {
  ignore('a'.is_digit(1))
}

///|
test "is_numeric" {
  assert_true('٣'.is_numeric())
  assert_true('7'.is_numeric())
  assert_true('৬'.is_numeric())
  assert_true('¾'.is_numeric())
  assert_true('①'.is_numeric())
  assert_false('K'.is_numeric())
  assert_false('و'.is_numeric())
  assert_false('藏'.is_numeric())
  assert_false('三'.is_numeric())
}

///|
test "is_whitespace" {
  assert_true(' '.is_whitespace())
  // line break
  assert_true('\n'.is_whitespace())
  // a non-breaking space
  assert_true('\u{A0}'.is_whitespace())
  assert_false('越'.is_whitespace())
}

///|
test "is_printable" {
  // Printable ASCII characters
  let uppercase_a = 'A'
  let lowercase_a = 'a'
  let digit = '0'
  let punctuation = '!'
  let space = ' '

  // Non-printable ASCII characters
  let null = '\u{0000}'
  let escape = '\u{001B}'
  let delete = '\u{007F}'

  // Printable Unicode characters
  let emoji = '😀'
  let chinese = '中'
  let arabic = 'ا'
  let russian = 'Я'
  let greek = 'Ω'
  let tamil = 'க'
  let symbol = '♥'
  let math = '∑'
  let currency = '€'

  // Non-printable Unicode characters
  let zero_width_space = '\u{200B}'
  let left_to_right_mark = '\u{200E}'
  let private_use = '\u{E000}'
  let word_joiner = '\u{2060}'
  let variation_selector = '\u{FE00}'
  let soft_hyphen = '\u{00AD}'
  let musical_format = '\u{1D173}'
  let paragraph_separator = '\u{2029}'
  let byte_order_mark = '\u{FEFF}'

  // Test printable characters
  assert_true(uppercase_a.is_printable())
  assert_true(lowercase_a.is_printable())
  assert_true(digit.is_printable())
  assert_true(punctuation.is_printable())
  assert_true(space.is_printable())
  assert_true(emoji.is_printable())
  assert_true(chinese.is_printable())
  assert_true(arabic.is_printable())
  assert_true(russian.is_printable())
  assert_true(greek.is_printable())
  assert_true(tamil.is_printable())
  assert_true(symbol.is_printable())
  assert_true(math.is_printable())
  assert_true(currency.is_printable())
  assert_true(variation_selector.is_printable())

  // Test non-printable characters
  assert_false(null.is_printable())
  assert_false(escape.is_printable())
  assert_false(delete.is_printable())
  assert_false(zero_width_space.is_printable())
  assert_false(left_to_right_mark.is_printable())
  assert_false(private_use.is_printable())
  assert_false(word_joiner.is_printable())
  assert_false(soft_hyphen.is_printable())
  assert_false(musical_format.is_printable())
  assert_false(paragraph_separator.is_printable())
  assert_false(byte_order_mark.is_printable())
  inspect(
    ['\t', '\n', '\r', '\b', '\\'].map(Char::is_printable),
    content="[false, false, false, false, true]",
  )
}

///|
test "to ascii uppercase" {
  assert_eq('A', 'a'.to_ascii_uppercase())
  assert_eq('Z', 'z'.to_ascii_uppercase())
  assert_eq('A', 'A'.to_ascii_uppercase())
  assert_eq('Z', 'Z'.to_ascii_uppercase())
  assert_eq('_', '_'.to_ascii_uppercase())
  assert_eq('❤', '❤'.to_ascii_uppercase())
}

///|
test "to ascii lowercase" {
  assert_eq('a', 'A'.to_ascii_lowercase())
  assert_eq('z', 'Z'.to_ascii_lowercase())
  assert_eq('a', 'a'.to_ascii_lowercase())
  assert_eq('z', 'z'.to_ascii_lowercase())
  assert_eq('_', '_'.to_ascii_lowercase())
  assert_eq('❤', '❤'.to_ascii_lowercase())
}

///|
test "ToJson implementation" {
  // Test that to_json works without crashing for various characters
  let json_a = 'a'.to_json()
  let json_quote = '"'.to_json()
  // let json_backslash = '\\'.to_json()
  let json_newline = '\n'.to_json()
  let json_tab = '\t'.to_json()
  let json_null = '\u{0000}'.to_json()
  let json_unicode = '🚀'.to_json()

  // Basic validation that JSON objects were created
  assert_true(json_a != json_quote) // Different characters produce different JSON
  assert_true(json_newline != json_tab)
  assert_true(json_null != json_unicode)
}

///|
test "is_digit boundary cases with maximum radix" {
  // Test maximum valid radix (36)
  assert_true('z'.is_digit(36))
  assert_true('Z'.is_digit(36))
  assert_false('z'.is_digit(35))

  // Test minimum valid radix (2)
  assert_true('0'.is_digit(2))
  assert_true('1'.is_digit(2))
  assert_false('2'.is_digit(2))

  // Test digits at boundaries
  assert_true('9'.is_digit(10))
  assert_false('9'.is_digit(9))
  assert_true('a'.is_digit(11))
  assert_false('a'.is_digit(10))
}

///|
test "ASCII boundaries and edge characters" {
  // Test the exact boundary of ASCII range
  assert_true('\u{007F}'.is_ascii()) // Last ASCII character (DEL)
  assert_false('\u{0080}'.is_ascii()) // First non-ASCII character

  // Test control character boundaries
  assert_true('\u{001F}'.is_ascii_control()) // Last in first control range
  assert_false('\u{0020}'.is_ascii_control()) // SPACE (not control)
  assert_true('\u{007F}'.is_ascii_control()) // DEL character
  assert_false('\u{0080}'.is_ascii_control()) // Beyond ASCII

  // Test graphic character boundaries
  assert_true('\u{0021}'.is_ascii_graphic()) // First graphic character (!)
  assert_false('\u{0020}'.is_ascii_graphic()) // SPACE (not graphic)
  assert_true('\u{007E}'.is_ascii_graphic()) // Last graphic character (~)
  assert_false('\u{007F}'.is_ascii_graphic()) // DEL (not graphic)
}

///|
test "Unicode edge cases for numeric detection" {
  // Test various Unicode numeric characters
  assert_true('\u{00BC}'.is_numeric()) // ¼ (vulgar fraction one quarter)
  assert_true('\u{2160}'.is_numeric()) // Ⅰ (Roman numeral one)
  assert_true('\u{1D7CE}'.is_numeric()) // Mathematical monospace digit zero

  // Test non-numeric characters that might be confused with numbers
  assert_false('O'.is_numeric()) // Letter O (not zero)
  assert_false('l'.is_numeric()) // Letter l (not one)
  assert_false('I'.is_numeric()) // Letter I (not Roman numeral)
}

///|
test "Whitespace edge cases" {
  // Test all ASCII whitespace characters
  assert_true('\u{0009}'.is_ascii_whitespace()) // TAB
  assert_true('\u{000A}'.is_ascii_whitespace()) // LF
  assert_true('\u{000B}'.is_ascii_whitespace()) // VT
  assert_true('\u{000C}'.is_ascii_whitespace()) // FF
  assert_true('\u{000D}'.is_ascii_whitespace()) // CR
  assert_true('\u{0020}'.is_ascii_whitespace()) // SPACE

  // Test characters that are not ASCII whitespace
  assert_false('\u{00A0}'.is_ascii_whitespace()) // NBSP (Unicode whitespace but not ASCII)
  assert_false('\u{0085}'.is_ascii_whitespace()) // NEL (not ASCII)

  // But they should be Unicode whitespace
  assert_true('\u{00A0}'.is_whitespace()) // NBSP
  assert_true('\u{0085}'.is_whitespace()) // NEL
}

///|
test "Case conversion with non-letters" {
  // Test symbols and numbers remain unchanged
  assert_eq('0'.to_ascii_lowercase(), '0')
  assert_eq('9'.to_ascii_uppercase(), '9')
  assert_eq('!'.to_ascii_lowercase(), '!')
  assert_eq('@'.to_ascii_uppercase(), '@')
  assert_eq(' '.to_ascii_lowercase(), ' ')
  assert_eq(' '.to_ascii_uppercase(), ' ')

  // Test boundary letters
  assert_eq('A'.to_ascii_lowercase(), 'a')
  assert_eq('Z'.to_ascii_lowercase(), 'z')
  assert_eq('a'.to_ascii_uppercase(), 'A')
  assert_eq('z'.to_ascii_uppercase(), 'Z')
}
