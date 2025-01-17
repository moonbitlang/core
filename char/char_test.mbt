// Copyright 2025 International Digital Economy Academy
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

test "to_string" {
  assert_eq!('a'.to_string(), "a")
}

test "show output" {
  fn repr(chr) {
    let buf = StringBuilder::new(size_hint=0)
    Show::output(chr, buf)
    buf.to_string()
  }

  assert_eq!(repr('a'), "'a'")
  assert_eq!(repr('\''), "'\\''")
  assert_eq!(repr('"'), "'\"'")
  assert_eq!(repr('\\'), "'\\\\'")
  assert_eq!(repr('\n'), "'\\n'")
  assert_eq!(repr('\r'), "'\\r'")
  assert_eq!(repr('\b'), "'\\b'")
  assert_eq!(repr('\t'), "'\\t'")
  assert_eq!(repr(Char::from_int(0)), "'\\x00'")
}

///|
struct TestHash {
  x : Char
} derive(Hash, Eq, Show)

test "Char hash function with struct" {
  let m = {}
  m[{ x: 'a' }] = '3'
  m[{ x: 'b' }] = '3'
  inspect!(m, content="{{x: 'a'}: '3', {x: 'b'}: '3'}")
}

test "Char hash" {
  let m = {}
  m['a'] = '3'
  m['b'] = '3'
  inspect!(m, content="{'a': '3', 'b': '3'}")
}

test "is_ascii" {
  let ascii = 'a'
  let non_ascii = '❤'
  assert_true!(ascii.is_ascii())
  assert_false!(non_ascii.is_ascii())
}

test "is_ascii_alphabetic" {
  let uppercase_a = 'A'
  let uppercase_g = 'G'
  let a = 'a'
  let g = 'g'
  let zero = '0'
  let percent = '%'
  let space = ' '
  let lf = '\n'
  let esc = '\x1B'
  assert_true!(uppercase_a.is_ascii_alphabetic())
  assert_true!(uppercase_g.is_ascii_alphabetic())
  assert_true!(a.is_ascii_alphabetic())
  assert_true!(g.is_ascii_alphabetic())
  assert_false!(zero.is_ascii_alphabetic())
  assert_false!(percent.is_ascii_alphabetic())
  assert_false!(space.is_ascii_alphabetic())
  assert_false!(lf.is_ascii_alphabetic())
  assert_false!(esc.is_ascii_alphabetic())
}

test "is_ascii_control" {
  let uppercase_a = 'A'
  let uppercase_g = 'G'
  let a = 'a'
  let g = 'g'
  let zero = '0'
  let percent = '%'
  let space = ' '
  let lf = '\n'
  let esc = '\x1B'
  assert_false!(uppercase_a.is_ascii_control())
  assert_false!(uppercase_g.is_ascii_control())
  assert_false!(a.is_ascii_control())
  assert_false!(g.is_ascii_control())
  assert_false!(zero.is_ascii_control())
  assert_false!(percent.is_ascii_control())
  assert_false!(space.is_ascii_control())
  assert_true!(lf.is_ascii_control())
  assert_true!(esc.is_ascii_control())
}

test "is_ascii_graphic" {
  let uppercase_a = 'A'
  let uppercase_g = 'G'
  let a = 'a'
  let g = 'g'
  let zero = '0'
  let percent = '%'
  let space = ' '
  let lf = '\n'
  let esc = '\x1B'
  assert_true!(uppercase_a.is_ascii_graphic())
  assert_true!(uppercase_g.is_ascii_graphic())
  assert_true!(a.is_ascii_graphic())
  assert_true!(g.is_ascii_graphic())
  assert_true!(zero.is_ascii_graphic())
  assert_true!(percent.is_ascii_graphic())
  assert_false!(space.is_ascii_graphic())
  assert_false!(lf.is_ascii_graphic())
  assert_false!(esc.is_ascii_graphic())
}

test "is_ascii_hexdigit" {
  let uppercase_a = 'A'
  let uppercase_g = 'G'
  let a = 'a'
  let g = 'g'
  let zero = '0'
  let percent = '%'
  let space = ' '
  let lf = '\n'
  let esc = '\x1B'
  assert_true!(uppercase_a.is_ascii_hexdigit())
  assert_false!(uppercase_g.is_ascii_hexdigit())
  assert_true!(a.is_ascii_hexdigit())
  assert_false!(g.is_ascii_hexdigit())
  assert_true!(zero.is_ascii_hexdigit())
  assert_false!(percent.is_ascii_hexdigit())
  assert_false!(space.is_ascii_hexdigit())
  assert_false!(lf.is_ascii_hexdigit())
  assert_false!(esc.is_ascii_hexdigit())
}

test "is_ascii_lowercase" {
  let uppercase_a = 'A'
  let uppercase_g = 'G'
  let a = 'a'
  let g = 'g'
  let zero = '0'
  let percent = '%'
  let space = ' '
  let lf = '\n'
  let esc = '\x1B'
  assert_false!(uppercase_a.is_ascii_lowercase())
  assert_false!(uppercase_g.is_ascii_lowercase())
  assert_true!(a.is_ascii_lowercase())
  assert_true!(g.is_ascii_lowercase())
  assert_false!(zero.is_ascii_lowercase())
  assert_false!(percent.is_ascii_lowercase())
  assert_false!(space.is_ascii_lowercase())
  assert_false!(lf.is_ascii_lowercase())
  assert_false!(esc.is_ascii_lowercase())
}

