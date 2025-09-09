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

/// Regular Expression Parser - Using Recursive Descent Parsing Algorithm
///
/// This parser implements a simplified regular expression syntax, described using ABNF (Augmented Backus-Naur Form) as follows:
///
/// ```abnf
/// ; Regular Expression Syntax ABNF Specification
/// regex       = expression
/// expression  = sequence *( "|" sequence )           ; Alternation: a|b|c
/// sequence    = *term                                ; Sequence: abc
/// term        = factor [quantifier]                  ; Term with quantifier: a*, b+, c?
/// factor      = char / group / char-class / escape / dot / assertion   ; Basic elements
///
/// ; Quantifiers
/// quantifier  = "*" / "+" / "?" / repeat
/// repeat      = "{" number "}" / "{" number "," "}" / "{" number "," number "}"
///
/// ; Groups
/// group       = "(" expression ")"                   ; Capture group: (abc)
///             / "(?<" group-name ">" expression ")"  ; Named capture group:(?<name>abc)
///
/// ; Character classes
/// char-class  = "[" *char-class-item "]"            ; Character class: [abc], [a-z]
/// char-class-item = escape / char-range / normal-char
/// char-range  = char-class-char "-" char-class-char  ; Character range: a-z, 0-9
/// char-class-char = escape / normal-char             ; Character in character class (any character or escaped character)
///
/// ; Escape sequences
/// escape      = "\" any-char                         ; Escape character: \n, \*, \\
///
/// ; Assertions
/// assertion   = "^" / "$"                            ; Assertions: ^ (line start), $ (line end)
///
/// ; Any character
/// dot         = "."                                  ; Match any character
///
/// ; Normal character
/// char        = normal-char
/// normal-char = <any character except special chars>
/// special-chars = "*" / "+" / "?" / "|" / "(" / ")" / "[" / "]" / "{" / "}" / "\" / "." / "^" / "$"
/// ```
///
/// Parsing precedence (from high to low):
/// 1. Factor: characters, groups, character classes, escapes, assertions
/// 2. Quantifiers: *, +, ?
/// 3. Concatenation: implicit concatenation
/// 4. Alternation: |
///
/// Examples:
/// - `abc`     -> Sequence: character a, character b, character c
/// - `a|b`     -> Alternation: character a or character b
/// - `a*`      -> Quantifier: character a repeated 0 or more times
/// - `(a|b)*`  -> Group with quantifier: (character a or character b) repeated 0 or more times
/// - `[abc]`   -> Character class: any of characters a, b, or c
/// - `^abc$`   -> Assertions: line start, characters abc, line end

///|
priv struct Parser {
  mut input : @string.View
  mut flags : Flags
  mut captures : Int
  current_capture_scope : Set[Int]
  capture_map : Map[String, Int]
  mut has_backreference : Bool
}

///|
priv struct ParseResult {
  ast : Ast
  captures : Int
  capture_map : Map[String, Int]
  has_backreference : Bool
}

///|
priv struct Flags {
  multiline : Bool
  singleline : Bool
  ignore_case : Bool
} derive(Default)

///| Regular expression parsing error types
///
/// Defines various error conditions that may be encountered during parsing
pub enum Err {
  InternalError // Internal error
  InvalidCharClass // Invalid character class
  InvalidEscape // Invalid escape sequence
  InvalidNamedCapture // Invalid named capture group
  InvalidRepeatOp // Invalid repeat operator
  InvalidRepeatSize // Invalid repeat count
  MissingBracket // Missing right bracket ]
  MissingParenthesis // Missing right parenthesis )
  MissingRepeatArgument // Missing repeat argument
  TrailingBackslash // Trailing backslash
  UnexpectedParenthesis // Unexpected parenthesis
} derive(Show)

///| Parsing error exception type
///
/// Contains error information and related string view context
pub suberror RegexpError {
  RegexpError(err~ : Err, source_fragment~ : @string.View)
} derive(Show)

///| Create a regular expression parser
///
/// Parameters:
/// - `input`: String view of the regular expression to parse
///
/// Returns: New parser instance
fn Parser::new(input : @string.View, flags : Flags) -> Parser {
  Parser::{
    input,
    flags,
    captures: 1,
    capture_map: {},
    current_capture_scope: @set.Set::new(),
    has_backreference: false,
  }
}

