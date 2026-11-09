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
    let buf = StringBuilder(capacity=0)
    Show::output(chr, buf)
    buf.to_string()
  }

  inspect(repr('a'), content="a")
  inspect(repr('\''), content="'")
  inspect(repr('"'), content="\"")
  inspect(repr('\\'), content="\\")
  inspect(repr('\n'), content="\n")
  inspect(repr('\r'), content="\r")
  inspect(repr('\b'), content="\b")
  inspect(repr('\t'), content="\t")
  inspect(repr('\u{00}'), content="\u{00}")
}

///|
#derive(Hash, Eq, Debug)
priv struct TestHash {
  x : Char
}

///|
test "Char hash function with struct" {
  let m = Map([])
  m[{ x: 'a', }] = '3'
  m[{ x: 'b', }] = '3'
  debug_inspect(
    m,
    content=(
      #|{ { x: 'a' }: '3', { x: 'b' }: '3' }
    ),
  )
}

///|
test "Char hash" {
  let m = Map([])
  m['a'] = '3'
  m['b'] = '3'
  debug_inspect(
    m,
    content=(
      #|{ 'a': '3', 'b': '3' }
    ),
  )
}

///|
test "is_ascii" {
  let ascii = 'a'
  let non_ascii = '❤'
  inspect(ascii.is_ascii(), content="true")
  inspect(non_ascii.is_ascii(), content="false")
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
  inspect(uppercase_a.is_ascii_alphabetic(), content="true")
  inspect(uppercase_g.is_ascii_alphabetic(), content="true")
  inspect(a.is_ascii_alphabetic(), content="true")
  inspect(g.is_ascii_alphabetic(), content="true")
  inspect(zero.is_ascii_alphabetic(), content="false")
  inspect(percent.is_ascii_alphabetic(), content="false")
  inspect(space.is_ascii_alphabetic(), content="false")
  inspect(lf.is_ascii_alphabetic(), content="false")
  inspect(esc.is_ascii_alphabetic(), content="false")
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
  inspect(uppercase_a.is_ascii_control(), content="false")
  inspect(uppercase_g.is_ascii_control(), content="false")
  inspect(a.is_ascii_control(), content="false")
  inspect(g.is_ascii_control(), content="false")
  inspect(zero.is_ascii_control(), content="false")
  inspect(percent.is_ascii_control(), content="false")
  inspect(space.is_ascii_control(), content="false")
  inspect(lf.is_ascii_control(), content="true")
  inspect(esc.is_ascii_control(), content="true")
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
  inspect(uppercase_a.is_ascii_graphic(), content="true")
  inspect(uppercase_g.is_ascii_graphic(), content="true")
  inspect(a.is_ascii_graphic(), content="true")
  inspect(g.is_ascii_graphic(), content="true")
  inspect(zero.is_ascii_graphic(), content="true")
  inspect(percent.is_ascii_graphic(), content="true")
  inspect(space.is_ascii_graphic(), content="false")
  inspect(lf.is_ascii_graphic(), content="false")
  inspect(esc.is_ascii_graphic(), content="false")
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
  inspect(uppercase_a.is_ascii_hexdigit(), content="true")
  inspect(uppercase_g.is_ascii_hexdigit(), content="false")
  inspect(a.is_ascii_hexdigit(), content="true")
  inspect(g.is_ascii_hexdigit(), content="false")
  inspect(zero.is_ascii_hexdigit(), content="true")
  inspect(percent.is_ascii_hexdigit(), content="false")
  inspect(space.is_ascii_hexdigit(), content="false")
  inspect(lf.is_ascii_hexdigit(), content="false")
  inspect(esc.is_ascii_hexdigit(), content="false")
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
  inspect(uppercase_a.is_ascii_lowercase(), content="false")
  inspect(uppercase_g.is_ascii_lowercase(), content="false")
  inspect(a.is_ascii_lowercase(), content="true")
  inspect(g.is_ascii_lowercase(), content="true")
  inspect(zero.is_ascii_lowercase(), content="false")
  inspect(percent.is_ascii_lowercase(), content="false")
  inspect(space.is_ascii_lowercase(), content="false")
  inspect(lf.is_ascii_lowercase(), content="false")
  inspect(esc.is_ascii_lowercase(), content="false")
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
  inspect(uppercase_a.is_ascii_octdigit(), content="false")
  inspect(a.is_ascii_octdigit(), content="false")
  inspect(zero.is_ascii_octdigit(), content="true")
  inspect(seven.is_ascii_octdigit(), content="true")
  inspect(nine.is_ascii_octdigit(), content="false")
  inspect(percent.is_ascii_octdigit(), content="false")
  inspect(lf.is_ascii_octdigit(), content="false")
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
  inspect(uppercase_a.is_ascii_punctuation(), content="false")
  inspect(uppercase_g.is_ascii_punctuation(), content="false")
  inspect(a.is_ascii_punctuation(), content="false")
  inspect(g.is_ascii_punctuation(), content="false")
  inspect(zero.is_ascii_punctuation(), content="false")
  inspect(percent.is_ascii_punctuation(), content="true")
  inspect(space.is_ascii_punctuation(), content="false")
  inspect(lf.is_ascii_punctuation(), content="false")
  inspect(esc.is_ascii_punctuation(), content="false")
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
  inspect(uppercase_a.is_ascii_uppercase(), content="true")
  inspect(uppercase_g.is_ascii_uppercase(), content="true")
  inspect(a.is_ascii_uppercase(), content="false")
  inspect(g.is_ascii_uppercase(), content="false")
  inspect(zero.is_ascii_uppercase(), content="false")
  inspect(percent.is_ascii_uppercase(), content="false")
  inspect(space.is_ascii_uppercase(), content="false")
  inspect(lf.is_ascii_uppercase(), content="false")
  inspect(esc.is_ascii_uppercase(), content="false")
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
  inspect(uppercase_a.is_ascii_whitespace(), content="false")
  inspect(uppercase_g.is_ascii_whitespace(), content="false")
  inspect(a.is_ascii_whitespace(), content="false")
  inspect(g.is_ascii_whitespace(), content="false")
  inspect(zero.is_ascii_whitespace(), content="false")
  inspect(percent.is_ascii_whitespace(), content="false")
  inspect(space.is_ascii_whitespace(), content="true")
  inspect(tab.is_ascii_whitespace(), content="true")
  inspect(lf.is_ascii_whitespace(), content="true")
  inspect(vt.is_ascii_whitespace(), content="true")
  inspect(ff.is_ascii_whitespace(), content="true")
  inspect(cr.is_ascii_whitespace(), content="true")
  inspect(esc.is_ascii_whitespace(), content="false")
}

