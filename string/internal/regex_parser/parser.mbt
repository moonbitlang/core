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
  Char(@re.Rechar)
  Class(@re.RecharSet)
}

///|
const MAX_QUANT = 256

///|
/// Deepest nesting of groups accepted, the same as in a regex literal.
const MAX_GROUP_DEPTH = 128

///|
fn Parser::class_atom(
  rest : StringView,
  ctx~ : ParserContext,
) -> (StringView, CharOrClass) raise ParserError {
  lexmatch rest with longest {
    (re"^\\[dDsSwW]", after=_) =>
      raise ctx.error_at(rest, HINT_USE_POSIX_CHARACTER_CLASS)
    (re"^\\b", after=rest) => (rest, Char('\b'))
    (re"^\\f", after=rest) => (rest, Char('\f'))
    (re"^\\n", after=rest) => (rest, Char('\n'))
    (re"^\\r", after=rest) => (rest, Char('\r'))
    (re"^\\t", after=rest) => (rest, Char('\t'))
    (re"^\\v", after=rest) => (rest, Char('\u{0b}'))
    (re"^\\c" + (re"[A-Za-z]" as letter), after=rest) =>
      (rest, Char(letter.to_int() & 0x1F))
    (re"^\\0[0-9]", after=_) => raise ctx.error_at(rest, HINT_INVALID_ESCAPE)
    (re"^\\0", after=rest) => (rest, Char(0))
    (re"^\\x" + (re"[0-9A-Fa-f]{2}" as hex), after=rest) =>
      (rest, Char(hex2i(hex)))
    // The two halves of a surrogate pair name one code point; on its own a
    // half is out of range.
    (
      re"^\\u" +
      (re"[dD][89abAB][0-9A-Fa-f]{2}" as high) +
      re"\\u" +
      (re"[dD][c-fC-F][0-9A-Fa-f]{2}" as low),
      after=rest2,
    ) => {
      if ctx.mode is Bytes {
        raise ctx.error_at(rest, HINT_UNICODE_ESCAPE_NOT_ALLOWED)
      }
      (rest2, Char(surrogate_pair(hex2i(high), hex2i(low))))
    }
    (re"^\\u" + (re"[0-9A-Fa-f]{4}" as hex), after=rest2) => {
      if ctx.mode is Bytes {
        raise ctx.error_at(rest, HINT_UNICODE_ESCAPE_NOT_ALLOWED)
      }
      let c = hex2i(hex)
      guard ctx.escape_in_range(c) else {
        raise ctx.error_at(rest, HINT_CHARACTER_OUT_OF_RANGE)
      }
      (rest2, Char(c))
    }
    (re"^\\u[{]" + (re"[0-9A-Fa-f]+" as hex) + re"[}]", after=rest) => {
      if ctx.mode is Bytes {
        raise ctx.error_at(rest, HINT_UNICODE_ESCAPE_NOT_ALLOWED)
      }
      let c = hex_code_point(hex)
      guard ctx.escape_in_range(c) else {
        raise ctx.error_at(rest, HINT_CHARACTER_OUT_OF_RANGE)
      }
      (rest, Char(c))
    }
    (re"^\\u", after=_) => raise ctx.error_at(rest, HINT_INVALID_ESCAPE)
    (re"^\\" + (re"[\^$\\.*+?()\[\]{}|/\"\-:&]" as c), after=rest) =>
      (rest, Char(c.to_int()))
    // Any other escape is an error, never a backslash followed by a character.
    (re"^\\", after=_) => raise ctx.error_at(rest, HINT_INVALID_ESCAPE)
    (re"^\[:ascii:\]", after=rest) => (rest, Class(posix_cset_ascii))
    (re"^\[:upper:\]", after=rest) => (rest, Class(posix_cset_upper))
    (re"^\[:lower:\]", after=rest) => (rest, Class(posix_cset_lower))
    (re"^\[:alpha:\]", after=rest) => (rest, Class(posix_cset_alpha))
    (re"^\[:alnum:\]", after=rest) => (rest, Class(posix_cset_alnum))
    (re"^\[:digit:\]", after=rest) => (rest, Class(posix_cset_digit))
    (re"^\[:xdigit:\]", after=rest) => (rest, Class(posix_cset_xdigit))
    (re"^\[:blank:\]", after=rest) => (rest, Class(posix_cset_blank))
    (re"^\[:space:\]", after=rest) => (rest, Class(posix_cset_space))
    (re"^\[:word:\]", after=rest) => (rest, Class(ctx.profile.word))
    (re"^\[:[A-Za-z0-9_\-]+:\]", after=_) =>
      raise ctx.error_at(rest, HINT_UNSUPPORTED_POSIX_CLASS)
    (re"^\[:", after=_) => raise ctx.error_at(rest, HINT_INVALID_POSIX_CLASS)
    (re"^." as c, after=rest) => {
      guard ctx.profile.valid.contains(c.to_int()) else {
        raise ctx.error_at(rest, HINT_CHARACTER_OUT_OF_RANGE)
      }
      (rest, Char(c.to_int()))
    }
    // Only the end of the pattern gets here, as in `[a-`.
    _ => raise ctx.error_at(rest, HINT_UNCLOSED_CHAR_CLASS)
  }
}