test "is_ascii_octdigit" {
  let uppercase_a = 'A'
  let a = 'a'
  let zero = '0'
  let seven = '7'
  let nine = '9'
  let percent = '%'
  let lf = '\n'
  assert_false!(uppercase_a.is_ascii_octdigit())
  assert_false!(a.is_ascii_octdigit())
  assert_true!(zero.is_ascii_octdigit())
  assert_true!(seven.is_ascii_octdigit())
  assert_false!(nine.is_ascii_octdigit())
  assert_false!(percent.is_ascii_octdigit())
  assert_false!(lf.is_ascii_octdigit())
}

test "is_ascii_punctuation" {
  let uppercase_a = 'A'
  let uppercase_g = 'G'
  let a = 'a'
  let g = 'g'
  let zero = '0'
  let percent = '%'
  let space = ' '
  let lf = '\n'
  let esc = '\x1B'
  assert_false!(uppercase_a.is_ascii_punctuation())
  assert_false!(uppercase_g.is_ascii_punctuation())
  assert_false!(a.is_ascii_punctuation())
  assert_false!(g.is_ascii_punctuation())
  assert_false!(zero.is_ascii_punctuation())
  assert_true!(percent.is_ascii_punctuation())
  assert_false!(space.is_ascii_punctuation())
  assert_false!(lf.is_ascii_punctuation())
  assert_false!(esc.is_ascii_punctuation())
}

test "is_ascii_uppercase" {
  let uppercase_a = 'A'
  let uppercase_g = 'G'
  let a = 'a'
  let g = 'g'
  let zero = '0'
  let percent = '%'
  let space = ' '
  let lf = '\n'
  let esc = '\x1B'
  assert_true!(uppercase_a.is_ascii_uppercase())
  assert_true!(uppercase_g.is_ascii_uppercase())
  assert_false!(a.is_ascii_uppercase())
  assert_false!(g.is_ascii_uppercase())
  assert_false!(zero.is_ascii_uppercase())
  assert_false!(percent.is_ascii_uppercase())
  assert_false!(space.is_ascii_uppercase())
  assert_false!(lf.is_ascii_uppercase())
  assert_false!(esc.is_ascii_uppercase())
}

test "is_ascii_whitespace" {
  let uppercase_a = 'A'
  let uppercase_g = 'G'
  let a = 'a'
  let g = 'g'
  let zero = '0'
  let percent = '%'
  let space = ' '
  let lf = '\n'
  let esc = '\x1B'
  assert_false!(uppercase_a.is_ascii_whitespace())
  assert_false!(uppercase_g.is_ascii_whitespace())
  assert_false!(a.is_ascii_whitespace())
  assert_false!(g.is_ascii_whitespace())
  assert_false!(zero.is_ascii_whitespace())
  assert_false!(percent.is_ascii_whitespace())
  assert_true!(space.is_ascii_whitespace())
  assert_true!(lf.is_ascii_whitespace())
  assert_false!(esc.is_ascii_whitespace())
}

test "is_control" {
  assert_true!(''.is_control())
  assert_false!('q'.is_control())
}

test "is_digit" {
  assert_eq!(true, 'a'.is_digit!(11))
  assert_eq!(true, 'a'.is_digit!(12))
  assert_eq!(true, 'a'.is_digit!(13))
  assert_eq!(true, 'a'.is_digit!(14))
  assert_eq!(true, 'a'.is_digit!(15))
  assert_eq!(true, 'a'.is_digit!(16))
  assert_eq!(true, 'A'.is_digit!(11))
  assert_eq!(true, 'B'.is_digit!(12))
  assert_eq!(true, 'C'.is_digit!(13))
  assert_eq!(true, 'D'.is_digit!(14))
  assert_eq!(true, 'E'.is_digit!(15))
  assert_eq!(true, 'F'.is_digit!(16))
  assert_eq!(false, 'A'.is_digit!(8))
  assert_eq!(true, '1'.is_digit!(2))
  assert_eq!(true, 'z'.is_digit!(36))
}

test "is_numeric" {
  assert_true!('٣'.is_numeric())
  assert_true!('7'.is_numeric())
  assert_true!('৬'.is_numeric())
  assert_true!('¾'.is_numeric())
  assert_true!('①'.is_numeric())
  assert_false!('K'.is_numeric())
  assert_false!('و'.is_numeric())
  assert_false!('藏'.is_numeric())
  assert_false!('三'.is_numeric())
}

test "is_whitespace" {
  assert_true!(' '.is_whitespace())
  // line break
  assert_true!('\n'.is_whitespace())
  // a non-breaking space
  assert_true!('\u{A0}'.is_whitespace())
  assert_false!('越'.is_whitespace())
}