///| Entry function for parsing regular expressions
///
/// According to ABNF rule: `regex = expression`
///
/// Parameters:
/// - `regex`: Regular expression string
///
/// Returns: Parsed Regex AST
///
/// Throws: Error_ when parsing fails
fn parse(
  regex : @string.View,
  flags~ : Flags = Flags::default(),
) -> ParseResult raise RegexpError {
  let parser = Parser::new(regex, flags)
  let result = parser.parse_expression()

  // Check if there's any remaining input, especially unmatched right parentheses
  if parser.input is [')', ..] {
    raise RegexpError(err=UnexpectedParenthesis, source_fragment=parser.input)
  }
  {
    ast: result,
    capture_map: parser.capture_map,
    captures: parser.captures,
    has_backreference: parser.has_backreference,
  }
}

///| Parse Expression
///
/// According to ABNF rule: `expression = sequence *( "|" sequence )`
///
/// Expression is the top-level structure of a regular expression, consisting of one or more sequences separated by `|`.
/// This represents alternation operation, matching any one of the sequences.
///
/// Examples:
/// - `a`       -> Single sequence
/// - `a|b`     -> Alternation of two sequences: match a or b
/// - `abc|def` -> Alternation of two sequences: match abc or def
/// - `a|b|c`   -> Alternation of multiple sequences: match a, b, or c
///
/// Returns: Parsed Regex AST
fn Parser::parse_expression(self : Parser) -> Ast raise RegexpError {
  let mut left = self.parse_sequence()
  while self.input is ['|', .. rest] {
    self.input = rest // consume '|'
    let right = self.parse_sequence()
    left = Ast::Alternate(left, right)
  }
  left
}

///| Parse Sequence
///
/// According to ABNF rule: `sequence = *term`
///
/// Sequence consists of consecutive terms, representing implicit concatenation operation.
/// Each term must match in order for the entire sequence to match successfully.
///
/// Examples:
/// - `abc`     -> Sequence of three terms: character a, character b, character c
/// - `a*b+`    -> Sequence of two terms: quantifier a*, quantifier b+
/// - `(ab)c`   -> Sequence of two terms: group (ab), character c
/// - ``        -> Empty sequence (valid)
///
/// Parsing termination conditions:
/// - Encounters `|` character (alternation operator)
/// - Encounters `)` character (group end)
/// - End of input
///
/// Returns: Parsed Regex AST
fn Parser::parse_sequence(self : Parser) -> Ast raise RegexpError {
  let sequence = []
  while self.input is [ch, ..] && ch != '|' && ch != ')' {
    let term = self.parse_term()
    sequence.push(term)
  }
  match sequence {
    // Empty sequence is considered a valid regular expression (consistent with Go's behavior)
    [] => Ast::Empty
    [regex] => regex
    _ => Ast::Concat(sequence)
  }
}

