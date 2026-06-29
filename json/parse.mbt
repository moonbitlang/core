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
/// Validate input and return whether it is valid.
pub fn valid(input : StringView) -> Bool {
  try {
    parse(input) |> ignore
    true
  } catch {
    _ => return false
  }
}

///|
/// Parse a JSON input string into a Json value, with an optional maximum nesting depth (default is 1024)
#label_migration(max_nesting_depth, fill=false)
pub fn parse(
  input : StringView,
  max_nesting_depth? : Int = 1024,
) -> Json raise ParseError {
  let ctx = ParseContext::make(input)
  let val = ctx.parse_value(remaining_available_depth=max_nesting_depth)
  ctx.lex_skip_whitespace()
  if ctx.offset >= ctx.end_offset {
    val
  } else {
    ctx.invalid_char()
  }
}

///|
fn ParseContext::parse_value(
  ctx : ParseContext,
  remaining_available_depth~ : Int,
) -> Json raise ParseError {
  let tok = ctx.lex_value(allow_rbracket=false)
  ctx.parse_value2(tok, remaining_available_depth~)
}

///|
fn ParseContext::parse_value2(
  ctx : ParseContext,
  tok : Token,
  remaining_available_depth~ : Int,
) -> Json raise ParseError {
  match tok {
    Null => null
    True => Json::boolean(true)
    False => Json::boolean(false)
    Number(n, repr) => Json::number(n, repr?)
    String(s) => Json::string(s)
    LBrace => ctx.parse_object(remaining_available_depth~)
    LBracket => ctx.parse_array(remaining_available_depth~)
    RBracket | RBrace | Comma => abort("unreachable")
  }
}

///|
fn ParseContext::parse_object(
  ctx : ParseContext,
  remaining_available_depth~ : Int,
) -> Json raise ParseError {
  if remaining_available_depth <= 0 {
    raise DepthLimitExceeded
  }
  let child_remaining_available_depth = remaining_available_depth - 1
  let map = Map([])
  for x = ctx.lex_property_name() {
    match x {
      RBrace => break Json::object(map)
      String(name) => {
        ctx.lex_after_property_name()
        map[name] = ctx.parse_value(
          remaining_available_depth=child_remaining_available_depth,
        )
        match ctx.lex_after_object_value() {
          Comma => continue ctx.lex_property_name2()
          RBrace => break Json::object(map)
          _ => abort("unreachable")
        }
      }
      _ => abort("unreachable")
    }
  }
}

///|
fn ParseContext::parse_array(
  ctx : ParseContext,
  remaining_available_depth~ : Int,
) -> Json raise ParseError {
  if remaining_available_depth <= 0 {
    raise DepthLimitExceeded
  }
  let child_remaining_available_depth = remaining_available_depth - 1
  let vec = []
  for x = ctx.lex_value(allow_rbracket=true) {
    match x {
      RBracket => break Json::array(vec)
      tok => {
        vec.push(
          ctx.parse_value2(
            tok,
            remaining_available_depth=child_remaining_available_depth,
          ),
        )
        let tok2 = ctx.lex_after_array_value()
        match tok2 {
          Comma => continue ctx.lex_value(allow_rbracket=false)
          RBracket => break Json::array(vec)
          _ => abort("unreachable")
        }
      }
    }
  }
}
