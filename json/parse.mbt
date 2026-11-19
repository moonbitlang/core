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
/// Returns whether `input` parses. "Valid" here means exactly what `parse`
/// accepts, so it includes the restriction on string contents described
/// there: a document whose only defect is an unpaired surrogate escape is
/// reported as invalid.
pub fn valid(input : StringView) -> Bool {
  try {
    parse(input) |> ignore
    true
  } catch {
    _ => return false
  }
}

///|
/// Parse a JSON input string into a Json value.
///
/// By default, duplicate object keys keep the last value. Set
/// `reject_duplicate_keys=true` to raise `DuplicateKey` instead, in any object.
/// Keys are compared after decoding escapes. The error contains the decoded
/// key and the position of the opening quote of its second occurrence.
///
/// Set `preserve_number_repr=true` to retain the original text of every number
/// in its `repr`, including integers and negative zero. `stringify` uses this
/// text verbatim. This requires additional string storage and does not change
/// the parsed `Double` value or the rules used by `from_json`. By default,
/// only numbers that need the existing precision/range fallback retain `repr`.
///
/// ```mbt check
/// test {
///   let value = @json.parse("{\"key\":1}", reject_duplicate_keys=true)
///   inspect(value.stringify(), content="{\"key\":1}")
///   let number = @json.parse("1.00e+0", preserve_number_repr=true)
///   inspect(number.stringify(), content="1.00e+0")
/// }
/// ```
///
/// ## What strings may contain
///
/// Each `\uXXXX` escape must denote a Unicode scalar value on its own,
/// or be one half of a correctly ordered surrogate pair. A leading-surrogate
/// escape (`\uD800`–`\uDBFF`) must therefore be followed immediately by an
/// escaped trailing surrogate (`\uDC00`–`\uDFFF`), and the pair is decoded as the
/// one character it stands for.
///
/// An escape that cannot pair up raises `InvalidChar` positioned at the
/// backslash that opens it — that one position, whatever the scan actually
/// stopped on. Input that simply runs out still raises `InvalidEof`, and a
/// second escape that is itself malformed is reported as the hex-digit
/// error it is, at the offending digit.
///
/// This is a limit on what a string may *contain*, which RFC 8259 §9 leaves
/// to the implementation — not a claim about which documents are
/// grammatically well formed, since §8.2 admits unpaired surrogate escapes,
/// nor a claim of I-JSON (RFC 7493) conformance, which restricts more than
/// this. It avoids manufacturing unpaired surrogates from escapes or
/// substituting U+FFFD and silently losing the distinction between two
/// different keys. A parse error lets the caller see and act on an invalid
/// escape. This check applies to escapes; raw UTF-16 code units in the input
/// are not validated. Callers constructing strings through unchecked APIs
/// must ensure that input is well-formed before parsing.
///
/// The cost is real: `JSON.stringify` in JavaScript emits lone surrogates as
/// `\uXXXX`, so some JSON that JavaScript and Python accept is rejected
/// here. Rust's serde_json rejects it too when parsing into `String` or
/// `Value`, though its byte-oriented mode admits WTF-8; Go's `encoding/json`
/// substitutes U+FFFD, while its experimental v2 parser is stricter.
#label_migration(max_nesting_depth, fill=false)
pub fn parse(
  input : StringView,
  max_nesting_depth~ : Int32 = 128,
  reject_duplicate_keys~ : Bool = false,
  preserve_number_repr~ : Bool = false,
) -> Json raise ParseError {
  let ctx = ParseContext::make(
    input,
    reject_duplicate_keys~,
    preserve_number_repr~,
  )
  let val = match ctx.lex_value() {
    Some(value) => value
    None => ctx.parse_container(remaining_available_depth=max_nesting_depth)
  }
  ctx.lex_skip_whitespace()
  if ctx.offset >= ctx.end_offset {
    val
  } else {
    ctx.invalid_char()
  }
}

///|
/// Parses the rest of a container, after `lex_value` has returned `None`: the
/// cursor is just past the opening bracket. The recursion happens here, after
/// `lex_value` has returned, so the stack of nested containers does not hold
/// the frame of its DFA.
fn ParseContext::parse_container(
  ctx : ParseContext,
  remaining_available_depth~ : Int32,
) -> Json raise ParseError {
  if ctx.input.unsafe_get(ctx.offset - 1) == '{' {
    ctx.parse_object(remaining_available_depth~)
  } else {
    ctx.parse_array(remaining_available_depth~)
  }
}

///|
/// Parses the rest of an object after its `{`.
///
/// This frame stays on the stack for every level of nesting, and in a debug
/// native build each `lexscan` in it reserves its own stack slots. With all
/// four of an object's `lexscan`s inline, 1024 nested objects overflowed the
/// 1 MiB main-thread stack on Windows. So only the `,` or `}` after each value
/// is lexed here; the property name and its `:` are lexed by
/// `lex_property_name`.
fn ParseContext::parse_object(
  ctx : ParseContext,
  remaining_available_depth~ : Int32,
) -> Json raise ParseError {
  let map = Map([])
  if ctx.lex_empty_container_end('}') {
    return Json::object(map)
  }
  if remaining_available_depth <= 0 {
    let name = ctx.lex_property_name(map)
    return ctx.stack_safe_parse(
      InsideObject(map, last_key=name, next=Outermost),
    )
  }
  let child_remaining_available_depth = remaining_available_depth - 1
  for ;; {
    let name = ctx.lex_property_name(map)
    map[name] = match ctx.lex_value() {
      Some(value) => value
      None =>
        ctx.parse_container(
          remaining_available_depth=child_remaining_available_depth,
        )
    }
    // After `,` only a property name may follow, not `}`, and
    // `lex_property_name` reports anything else.
    lexscan ctx {
      re"^[ \t\r\n]*" + re"," => continue
      re"^[ \t\r\n]*" + re"[}]" => break Json::object(map)
      _ => ctx.unexpected_token()
    }
  }
}