///|
fn Parser::class_contents(
  rest : StringView,
  ctx~ : ParserContext,
) -> (StringView, @re.RecharSet) raise ParserError {
  outer~: for rest = rest, char_set = @re.RecharSet::empty() {
    match rest {
      [] => raise ctx.error_at(rest, HINT_UNCLOSED_CHAR_CLASS)
      [']', ..] => break outer~ (rest, char_set)
      // `--` and `&&` are kept for set operations, and a single dash is only
      // the middle of a range.
      ['-', '-', ..] | ['&', '&', ..] =>
        raise ctx.error_at(rest, HINT_UNSUPPORTED_CLASS_SET_EXPRESSION)
      ['-', ..] => raise ctx.error_at(rest, HINT_UNESCAPED_DASH)
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
              ['-', ']', ..] => raise ctx.error_at(rest, HINT_DASH_AT_BOUNDARY)
              ['-', '&', '&', ..] =>
                raise ctx.error_at(
                  rest,
                  offset=1,
                  HINT_UNSUPPORTED_CLASS_SET_EXPRESSION,
                )
              ['-', .. rest] => {
                // An unescaped `[` is not a range end; `[:name:]` is read as
                // a POSIX class and rejected below.
                if rest is ['[', ..] && !(rest is ['[', ':', ..]) {
                  raise ctx.error_at(rest, HINT_UNSUPPORTED_NESTED_CHAR_CLASS)
                }
                let (rest2, right) = Parser::class_atom(rest, ctx~)
                match right {
                  Char(c2) => {
                    guard c <= c2 else {
                      raise ctx.error_at(rest, HINT_INVALID_CHAR_RANGE)
                    }
                    (rest2, @re.RecharSet::char_range(c, c2))
                  }
                  Class(_) =>
                    raise ctx.error_at(
                      rest,
                      offset=1,
                      HINT_CHAR_RANGE_OVER_SETS,
                    )
                }
              }
              _ => (rest, @re.RecharSet::char(c))
            }
          Class(cs) => (rest, cs)
        }
        continue outer~ rest, char_set + left_set
      }
    }
  }
}

