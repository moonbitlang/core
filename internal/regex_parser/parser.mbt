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
priv type Parser

///|
priv enum CharOrClass {
  Char(Rechar)
  Class(RecharSet)
}

///|
const MAX_QUANT = 256

///|
fn Parser::class_atom(
  rest : StringView,
  ctx~ : ParserContext,
) -> (StringView, CharOrClass) raise ParserError {
  lexmatch rest with longest {
    ("\\" "[dDsSwW]", _) =>
      raise ctx.error_at(rest, HINT_USE_POSIX_CHARACTER_CLASS)
    ("\\" "b", rest) => (rest, Char('\b'))
    ("\\" "f", rest) => (rest, Char('\f'))
    ("\\" "n", rest) => (rest, Char('\n'))
    ("\\" "r", rest) => (rest, Char('\r'))
    ("\\" "t", rest) => (rest, Char('\t'))
    ("\\" "x" ("[0-9A-Fa-f]{2}" as hex), rest) => {
      if ctx.mode is String {
        raise ctx.error_at(rest, HINT_BYTE_ESCAPE_NOT_ALLOWED)
      }
      (rest, Char(hex2i(hex)))
    }
    ("\\" "u" ("[0-9A-Fa-f]{4}" as hex), rest2) => {
      if ctx.mode is Bytes {
        raise ctx.error_at(rest, HINT_UNICODE_ESCAPE_NOT_ALLOWED)
      }
      let c = hex2i(hex)
      guard ctx.profile.valid.contains(c) else {
        raise ctx.error_at(rest, HINT_CHARACTER_OUT_OF_RANGE)
      }
      (rest2, Char(c))
    }
    ("\\" "u" "[{]" ("[0-9A-Fa-f]{1,6}" as hex) "[}]", rest) => {
      if ctx.mode is Bytes {
        raise ctx.error_at(rest, HINT_UNICODE_ESCAPE_NOT_ALLOWED)
      }
      let c = hex2i(hex)
      guard ctx.profile.valid.contains(c) else {
        raise ctx.error_at(rest, HINT_CHARACTER_OUT_OF_RANGE)
      }
      (rest, Char(c))
    }
    ("\\" ("[\^$\\.*+?()\[\]{}|/\"\-:&]" as c), rest) =>
      (rest, Char(c.to_int()))
    ("\[:ascii:\]", rest) => (rest, Class(posix_cset_ascii))
    ("\[:upper:\]", rest) => (rest, Class(posix_cset_upper))
    ("\[:lower:\]", rest) => (rest, Class(posix_cset_lower))
    ("\[:alpha:\]", rest) => (rest, Class(posix_cset_alpha))
    ("\[:alnum:\]", rest) => (rest, Class(posix_cset_alnum))
    ("\[:digit:\]", rest) => (rest, Class(posix_cset_digit))
    ("\[:xdigit:\]", rest) => (rest, Class(posix_cset_xdigit))
    ("\[:blank:\]", rest) => (rest, Class(posix_cset_blank))
    ("\[:space:\]", rest) => (rest, Class(posix_cset_space))
    ("\[:word:\]", rest) => (rest, Class(ctx.profile.word))
    ("\[:[A-Za-z0-9_\-]+:\]", _) =>
      raise ctx.error_at(rest, HINT_UNSUPPORTED_POSIX_CLASS)
    ("\[:", _) => raise ctx.error_at(rest, HINT_INVALID_POSIX_CLASS)
    ("." as c, rest) => {
      guard ctx.profile.valid.contains(c.to_int()) else {
        raise ctx.error_at(rest, HINT_CHARACTER_OUT_OF_RANGE)
      }
      (rest, Char(c.to_int()))
    }
    _ => panic()
  }
}