///|
test "is_control" {
  inspect(
    'œ'.is_control(),
    content=(
      #|false
    ),
  )
  inspect('q'.is_control(), content="false")
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
  inspect('٣'.is_numeric(), content="true")
  inspect('7'.is_numeric(), content="true")
  inspect('৬'.is_numeric(), content="true")
  inspect('¾'.is_numeric(), content="true")
  inspect('①'.is_numeric(), content="true")
  inspect('K'.is_numeric(), content="false")
  inspect('و'.is_numeric(), content="false")
  inspect('藏'.is_numeric(), content="false")
  inspect('三'.is_numeric(), content="false")
}

///|
test "is_whitespace" {
  inspect(' '.is_whitespace(), content="true")
  // line break
  inspect('\n'.is_whitespace(), content="true")
  // a non-breaking space
  inspect('\u{A0}'.is_whitespace(), content="true")
  inspect('越'.is_whitespace(), content="false")
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
  inspect(uppercase_a.is_printable(), content="true")
  inspect(lowercase_a.is_printable(), content="true")
  inspect(digit.is_printable(), content="true")
  inspect(punctuation.is_printable(), content="true")
  inspect(space.is_printable(), content="true")
  inspect(emoji.is_printable(), content="true")
  inspect(chinese.is_printable(), content="true")
  inspect(arabic.is_printable(), content="true")
  inspect(russian.is_printable(), content="true")
  inspect(greek.is_printable(), content="true")
  inspect(tamil.is_printable(), content="true")
  inspect(symbol.is_printable(), content="true")
  inspect(math.is_printable(), content="true")
  inspect(currency.is_printable(), content="true")
  inspect(variation_selector.is_printable(), content="true")

  // Test non-printable characters
  inspect(null.is_printable(), content="false")
  inspect(escape.is_printable(), content="false")
  inspect(delete.is_printable(), content="false")
  inspect(zero_width_space.is_printable(), content="false")
  inspect(left_to_right_mark.is_printable(), content="false")
  inspect(private_use.is_printable(), content="false")
  inspect(word_joiner.is_printable(), content="false")
  inspect(soft_hyphen.is_printable(), content="false")
  inspect(musical_format.is_printable(), content="false")
  inspect(paragraph_separator.is_printable(), content="false")
  inspect(byte_order_mark.is_printable(), content="false")
  debug_inspect(
    ['\t', '\n', '\r', '\b', '\\'].map(c => c.is_printable()),
    content="[false, false, false, false, true]",
  )
}

///|
test "to ascii uppercase" {
  inspect('a'.to_ascii_uppercase(), content="A")
  inspect('z'.to_ascii_uppercase(), content="Z")
  inspect('A'.to_ascii_uppercase(), content="A")
  inspect('Z'.to_ascii_uppercase(), content="Z")
  inspect('_'.to_ascii_uppercase(), content="_")
  inspect('❤'.to_ascii_uppercase(), content="❤")
}

///|
test "to ascii lowercase" {
  inspect('A'.to_ascii_lowercase(), content="a")
  inspect('Z'.to_ascii_lowercase(), content="z")
  inspect('a'.to_ascii_lowercase(), content="a")
  inspect('z'.to_ascii_lowercase(), content="z")
  inspect('_'.to_ascii_lowercase(), content="_")
  inspect('❤'.to_ascii_lowercase(), content="❤")
}