///|
fn Parser::character_class(
  rest : StringView,
  ctx~ : ParserContext,
) -> (StringView, @re.RecharSet) raise ParserError {
  let (rest, neg) = match rest {
    ['[', '^', .. rest] => (rest, true)
    ['[', .. rest] => (rest, false)
    _ => raise ctx.error_at(rest, HINT_UNEXPECTED_CHAR)
  }
  // Check for dash at the start of character class
  match rest {
    ['-', ..] => raise ctx.error_at(rest, HINT_DASH_AT_BOUNDARY)
    _ => ()
  }
  let (rest, char_set) = Parser::class_contents(rest, ctx~)
  match rest {
    [']', .. rest] =>
      (
        rest,
        if neg {
          ctx.profile.valid - char_set
        } else {
          char_set & ctx.profile.valid
        },
      )
    [] => raise ctx.error_at(rest, HINT_UNCLOSED_CHAR_CLASS)
    _ => panic()
  }
}

///|
fn Parser::quantifier_opt(
  rest : StringView,
  ctx~ : ParserContext,
) -> (StringView, @re.Quantifier?) raise ParserError {
  let (rest, range) = lexmatch rest with longest {
    (re"^\*", after=rest) => (rest, Some((0, None)))
    (re"^\+", after=rest) => (rest, Some((1, None)))
    (re"^\?", after=rest) => (rest, Some((0, Some(1))))
    (re"^[{]" + (re"[0-9]+" as min) + re"[}]", after=rest) => {
      let min = Parser::quant_bound(min, ctx~)
      (rest, Some((min, Some(min))))
    }
    (re"^[{]" + (re"[0-9]+" as min) + re",[}]", after=rest) => {
      let min = Parser::quant_bound(min, ctx~)
      (rest, Some((min, None)))
    }
    (
      re"^[{]" +
      (re"[0-9]+" as min) +
      re"," +
      (re"[0-9]+" as max) +
      re"[}]",
      after=rest,
    ) => {
      let min = Parser::quant_bound(min, ctx~)
      let max = Parser::quant_bound(max, ctx~)
      guard min <= max else {
        raise ctx.error_at(rest, HINT_INVALID_QUANTIFIER)
      }
      (rest, Some((min, Some(max))))
    }
    (re"^[{]", after=_) => raise ctx.error_at(rest, HINT_INVALID_QUANTIFIER)
    _ => (rest, None)
  }
  match range {
    Some((min, max)) => {
      let rest0 = rest
      let (rest, mode) = match rest {
        ['?', .. rest] => (rest, @re.QuantifierMode::NonGreedy)
        ['+', ..] =>
          raise ctx.error_at(rest0, HINT_UNSUPPORTED_POSSESSIVE_QUANTIFIER)
        _ => (rest, Greedy)
      }
      (rest, Some({ min, max, mode, }))
    }
    None => (rest, None)
  }
}

///|
fn Parser::quant_bound(
  digits : StringView,
  ctx~ : ParserContext,
) -> Int raise ParserError {
  for c in digits; value = 0 {
    let digit = c.to_int() - '0'
    let next = value * 10 + digit
    guard next <= MAX_QUANT else {
      raise ctx.error_at(digits, HINT_QUANTIFIER_TOO_LARGE)
    }
    continue next
  } nobreak {
    value
  }
}

///|
priv enum GroupKind {
  Capturing(String?)
  NonCapturing
  IgnoreCase
}

///|
/// How a term starts: something read in full, with whether it is an
/// assertion, or the opening of a group whose body comes next.
priv enum TermStart {
  Atom(StringView, @re.Pattern, Bool)
  Group(StringView, GroupKind)
}