///|
/// Lexes a property name and the `:` that follows it, skipping the whitespace
/// before each. With `reject_duplicate_keys`, raises `DuplicateKey` if `map`
/// already has the name.
fn ParseContext::lex_property_name(
  ctx : ParseContext,
  map : Map[String, Json],
) -> String raise ParseError {
  lexscan ctx {
    re"^[ \t\r\n]*" + re"\"" => ()
    _ => ctx.unexpected_token()
  }
  let offset = ctx.offset - 1
  let name = ctx.lex_string()
  if ctx.reject_duplicate_keys && map.contains(name) {
    raise DuplicateKey(offset_to_position(ctx.input, offset), name)
  }
  lexscan ctx {
    re"^[ \t\r\n]*" + re":" => name
    _ => ctx.unexpected_token()
  }
}

///|
/// Parses the rest of an array after its `[`. After each element, `lexscan`
/// lexes the `,` or `]` that must follow, skipping the whitespace before it;
/// anything else is an error, reported by `unexpected_token`.
fn ParseContext::parse_array(
  ctx : ParseContext,
  remaining_available_depth~ : Int32,
) -> Json raise ParseError {
  let vec = []
  if ctx.lex_empty_container_end(']') {
    return Json::array(vec)
  }
  if remaining_available_depth <= 0 {
    return ctx.stack_safe_parse(InsideArray(vec, next=Outermost))
  }
  let child_remaining_available_depth = remaining_available_depth - 1
  for ;; {
    let value = match ctx.lex_value() {
      Some(value) => value
      None =>
        ctx.parse_container(
          remaining_available_depth=child_remaining_available_depth,
        )
    }
    vec.push(value)
    lexscan ctx {
      re"^[ \t\r\n]*" + re"," => continue
      re"^[ \t\r\n]*" + re"\]" => break Json::array(vec)
      _ => ctx.unexpected_token()
    }
  }
}

///|
/// Skips whitespace after a container's opening bracket and consumes `close`
/// if the container is empty. Otherwise the cursor is left at the first
/// non-whitespace character or EOF, where `lex_value` (for an array) or
/// `lex_property_name` (for an object) starts.
fn ParseContext::lex_empty_container_end(
  ctx : ParseContext,
  close : UInt16,
) -> Bool {
  ctx.lex_skip_whitespace()
  if ctx.offset < ctx.end_offset && ctx.input.unsafe_get(ctx.offset) == close {
    ctx.offset += 1
    true
  } else {
    false
  }
}

///|
priv enum ParserStack {
  Outermost
  InsideArray(Array[Json], next~ : ParserStack)
  InsideObject(Map[String, Json], mut last_key~ : String, next~ : ParserStack)
}

///|
fn ParseContext::stack_safe_parse(
  ctx : ParseContext,
  stack : ParserStack,
) -> Json raise ParseError {
  main_parse_loop~: for stack = stack {
    let value = if ctx.lex_value() is Some(value) {
      value
    } else if ctx.input.unsafe_get(ctx.offset - 1) == '{' {
      let map = Map([])
      if ctx.lex_empty_container_end('}') {
        Json::object(map)
      } else {
        let last_key = ctx.lex_property_name(map)
        continue main_parse_loop~ InsideObject(map, last_key~, next=stack)
      }
    } else {
      let vec = []
      if ctx.lex_empty_container_end(']') {
        Json::array(vec)
      } else {
        continue main_parse_loop~ InsideArray(vec, next=stack)
      }
    }
    // we have obtained a new complete JSON value,
    // feed the value to surrounding containers, if any
    for value = value, stack = stack {
      match stack {
        Outermost => break main_parse_loop~ value
        InsideArray(vec, next~) => {
          vec.push(value)
          lexscan ctx {
            re"^[ \t\r\n]*" + re"," => continue main_parse_loop~ stack
            re"^[ \t\r\n]*" + re"\]" => continue Json::array(vec), next
            _ => ctx.unexpected_token()
          }
        }
        InsideObject(map, last_key~, next~) as obj => {
          map[last_key] = value
          // After `,` only a property name may follow, not `}`, and
          // `lex_property_name` reports anything else.
          lexscan ctx {
            re"^[ \t\r\n]*" + re"," => {
              obj.last_key = ctx.lex_property_name(map)
              continue main_parse_loop~ stack
            }
            re"^[ \t\r\n]*" + re"[}]" => continue Json::object(map), next
            _ => ctx.unexpected_token()
          }
        }
      }
    }
  }
}