///| Parse Term
///
/// According to ABNF rule: `term = factor [quantifier]`
///
/// Term consists of a factor plus an optional quantifier.
/// Factor is the most basic regular expression unit, quantifier modifies the repetition count of the factor.
///
/// Supported quantifiers:
/// - `*`: Zero or more repetitions (ZeroOrMore)
/// - `+`: One or more repetitions (OneOrMore)
/// - `?`: Zero or one repetition (ZeroOrOne)
/// - `{n}`: Exactly n repetitions
/// - `{n,}`: At least n repetitions
/// - `{n,m}`: n to m repetitions
///
/// Examples:
/// - `a`      -> Basic factor: character a
/// - `a*`     -> Quantified term: character a repeated 0 or more times
/// - `a+`     -> Quantified term: character a repeated 1 or more times
/// - `a?`     -> Quantified term: character a repeated 0 or 1 times
/// - `a{3}`   -> Quantified term: character a repeated exactly 3 times
/// - `a{2,}`  -> Quantified term: character a repeated at least 2 times
/// - `a{2,5}` -> Quantified term: character a repeated 2 to 5 times
/// - `(ab)*`  -> Quantified term: group (ab) repeated 0 or more times
///
/// Returns: Parsed Regex AST
fn Parser::parse_term(self : Parser) -> Ast raise RegexpError {
  let mut base = self.parse_factor()

  // Handle quantifiers
  match self.input {
    [.. "*?", .. rest] => {
      // Handle lazy quantifier '*?'
      self.input = rest // consume '*?'
      base = ZeroOrMore(base, greedy=false)
    }
    [.. "*", .. rest] => {
      // Handle greedy quantifier '*'
      self.input = rest // consume '*'
      base = ZeroOrMore(base, greedy=true)
    }
    [.. "+?", .. rest] => {
      // Handle lazy quantifier '+?'
      self.input = rest // consume '+?'
      base = OneOrMore(base, greedy=false)
    }
    [.. "+", .. rest] => {
      // Handle greedy quantifier '+'
      self.input = rest // consume '+'
      base = OneOrMore(base, greedy=true)
    }
    [.. "??", .. rest] => {
      // Handle lazy quantifier '??'
      self.input = rest // consume '??'
      base = ZeroOrOne(base, greedy=false)
    }
    [.. "?", .. rest] => {
      // Handle greedy quantifier '?'
      self.input = rest // consume '?'
      base = ZeroOrOne(base, greedy=true)
    }
    ['{', .. rest] => {
      self.input = rest
      // Handle repeat quantifiers {n}, {n,}, {n,m}
      let repeat_result = self.parse_repeat()
      let greedy = match self.input {
        ['?', .. rest] => {
          self.input = rest // consume '?'
          false
        }
        _ => true
      }
      base = Repeat(base, greedy~, min=repeat_result.0, max=repeat_result.1)
    }
    _ => ()
  }
  base
}