///|
fn Parser::class_contents(
  rest : StringView,
  ctx~ : ParserContext,
) -> (StringView, RecharSet) raise ParserError {
  outer~: for rest = rest, char_set = RecharSet::empty() {
    match rest {
      [] => raise ctx.error_at(rest, HINT_UNCLOSED_CHAR_CLASS)
      [']', ..] => break (rest, char_set)
      _ => {
        let (rest, left) = match rest {
          ['[', ':', ..] =>
            // POSIX character class like [:digit:], handled by class_atom
            Parser::class_atom(rest, ctx~)
          ['[', ..] =>
            raise ctx.error_at(rest, HINT_UNSUPPORTED_NESTED_CHAR_CLASS)
          _ => Parser::class_atom(rest, ctx~)
        }
        let (rest, left_set) = match left {
          Char(c) =>
            match rest {
              ['-', '-', ..] =>
                raise ctx.error_at(rest, HINT_UNSUPPORTED_CLASS_SET_EXPRESSION)
              ['-', ']', ..] =>
                raise ctx.error_at(rest, offset=1, HINT_UNEXPECTED_CHAR)
              ['-', .. rest] => {
                let (rest2, right) = Parser::class_atom(rest, ctx~)
                match right {
                  Char(c2) => {
                    guard c <= c2 else {
                      raise ctx.error_at(rest, HINT_INVALID_CHAR_RANGE)
                    }
                    (rest2, RecharSet::char_range(c, c2))
                  }
                  Class(_) =>
                    raise ctx.error_at(
                      rest,
                      offset=1,
                      HINT_CHAR_RANGE_OVER_SETS,
                    )
                }
              }
              _ => (rest, RecharSet::char(c))
            }
          Class(cs) => (rest, cs)
        }
        let char_set = char_set + left_set
        match rest {
          [.. "--", ..] =>
            raise ctx.error_at(rest, HINT_UNSUPPORTED_CLASS_SET_EXPRESSION)
          [.. "&&", ..] =>
            raise ctx.error_at(rest, HINT_UNSUPPORTED_CLASS_SET_EXPRESSION)
          _ => continue outer~ rest, char_set
        }
      }
    }
  }
}

///|
fn Parser::character_class(
  rest : StringView,
  ctx~ : ParserContext,
) -> (StringView, RecharSet) raise ParserError {
  let (rest, neg) = match rest {
    ['[', '^', .. rest] => (rest, true)
    ['[', .. rest] => (rest, false)
    _ => raise ctx.error_at(rest, HINT_UNEXPECTED_CHAR)
  }
  let (rest, char_set) = Parser::class_contents(rest, ctx~)
  match rest {
    [']', .. rest] =>
      (rest, if neg { ctx.profile.valid - char_set } else { char_set })
    [] => raise ctx.error_at(rest, HINT_UNCLOSED_CHAR_CLASS)
    _ => panic()
  }
}

///|
fn Parser::quantifier_opt(
  rest : StringView,
  ctx~ : ParserContext,
) -> (StringView, Quantifier?) raise ParserError {
  let (rest, range) = lexmatch rest with longest {
    ("\*", rest) => (rest, Some((0, None)))
    ("\+", rest) => (rest, Some((1, None)))
    ("\?", rest) => (rest, Some((0, Some(1))))
    ("[{]" ("[0-9]+" as min) "[}]", rest) => {
      let min = Parser::quant_bound(min, ctx~)
      (rest, Some((min, Some(min))))
    }
    ("[{]" ("[0-9]+" as min) "," "[}]", rest) => {
      let min = Parser::quant_bound(min, ctx~)
      (rest, Some((min, None)))
    }
    ("[{]" ("[0-9]+" as min) "," ("[0-9]+" as max) "[}]", rest) => {
      let min = Parser::quant_bound(min, ctx~)
      let max = Parser::quant_bound(max, ctx~)
      guard min <= max else {
        raise ctx.error_at(rest, HINT_INVALID_QUANTIFIER)
      }
      (rest, Some((min, Some(max))))
    }
    ("[{]", _) => raise ctx.error_at(rest, HINT_INVALID_QUANTIFIER)
    _ => (rest, None)
  }
  match range {
    Some((min, max)) => {
      let rest0 = rest
      let (rest, mode) = match rest {
        ['?', .. rest] => (rest, QuantifierMode::NonGreedy)
        ['+', ..] =>
          raise ctx.error_at(rest0, HINT_UNSUPPORTED_POSSESSIVE_QUANTIFIER)
        _ => (rest, Greedy)
      }
      (rest, Some({ min, max, mode }))
    }
    None => (rest, None)
  }
}