///|
test "ToJson implementation" {
  // Test that to_json works without crashing for various characters
  let json_a = Json('a')
  let json_quote = Json('"')
  // let json_backslash = '\\'.to_json()
  let json_newline = Json('\n')
  let json_tab = Json('\t')
  let json_null = Json('\u{0000}')
  let json_unicode = Json('🚀')

  // Basic validation that JSON objects were created
  inspect(json_a != json_quote, content="true") // Different characters produce different JSON
  inspect(json_newline != json_tab, content="true")
  inspect(json_null != json_unicode, content="true")
}

///|
test "is_digit boundary cases with maximum radix" {
  // Test maximum valid radix (36)
  inspect('z'.is_digit(36), content="true")
  inspect('Z'.is_digit(36), content="true")
  inspect('z'.is_digit(35), content="false")

  // Test minimum valid radix (2)
  inspect('0'.is_digit(2), content="true")
  inspect('1'.is_digit(2), content="true")
  inspect('2'.is_digit(2), content="false")

  // Test digits at boundaries
  inspect('9'.is_digit(10), content="true")
  inspect('9'.is_digit(9), content="false")
  inspect('a'.is_digit(11), content="true")
  inspect('a'.is_digit(10), content="false")
}

///|
test "ASCII boundaries and edge characters" {
  // Test the exact boundary of ASCII range
  inspect('\u{007F}'.is_ascii(), content="true") // Last ASCII character (DEL)
  inspect('\u{0080}'.is_ascii(), content="false") // First non-ASCII character

  // Test control character boundaries
  inspect('\u{001F}'.is_ascii_control(), content="true") // Last in first control range
  inspect('\u{0020}'.is_ascii_control(), content="false") // SPACE (not control)
  inspect('\u{007F}'.is_ascii_control(), content="true") // DEL character
  inspect('\u{0080}'.is_ascii_control(), content="false") // Beyond ASCII

  // Test graphic character boundaries
  inspect('\u{0021}'.is_ascii_graphic(), content="true") // First graphic character (!)
  inspect('\u{0020}'.is_ascii_graphic(), content="false") // SPACE (not graphic)
  inspect('\u{007E}'.is_ascii_graphic(), content="true") // Last graphic character (~)
  inspect('\u{007F}'.is_ascii_graphic(), content="false") // DEL (not graphic)
}

///|
test "Unicode edge cases for numeric detection" {
  // Test various Unicode numeric characters
  inspect('\u{00BC}'.is_numeric(), content="true") // ¼ (vulgar fraction one quarter)
  inspect('\u{2160}'.is_numeric(), content="true") // Ⅰ (Roman numeral one)
  inspect('\u{1D7CE}'.is_numeric(), content="true") // Mathematical monospace digit zero

  // Test non-numeric characters that might be confused with numbers
  inspect('O'.is_numeric(), content="false") // Letter O (not zero)
  inspect('l'.is_numeric(), content="false") // Letter l (not one)
  inspect('I'.is_numeric(), content="false") // Letter I (not Roman numeral)
}

///|
test "Whitespace edge cases" {
  // Test all ASCII whitespace characters
  inspect('\u{0009}'.is_ascii_whitespace(), content="true") // TAB
  inspect('\u{000A}'.is_ascii_whitespace(), content="true") // LF
  inspect('\u{000B}'.is_ascii_whitespace(), content="true") // VT
  inspect('\u{000C}'.is_ascii_whitespace(), content="true") // FF
  inspect('\u{000D}'.is_ascii_whitespace(), content="true") // CR
  inspect('\u{0020}'.is_ascii_whitespace(), content="true") // SPACE

  // Test characters that are not ASCII whitespace
  inspect('\u{00A0}'.is_ascii_whitespace(), content="false") // NBSP (Unicode whitespace but not ASCII)
  inspect('\u{0085}'.is_ascii_whitespace(), content="false") // NEL (not ASCII)

  // But they should be Unicode whitespace
  inspect('\u{00A0}'.is_whitespace(), content="true") // NBSP
  inspect('\u{0085}'.is_whitespace(), content="true") // NEL
}

///|
test "Case conversion with non-letters" {
  // Test symbols and numbers remain unchanged
  inspect('0'.to_ascii_lowercase(), content="0")
  inspect('9'.to_ascii_uppercase(), content="9")
  inspect('!'.to_ascii_lowercase(), content="!")
  inspect('@'.to_ascii_uppercase(), content="@")
  inspect(' '.to_ascii_lowercase(), content=" ")
  inspect(' '.to_ascii_uppercase(), content=" ")

  // Test boundary letters
  inspect('A'.to_ascii_lowercase(), content="a")
  inspect('Z'.to_ascii_lowercase(), content="z")
  inspect('a'.to_ascii_uppercase(), content="A")
  inspect('z'.to_ascii_uppercase(), content="Z")
}

///|
test "utf16_len counts UTF-16 code units" {
  inspect('A'.utf16_len(), content="1")
  inspect('🌟'.utf16_len(), content="2")
  inspect('\u{FFFF}'.utf16_len(), content="1")
  inspect('\u{10000}'.utf16_len(), content="2")
}