///| Parse Factor
///
/// According to ABNF rule: `factor = char / group / char-class / escape / dot / assertion`
///
/// Factor is the smallest unit of a regular expression, which can be:
/// - Group: `(expression)` - Subexpression surrounded by parentheses
/// - Character class: `[abc]` - Match any one character from the specified character set
/// - Any character: `.` - Match any single character
/// - Assertion: `^` - Line start assertion, `$` - Line end assertion
/// - Escape character: `\c` - Escaped character, such as `\*`, `\\`
/// - Normal character: Any character except special characters
///
/// Special characters must be escaped to be used as literals:
/// `*` `+` `?` `|` `(` `)` `[` `]` `{` `}` `\` `.` `^` `$`
///
/// Examples:
/// - `a`       -> Character: matches character 'a'
/// - `(abc)`   -> Group: capture group, matches sequence 'abc'
/// - `[abc]`   -> Character class: matches 'a', 'b', or 'c'
/// - `\.`      -> Escape character: matches literal '.'
/// - `.`       -> Any character: matches any character
/// - `^`       -> Assertion: line start assertion
/// - `$`       -> Assertion: line end assertion
///
/// Returns: Parsed Regex AST
///
/// Throws: Error_ when invalid syntax is encountered
fn Parser::parse_factor(self : Parser) -> Ast raise RegexpError {
  match self.input {
    [.. "(?", .. rest] as capture =>
      // Handle various special group syntax
      match rest {
        ['<', .. rest] => {
          let captures = self.captures
          self.captures += 1
          // Named capture group (?<name>...)
          self.input = rest // consume '(?<'
          let name = self.parse_group_name()
          guard self.input is ['>', .. rest] else {
            raise RegexpError(
              err=InvalidNamedCapture,
              source_fragment=self.input,
            )
          }
          self.input = rest // consume '>'

          // Parse the expression inside the named capture group
          self.current_capture_scope.add(captures)
          let expr = self.parse_expression()
          self.current_capture_scope.remove(captures)

          // Check for closing parenthesis
          guard self.input is [')', .. rest] else {
            raise RegexpError(
              err=MissingParenthesis,
              source_fragment=self.input,
            )
          }
          self.input = rest // consume ')'
          if self.capture_map.contains(name) { // check for duplicate named capture
            raise RegexpError(err=InvalidNamedCapture, source_fragment=capture)
          }
          self.capture_map.set(name, captures)
          Capture(expr, index=captures)
        }
        _ => {
          // (?flags:...) - Scoped flags group
          self.input = rest // consume '(?'
          let old_flags = self.flags
          let new_flags = self.parse_flags()
          self.flags = new_flags
          let expr = self.parse_expression()
          guard self.input is [')', .. rest] else {
            raise RegexpError(
              err=MissingParenthesis,
              source_fragment=self.input,
            )
          }
          self.input = rest // consume ')'
          self.flags = old_flags // restore original flags
          expr
        }
      }
    ['(', .. rest] => {
      let captures = self.captures
      self.captures += 1
      self.input = rest // consume '('
      // Regular capture group

      // Parse the expression inside the capture group
      self.current_capture_scope.add(captures)
      let expr = self.parse_expression()
      self.current_capture_scope.remove(captures)

      // Check for closing parenthesis
      guard self.input is [')', .. rest] else {
        raise RegexpError(err=MissingParenthesis, source_fragment=self.input)
      }
      self.input = rest // consume ')'
      Capture(expr, index=captures)
    }
    ['[', .. rest] => {
      self.input = rest
      self.parse_char_class()
    }
    ['.', .. rest] => {
      self.input = rest // consume '.'
      if self.flags.singleline {
        // In singleline mode, '.' matches any character including newline
        CharClass(ranges_any, neg=false)
      } else {
        // In default mode, '.' matches any character except newline
        CharClass(ranges_any_not_new_line, neg=false)
      }
    }
    ['^', .. rest] => {
      self.input = rest // consume '^'
      if self.flags.multiline {
        // In multiline mode, '^' matches the beginning of a line
        Assertion(BeginLine)
      } else {
        // In default mode, '^' matches the beginning of the text
        Assertion(BeginText)
      }
    }
    ['$', .. rest] => {
      self.input = rest // consume '$'
      if self.flags.multiline {
        // In multiline mode, '$' matches the end of a line
        Assertion(EndLine)
      } else {
        // In default mode, '$' matches the end of the text
        Assertion(EndText)
      }
    }
    ['\\', .. rest] as escape => {
      guard rest is [c, .. rest] else {
        raise RegexpError(err=TrailingBackslash, source_fragment=self.input)
      }
      self.input = rest // consume '\' and the character
      match c {
        'b' => Assertion(WordBoundary) // Word boundary assertion
        'B' => Assertion(NoWordBoundary) // Non-word boundary assertion
        'd' => CharClass(ranges_is_digit, neg=false) // Digit character class
        'D' => CharClass(ranges_is_not_digit, neg=false) // Non-digit character class
        'w' => CharClass(ranges_is_word, neg=false) // Word character class
        'W' => CharClass(ranges_is_not_word, neg=false) // Non-word character class
        's' => CharClass(ranges_is_white_space_or_line_terminator, neg=false) // Whitespace character class
        'S' =>
          CharClass(ranges_is_not_white_space_or_line_terminator, neg=false) // Non-whitespace character class
        // ControlEscape
        't' => CharClass(['\t', '\t'], neg=false) // Tab
        'n' => CharClass(['\n', '\n'], neg=false) // Newline
        'v' => CharClass(['\u{b}', '\u{b}'], neg=false) // Vertical tab
        'f' => CharClass(['\u{c}', '\u{c}'], neg=false) // Form feed
        'r' => CharClass(['\r', '\r'], neg=false) // Carriage return
        'p' | 'P' as flag => {
          // Unicode property \p{property_name}
          let property_name = self.parse_unicode_property()
          self.parse_general_category(property_name, flag == 'P')
        }
        'u' => {
          // Unicode escape \u{aaaa} or \uaaaa
          let unicode_char = self.parse_unicode_escape()
          CharClass([unicode_char, unicode_char], neg=false)
        }
        '0' =>
          if rest is ['0'..='9', ..] {
            raise RegexpError(err=InvalidEscape, source_fragment=escape)
          } else {
            self.input = rest
            CharClass(['\u{0}', '\u{0}'], neg=false) // Null character
          }
        '1'..='9' as ch => {
          let mut input = self.input
          let mut capture = ch.to_int() - '0'.to_int()
          while input is ['0'..='9' as next_ch, .. next_rest] {
            capture = capture * 10 + (next_ch.to_int() - '0'.to_int())
            input = next_rest // consume the digit
          }
          self.input = input
          self.has_backreference = true

          // Ban recursive backreferences and backreferences to the non existent capture group
          if self.current_capture_scope.contains(capture) {
            raise RegexpError(err=InvalidEscape, source_fragment=escape)
          } else if capture >= self.captures {
            raise RegexpError(err=InvalidEscape, source_fragment=escape)
          }
          Backreference(capture)
        }
        'k' => {
          // Named backreference \k<name>
          guard self.input is ['<', .. rest] else {
            raise RegexpError(err=InvalidEscape, source_fragment=self.input)
          }
          self.input = rest // consume '<'
          let name = self.parse_group_name()
          guard self.input is ['>', .. rest] else {
            raise RegexpError(err=InvalidEscape, source_fragment=self.input)
          }
          self.input = rest // consume '>'

          // Get the capture index for the named group
          guard self.capture_map.get(name) is Some(capture) else {
            raise RegexpError(err=InvalidEscape, source_fragment=escape)
          }

          // Set backreference flag
          self.has_backreference = true

          // Ban recursive backreferences
          if self.current_capture_scope.contains(capture) {
            raise RegexpError(err=InvalidEscape, source_fragment=escape)
          } else if capture >= self.captures {
            raise RegexpError(err=InvalidEscape, source_fragment=escape)
          }
          Backreference(capture)
        }
        // reserve c
        'c' => raise RegexpError(err=InvalidEscape, source_fragment=self.input)
        _ =>
          if self.flags.ignore_case {
            CharClass(case_insensitive_char_class([c, c]), neg=false)
          } else {
            CharClass([c, c], neg=false)
          }
      }
    }
    [c, ..] if Parser::is_special_char(c) =>
      raise RegexpError(err=InvalidEscape, source_fragment=self.input)
    [c, .. rest] => {
      self.input = rest
      if self.flags.ignore_case {
        CharClass(case_insensitive_char_class([c, c]), neg=false)
      } else {
        CharClass([c, c], neg=false)
      }
    }
    "" => raise RegexpError(err=InternalError, source_fragment=self.input)
  }
}