///|
/// Read the start of a term. The body of a group is not parsed here but by
/// the caller: this function has a large frame, and nesting would otherwise
/// keep one of them on the stack per level.
fn Parser::term_start(
  rest : StringView,
  ctx~ : ParserContext,
) -> TermStart raise ParserError {
  let (rest, pat, is_assertion) = lexmatch rest with longest {
    (re"^\^", after=rest) => (rest, @re.start_of_input, true)
    (re"^\$", after=rest) => (rest, @re.end_of_input, true)
    (re"^\\b", after=rest) =>
      (rest, @re.alt([@re.start_of_word, @re.end_of_word]), true)
    (re"^\\B", after=rest) => (rest, @re.not_word_boundary, true)
    (re"^\\[dDsSwW]", after=_) =>
      raise ctx.error_at(rest, HINT_USE_POSIX_CHARACTER_CLASS)
    (re"^\\f", after=rest) => (rest, @re.char(@re.RecharSet::char('\f')), false)
    (re"^\\n", after=rest) => (rest, @re.char(@re.RecharSet::char('\n')), false)
    (re"^\\r", after=rest) => (rest, @re.char(@re.RecharSet::char('\r')), false)
    (re"^\\t", after=rest) => (rest, @re.char(@re.RecharSet::char('\t')), false)
    (re"^\\v", after=rest) =>
      (rest, @re.char(@re.RecharSet::char('\u{0b}')), false)
    (re"^\\c" + (re"[A-Za-z]" as letter), after=rest) =>
      (rest, @re.char(@re.RecharSet::char(letter.to_int() & 0x1F)), false)
    (re"^\\0[0-9]", after=_) => raise ctx.error_at(rest, HINT_INVALID_ESCAPE)
    (re"^\\0", after=rest) => (rest, @re.char(@re.RecharSet::char(0)), false)
    (re"^\\x" + (re"[0-9A-Fa-f]{2}" as hex), after=rest) =>
      (rest, @re.char(@re.RecharSet::char(hex2i(hex))), false)
    (
      re"^\\u" +
      (re"[dD][89abAB][0-9A-Fa-f]{2}" as high) +
      re"\\u" +
      (re"[dD][c-fC-F][0-9A-Fa-f]{2}" as low),
      after=rest2,
    ) => {
      if ctx.mode is Bytes {
        raise ctx.error_at(rest, HINT_UNICODE_ESCAPE_NOT_ALLOWED)
      }
      let c = surrogate_pair(hex2i(high), hex2i(low))
      (rest2, @re.char(@re.RecharSet::char(c)), false)
    }
    (re"^\\u" + (re"[0-9A-Fa-f]{4}" as hex), after=rest) => {
      if ctx.mode is Bytes {
        raise ctx.error_at(rest, HINT_UNICODE_ESCAPE_NOT_ALLOWED)
      }
      let c = hex2i(hex)
      guard ctx.escape_in_range(c) else {
        raise ctx.error_at(rest, HINT_CHARACTER_OUT_OF_RANGE)
      }
      (rest, @re.char(@re.RecharSet::char(c) & ctx.profile.valid), false)
    }
    (re"^\\u[{]" + (re"[0-9A-Fa-f]+" as hex) + re"[}]", after=rest) => {
      if ctx.mode is Bytes {
        raise ctx.error_at(rest, HINT_UNICODE_ESCAPE_NOT_ALLOWED)
      }
      let c = hex_code_point(hex)
      guard ctx.escape_in_range(c) else {
        raise ctx.error_at(rest, HINT_CHARACTER_OUT_OF_RANGE)
      }
      (rest, @re.char(@re.RecharSet::char(c) & ctx.profile.valid), false)
    }
    (re"^\\u", after=_) => raise ctx.error_at(rest, HINT_INVALID_ESCAPE)
    (re"^\\" + (re"[\^$\\.*+?()\[\]{}|/\"]" as c), after=rest) =>
      (rest, @re.char(@re.RecharSet::char(c.to_int())), false)
    (re"^\\.", after=_) => raise ctx.error_at(rest, HINT_INVALID_ESCAPE)
    (re"^\.", after=rest) => (rest, @re.char(ctx.profile.valid), false)
    (re"^\(\?=", after=_) =>
      raise ctx.error_at(rest, HINT_UNSUPPORTED_LOOKAHEAD)
    (re"^\(\?!", after=_) =>
      raise ctx.error_at(rest, HINT_UNSUPPORTED_NEGATIVE_LOOKAHEAD)
    (re"^\(\?<=", after=_) =>
      raise ctx.error_at(rest, HINT_UNSUPPORTED_LOOKBEHIND)
    (re"^\(\?<!", after=_) =>
      raise ctx.error_at(rest, HINT_UNSUPPORTED_NEGATIVE_LOOKBEHIND)
    (re"^\(\?<" + (re"[A-Za-z_][A-Za-z0-9_]*" as name) + re">", after=rest2) => {
      let name = name.to_owned()
      guard !ctx.group_names.contains(name) else {
        raise ctx.error_at(rest, HINT_DUPLICATE_GROUP_NAME)
      }
      ctx.group_names[name] = ()
      return Group(rest2, Capturing(Some(name)))
    }
    (re"^\(\?:", after=rest) => return Group(rest, NonCapturing)
    (re"^\(\?<", after=_) => raise ctx.error_at(rest, HINT_INVALID_GROUP)
    (re"^\(\?" + (re"[A-Za-z]+" as modifier) + re":", after=rest) =>
      match modifier {
        "i" => return Group(rest, IgnoreCase)
        _ => raise ctx.error_at(rest, HINT_INVALID_GROUP)
      }
    (re"^\(", after=rest) => return Group(rest, Capturing(None))
    (re"^\[\^?:[a-z]+:\]", after=_) =>
      raise ctx.error_at(rest, HINT_BARE_POSIX_CLASS)
    (re"^\[", after=_) => {
      let (rest, char_set) = Parser::character_class(rest, ctx~)
      (rest, @re.char(char_set), false)
    }
    (re"^[\^$\\.*+?()\[\]{}|]", after=_) =>
      raise ctx.error_at(rest, HINT_UNEXPECTED_CHAR)
    (re"^." as c, after=rest2) => {
      guard ctx.profile.valid.contains(c.to_int()) else {
        raise ctx.error_at(rest, HINT_CHARACTER_OUT_OF_RANGE)
      }
      (rest2, @re.char(@re.RecharSet::char(c.to_int())), false)
    }
    _ => raise ctx.error_at(rest, HINT_UNEXPECTED_CHAR)
  }
  Atom(rest, pat, is_assertion)
}