///|
fn Parser::quant_bound(
  digits : StringView,
  ctx~ : ParserContext,
) -> Int raise ParserError {
  let mut value = 0
  for c in digits {
    let digit = c.to_int() - '0'.to_int()
    let next = value * 10 + digit
    guard next <= MAX_QUANT else {
      raise ctx.error_at(digits, HINT_QUANTIFIER_TOO_LARGE)
    }
    value = next
  }
  value
}

///|
fn Parser::term(
  rest : StringView,
  ctx~ : ParserContext,
) -> (StringView, Pattern) raise ParserError {
  let (rest, pat, is_assertion) = lexmatch rest with longest {
    ("\^", rest) => (rest, @re.start_of_input, true)
    ("\$", rest) => (rest, @re.end_of_input, true)
    ("\\" "b", rest) =>
      (rest, @re.alt([@re.start_of_word, @re.end_of_word]), true)
    ("\\" "B", rest) => (rest, @re.not_word_boundary, true)
    ("\\" "[dDsSwW]", _) =>
      raise ctx.error_at(rest, HINT_USE_POSIX_CHARACTER_CLASS)
    ("\\" "f", rest) => (rest, @re.char(RecharSet::char('\f')), false)
    ("\\" "n", rest) => (rest, @re.char(RecharSet::char('\n')), false)
    ("\\" "r", rest) => (rest, @re.char(RecharSet::char('\r')), false)
    ("\\" "t", rest) => (rest, @re.char(RecharSet::char('\t')), false)
    ("\\" "v", rest) => (rest, @re.char(RecharSet::char('\u{0b}')), false)
    ("\\" "x" ("[0-9A-Fa-f]{2}" as hex), rest) => {
      if ctx.mode is String {
        raise ctx.error_at(rest, HINT_BYTE_ESCAPE_NOT_ALLOWED)
      }
      (rest, @re.char(RecharSet::char(hex2i(hex))), false)
    }
    ("\\" "u" ("[0-9A-Fa-f]{4}" as hex), rest) => {
      if ctx.mode is Bytes {
        raise ctx.error_at(rest, HINT_UNICODE_ESCAPE_NOT_ALLOWED)
      }
      let c = hex2i(hex)
      guard ctx.profile.valid.contains(c) else {
        raise ctx.error_at(rest, HINT_CHARACTER_OUT_OF_RANGE)
      }
      (rest, @re.char(RecharSet::char(c)), false)
    }
    ("\\" "u" "[{]" ("[0-9A-Fa-f]{1,6}" as hex) "[}]", rest) => {
      if ctx.mode is Bytes {
        raise ctx.error_at(rest, HINT_UNICODE_ESCAPE_NOT_ALLOWED)
      }
      let c = hex2i(hex)
      guard ctx.profile.valid.contains(c) else {
        raise ctx.error_at(rest, HINT_CHARACTER_OUT_OF_RANGE)
      }
      (rest, @re.char(RecharSet::char(c)), false)
    }
    ("\\" ("[\^$\\.*+?()\[\]{}|/\"]" as c), rest) =>
      (rest, @re.char(RecharSet::char(c.to_int())), false)
    ("\\" ".", _) => raise ctx.error_at(rest, HINT_INVALID_ESCAPE)
    ("\.", rest) => (rest, @re.char(ctx.profile.valid), false)
    ("\(\?=", _) => raise ctx.error_at(rest, HINT_UNSUPPORTED_LOOKAHEAD)
    ("\(\?!", _) =>
      raise ctx.error_at(rest, HINT_UNSUPPORTED_NEGATIVE_LOOKAHEAD)
    ("\(\?<=", _) => raise ctx.error_at(rest, HINT_UNSUPPORTED_LOOKBEHIND)
    ("\(\?<!", _) =>
      raise ctx.error_at(rest, HINT_UNSUPPORTED_NEGATIVE_LOOKBEHIND)
    ("\(\?<" ("[A-Za-z_][A-Za-z0-9_]*" as name) ">", rest) => {
      let (rest, pat) = Parser::parse_group_continue(rest, ctx~)
      (rest, @re.capture(name=name.to_string(), pat), false)
    }
    ("\(\?:", rest) => {
      let (rest, pat) = Parser::parse_group_continue(rest, ctx~)
      (rest, pat, false)
    }
    ("\(\?<", _) => raise ctx.error_at(rest, HINT_INVALID_GROUP)
    ("\(\?" ("[A-Za-z]+" as modifier) ":", rest) =>
      match modifier {
        "i" => {
          let need_process = !ctx.ignore_case
          let (rest, pat) = Parser::parse_group_continue(rest, ctx={
            ..ctx,
            ignore_case: true,
          })
          (
            rest,
            if need_process {
              pattern_map_char(pat, ignore_case)
            } else {
              pat
            },
            false,
          )
        }
        _ => raise ctx.error_at(rest, HINT_INVALID_GROUP)
      }
    ("\(", rest) => {
      let (rest, pat) = Parser::parse_group_continue(rest, ctx~)
      (rest, @re.capture(pat), false)
    }
    ("\[:", _) => raise ctx.error_at(rest, HINT_BARE_POSIX_CLASS)
    ("\[", _) => {
      let (rest, char_set) = Parser::character_class(rest, ctx~)
      (rest, @re.char(char_set), false)
    }
    ("[\^$\\.*+?()\[\]{}|]", _) =>
      raise ctx.error_at(rest, HINT_UNEXPECTED_CHAR)
    ("." as c, rest2) => {
      guard ctx.profile.valid.contains(c.to_int()) else {
        raise ctx.error_at(rest, HINT_CHARACTER_OUT_OF_RANGE)
      }
      (rest2, @re.char(RecharSet::char(c.to_int())), false)
    }
    _ => raise ctx.error_at(rest, HINT_UNEXPECTED_CHAR)
  }
  if !is_assertion {
    let (rest, quantifier) = Parser::quantifier_opt(rest, ctx~)
    match quantifier {
      Some(q) => (rest, @re.quantifier(pat, q))
      None => (rest, pat)
    }
  } else {
    (rest, pat)
  }
}