///| Parse Character Class
///
/// According to ABNF rule: `char-class = "[" *char-class-item "]"`
///
/// A character class is a set of characters enclosed in square brackets, matching any single character from the set.
/// It supports escape characters and character range syntax.
///
/// Examples:
/// - `[abc]`   -> Matches character 'a', 'b', or 'c'
/// - `[a-z]`   -> Character range: matches any character from 'a' to 'z'
/// - `[a-zA-Z]` -> Multiple ranges: matches any character from 'a' to 'z' or 'A' to 'Z'
/// - `[a-\]]`  -> Character range: matches any character from 'a' to ']'
/// - `[\[\]]`  -> Escaped square bracket characters
/// - `[\\]`    -> Escaped backslash character
///
/// A char-class-item can be:
/// - Character range: `a-z` - a range from character 'a' to character 'z'
/// - Escape character: `\c` - any character escaped by a backslash (including `\]`)
/// - Normal character: any non-special character
///
/// Input: Assumes the left square bracket `[` has been consumed
///
/// Returns: CharClass(chars) - a character class AST containing a list of character ranges
///
/// Throws: Error_ when the character class format is incorrect
fn Parser::parse_char_class(self : Parser) -> Ast raise RegexpError {
  let neg = if self.input is ['^', .. rest] {
    self.input = rest // consume '^'
    true
  } else {
    false
  }
  let chars = []
  while self.input is [ch, .. rest] && ch != ']' {
    let escape = rest
    let start_char = match ch {
      '\\' => {
        guard rest is [ch, .. rest] else {
          raise RegexpError(err=TrailingBackslash, source_fragment=self.input)
        }
        self.input = rest
        match ch {
          'd' => {
            ranges_is_digit.each(chars.push(_)) // digit character class
            continue
          }
          'D' => {
            ranges_is_not_digit.each(chars.push(_)) // non-digit character class
            continue
          }
          'w' => {
            ranges_is_word.each(chars.push(_)) // word character class
            continue
          }
          'W' => {
            ranges_is_not_word.each(chars.push(_)) // non-word character class
            continue
          }
          's' => {
            ranges_is_white_space_or_line_terminator.each(chars.push(_)) // whitespace character class
            continue
          }
          'S' => {
            ranges_is_not_white_space_or_line_terminator.each(chars.push(_)) // non-whitespace character class
            continue
          }
          // ControlEscape
          't' => {
            ['\t', '\t'].each(chars.push(_))
            continue
          }
          'n' => {
            ['\n', '\n'].each(chars.push(_))
            continue
          }
          'v' => {
            ['\u{b}', '\u{b}'].each(chars.push(_))
            continue
          }
          'f' => {
            ['\u{c}', '\u{c}'].each(chars.push(_))
            continue
          }
          'r' => {
            ['\r', '\r'].each(chars.push(_))
            continue
          }
          // backspace
          'b' => {
            ['\u{8}', '\u{8}'].each(chars.push(_))
            continue
          }
          'u' => {
            // Unicode escape \u{aaaa} or \uaaaa  
            let unicode_char = self.parse_unicode_escape()
            [unicode_char, unicode_char].each(chars.push(_))
            continue
          }
          'p' | 'P' as flag => {
            // Unicode property \p{property_name}
            let property_name = self.parse_unicode_property()
            guard self.parse_general_category(property_name, flag == 'P')
              is CharClass(class, neg~)
            if neg {
              compute_char_class_complement(class).each(chars.push(_))
            } else {
              class.each(chars.push(_))
            }
            continue
          }
          // reserve c and k
          'c' | 'k' =>
            raise RegexpError(err=InvalidEscape, source_fragment=escape)
          _ => ch
        }
      }
      _ => {
        self.input = rest
        ch
      }
    }

    // Check for character range (e.g., a-z)
    if self.input is ['-', .. rest] {
      // Look ahead after '-', ensure it's not ']' and there are more characters
      let input_copy = self.input
      self.input = rest // consume '-'
      if self.input is [ch, .. rest] && ch != ']' {
        // Parse the end character of the range
        let end_char = match ch {
          '\\' => {
            guard rest is [ch, .. rest] else {
              raise RegexpError(
                err=TrailingBackslash,
                source_fragment=self.input,
              )
            }
            self.input = rest
            ch
          }
          _ => {
            self.input = rest
            ch
          }
        }

        // Check if the end character of the range is valid
        if end_char < start_char {
          raise RegexpError(err=InvalidCharClass, source_fragment=self.input)
        }

        // Add the range: start and end characters
        chars.push(start_char)
        chars.push(end_char)
      } else {
        // If '-' is followed by ']' or end of input, it's a literal, not a range operator
        self.input = input_copy // Restore input state
        chars.push(start_char)
        chars.push(start_char)
      }
    } else {
      // Normal character, not a range, represented as a single-character range
      chars.push(start_char)
      chars.push(start_char)
    }
  }
  guard self.input is [']', .. rest] else {
    raise RegexpError(err=MissingBracket, source_fragment=self.input)
  }
  self.input = rest // consume ']'
  if self.flags.ignore_case {
    CharClass(case_insensitive_char_class(chars), neg~)
  } else {
    CharClass(chars, neg~)
  }
}