///|
fn Parser::term(
  rest : StringView,
  ctx~ : ParserContext,
) -> (StringView, @re.Pattern) raise ParserError {
  let (rest, pat, is_assertion) = match Parser::term_start(rest, ctx~) {
    Atom(rest, pat, is_assertion) => (rest, pat, is_assertion)
    Group(rest, Capturing(name)) => {
      let (rest, pat) = Parser::parse_group_continue(rest, ctx~)
      (rest, @re.capture(name?, pat), false)
    }
    Group(rest, NonCapturing) => {
      let (rest, pat) = Parser::parse_group_continue(rest, ctx~)
      (rest, pat, false)
    }
    Group(rest, IgnoreCase) => {
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
) -> (StringView, @re.Pattern) raise ParserError {
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
) -> (StringView, @re.Pattern) raise ParserError {
  // The parser recurses once per level, so a pattern that only nests would
  // otherwise overflow the stack.
  guard ctx.depth < MAX_GROUP_DEPTH else {
    raise ctx.error_at(rest, HINT_NESTING_TOO_DEEP)
  }
  let ctx = { ..ctx, depth: ctx.depth + 1, }
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
) -> (StringView, @re.Pattern) raise ParserError {
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
/// Parse input into this package's structured value.
pub fn parse(
  profile~ : @re.Profile,
  mode~ : Mode,
  pattern : StringView,
) -> @re.Pattern raise ParserError {
  let ctx = ParserContext::new(profile~, base=pattern.start_offset(), mode~)
  let (rest, pat) = Parser::disjunction(pattern, ctx~)
  if !rest.is_empty() {
    raise ctx.error_at(rest, HINT_UNEXPECTED_CHAR)
  }
  pat
}