///|
fn Parser::alternative(
  rest : StringView,
  ctx~ : ParserContext,
) -> (StringView, Pattern) raise ParserError {
  let seq = []
  let rest = for rest = rest {
    match rest {
      [] | ['|' | ')', ..] => break rest
      _ => {
        let (rest, pat) = Parser::term(rest, ctx~)
        seq.push(pat)
        continue rest
      }
    }
  }
  (rest, @re.seq(ReadOnlyArray::from_array(seq)))
}

///|
fn Parser::parse_group_continue(
  rest : StringView,
  ctx~ : ParserContext,
) -> (StringView, Pattern) raise ParserError {
  let (rest, pat) = Parser::disjunction(rest, ctx~)
  match rest {
    [')', .. rest] => (rest, pat)
    [] => raise ctx.error_at(rest, HINT_UNCLOSED_GROUP)
    _ => raise ctx.error_at(rest, HINT_UNEXPECTED_CHAR)
  }
}

///|
fn Parser::disjunction(
  rest : StringView,
  ctx~ : ParserContext,
) -> (StringView, Pattern) raise ParserError {
  let alts = []
  let (rest, alt) = Parser::alternative(rest, ctx~)
  alts.push(alt)
  let rest = for rest = rest {
    match rest {
      ['|', .. rest] => {
        let (rest, pat) = Parser::alternative(rest, ctx~)
        alts.push(pat)
        continue rest
      }
      _ => break rest
    }
  }
  (rest, @re.alt(ReadOnlyArray::from_array(alts)))
}

///|
pub fn parse(
  profile~ : Profile,
  mode~ : Mode,
  pattern : StringView,
) -> Pattern raise ParserError {
  let ctx = ParserContext::new(profile~, base=pattern.start_offset(), mode~)
  let (rest, pat) = Parser::disjunction(pattern, ctx~)
  if !rest.is_empty() {
    raise ctx.error_at(rest, HINT_UNEXPECTED_CHAR)
  }
  pat
}