///| Check if a character is a regular expression special character
///
/// Special characters need to be escaped to be used as literal characters.
///
/// Parameters:
/// - `c`: The character to check
///
/// Returns: `true` if it is a special character
fn Parser::is_special_char(c : Char) -> Bool {
  c is ('*' | '+' | '?' | '|' | '(' | ')' | '[' | ']' | '{' | '.' | '^' | '$')
}

///| Parse Repeat Quantifier
///
/// According to ABNF rule: `repeat = "{" number "}" / "{" number "," "}" / "{" number "," number "}"`
///
/// The repeat quantifier specifies how many times the preceding element should be repeated:
/// - `{n}`: Exactly n times
/// - `{n,}`: At least n times
/// - `{n,m}`: From n to m times (inclusive)
///
/// Examples:
/// - `a{3}` -> Character 'a' repeated exactly 3 times
/// - `b{2,}` -> Character 'b' repeated at least 2 times
/// - `c{1,5}` -> Character 'c' repeated 1 to 5 times
///
/// Input: Assumes the left brace `{` has been consumed
///
/// Returns: A tuple (min, max), where:
/// - min: Minimum number of repetitions
/// - max: Maximum number of repetitions (None means unlimited)
///
/// Throws: Error_ when the repeat quantifier format is incorrect
fn Parser::parse_repeat(self : Parser) -> (UInt, UInt?) raise RegexpError {

  // Parse the first number (minimum repetitions)
  let min = self.parse_number()
  match self.input {
    ['}', .. rest] => {
      // {n} format: exactly n repetitions
      self.input = rest
      (min, Some(min))
    }
    [',', .. rest] => {
      self.input = rest // consume ','
      match self.input {
        ['}', .. rest] => {
          // {n,} format: at least n repetitions
          self.input = rest
          (min, None)
        }
        _ => {
          // {n,m} format: n to m repetitions
          let max = self.parse_number()
          guard self.input is ['}', .. rest] else {
            raise RegexpError(err=InvalidRepeatOp, source_fragment=self.input)
          }
          self.input = rest // consume '}'

          // Validate the range
          if max < min {
            raise RegexpError(err=InvalidRepeatSize, source_fragment=self.input)
          }
          (min, Some(max))
        }
      }
    }
    _ => raise RegexpError(err=InvalidRepeatOp, source_fragment=self.input)
  }
}

///| Parse Number
///
/// Parses a sequence of decimal digits from the current input position.
/// The number must contain at least one digit character.
///
/// Examples:
/// - `123` -> 123
/// - `0` -> 0
/// - `42` -> 42
///
/// Returns: The parsed integer value
///
/// Throws: Error_ when no valid number is found
fn Parser::parse_number(self : Parser) -> UInt raise RegexpError {
  let mut result = 0U
  let mut has_digits = false
  while self.input is [ch, .. rest] && ch >= '0' && ch <= '9' {
    has_digits = true
    result = result * 10U + (ch.to_int() - '0'.to_int()).reinterpret_as_uint()
    self.input = rest
  }
  if not(has_digits) {
    raise RegexpError(err=MissingRepeatArgument, source_fragment=self.input)
  }
  result
}

///| Parse Group Name of a Named Capture Group
///
/// The group name must be a valid identifier, containing only letters, numbers, and underscores,
/// and must start with a letter or an underscore.
///
/// Examples:
/// - `name`     -> Valid group name
/// - `group1`   -> Valid group name
/// - `_test`    -> Valid group name
/// - `1invalid` -> Invalid group name (starts with a digit)
///
/// Returns: The parsed group name string
///
/// Throws: Error_ when the group name format is incorrect
fn Parser::parse_group_name(self : Parser) -> String raise RegexpError {
  let mut name = ""
  let mut first = true
  while self.input is [ch, .. rest] && ch != '>' {
    if first {
      // The first character must be a letter or an underscore
      if ch is ('a'..='z' | 'A'..='Z' | '_') {
        name += ch.to_string()
        self.input = rest
        first = false
      } else {
        raise RegexpError(err=InvalidNamedCapture, source_fragment=self.input)
      }
    } else if ch is ('a'..='z' | 'A'..='Z' | '0'..='9' | '_') {
      // Subsequent characters can be letters, numbers, or underscores
      name += ch.to_string()
      self.input = rest
    } else {
      raise RegexpError(err=InvalidNamedCapture, source_fragment=self.input)
    }
  }

  // Check if the group name is empty
  if name == "" {
    raise RegexpError(err=InvalidNamedCapture, source_fragment=self.input)
  }
  name
}

///| Parse flag string, e.g., "msi" for multiline, singleline and ignore case modes
///
/// Supported flags:
/// - `m`: Multiline mode
/// - `s`: Singleline mode (dotall)
/// - `i`: Ignore case mode
///
/// Returns: The new flag settings
///
/// Throws: Error_ when an invalid flag is encountered
fn Parser::parse_flags(self : Parser) -> Flags raise RegexpError {
  let mut flag = { ..self.flags }
  let mut positive = true
  loop self.input {
    [':', .. rest] => {
      self.input = rest // consume
      return flag
    }
    ['m', .. rest] => {
      flag = { ..flag, multiline: positive }
      continue rest
    }
    ['s', .. rest] => {
      flag = { ..flag, singleline: positive }
      continue rest
    }
    ['i', .. rest] => {
      flag = { ..flag, ignore_case: positive }
      continue rest
    }
    ['-', .. rest] if positive => {
      positive = false // Switch to negation mode
      continue rest
    }
    [_, ..] | [] =>
      // Unknown flag character or unexpected end
      raise RegexpError(err=InvalidRepeatOp, source_fragment=self.input)
  }
}

///| Parse Unicode Property name from \p{property_name}

///| Parse Unicode escape sequence \u{aaaa} or \uaaaa
///
/// Supports two formats:
/// - `\u{aaaa}`  : Unicode codepoint in hex inside braces (1-6 hex digits)
/// - `\uaaaa`    : Unicode codepoint in hex, exactly 4 digits
///
/// Parameters:
/// - `self`: Parser instance
///
/// Returns: Unicode character corresponding to the hex codepoint
///
/// Throws: Error_ when invalid Unicode escape format is encountered
fn Parser::parse_unicode_escape(self : Parser) -> Char raise RegexpError {
  match self.input {
    ['{', .. rest] => {
      let num = rest
      self.input = rest // consume '{'
      let mut codepoint = 0
      let mut len = 0

      // Parse hex digits until '}'
      while self.input is [ch, .. rest] && ch != '}' {
        match ch {
          '0'..='9' as ch => {
            codepoint = (codepoint << 4) | (ch.to_int() - '0'.to_int())
            self.input = rest
          }
          'a'..='f' as ch => {
            codepoint = (codepoint << 4) | (ch.to_int() - 'a'.to_int() + 10)
            self.input = rest
          }
          'A'..='F' as ch => {
            codepoint = (codepoint << 4) | (ch.to_int() - 'A'.to_int() + 10)
            self.input = rest
          }
          _ => raise RegexpError(err=InvalidEscape, source_fragment=self.input)
        }
        len += 1
        if len > 6 {
          raise RegexpError(err=InvalidEscape, source_fragment=num)
        }
      }
      if len == 0 {
        raise RegexpError(err=InvalidEscape, source_fragment=num)
      }

      // Check for closing brace
      guard self.input is ['}', .. rest]
      self.input = rest // consume '}'

      // Validate Unicode range (0x0 to 0x10FFFF)
      if codepoint < 0 || codepoint > 0x10FFFF {
        raise RegexpError(err=InvalidEscape, source_fragment=num)
      }
      codepoint.unsafe_to_char()
    }
    _ => {
      // Parse exactly 4 hex digits for \uaaaa format
      let mut codepoint = 0
      for i in 0..<4 {
        match self.input {
          ['0'..='9' as ch, .. rest] => {
            codepoint = (codepoint << 4) | (ch.to_int() - '0'.to_int())
            self.input = rest
          }
          ['a'..='f' as ch, .. rest] => {
            codepoint = (codepoint << 4) | (ch.to_int() - 'a'.to_int() + 10)
            self.input = rest
          }
          ['A'..='F' as ch, .. rest] => {
            codepoint = (codepoint << 4) | (ch.to_int() - 'A'.to_int() + 10)
            self.input = rest
          }
          _ => raise RegexpError(err=InvalidEscape, source_fragment=self.input)
        }
      }
      codepoint.unsafe_to_char()
    }
  }
}

///|
fn Parser::parse_unicode_property(self : Parser) -> String raise RegexpError {
  guard self.input is ['{', .. rest] else {
    raise RegexpError(err=InvalidCharClass, source_fragment=self.input)
  }
  self.input = rest // consume '{'
  let chars = []
  while self.input is [ch, .. rest] && ch != '}' {
    chars.push(ch)
    self.input = rest
  }
  guard self.input is ['}', .. rest] else {
    raise RegexpError(err=InvalidCharClass, source_fragment=self.input)
  }
  self.input = rest // consume '}'
  String::from_iter(chars.iter())
}

///|
fn Parser::parse_general_category(
  self : Parser,
  property_name : String,
  neg : Bool,
) -> Ast raise RegexpError {
  // First, normalize the property name using aliases
  let normalized_name = match
    @unicode.general_category_property_value_alises.get(property_name) {
    Some(name) => name
    None => raise RegexpError(err=InvalidCharClass, source_fragment=self.input)
  }

  // Get the character ranges for the normalized property name
  guard @unicode.general_category_ranges.get(normalized_name) is Some(ranges)
  CharClass(ranges, neg~)
}
