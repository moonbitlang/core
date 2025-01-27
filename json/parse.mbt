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

///|
pub fn valid(input : String) -> Bool {
  try {
    parse!(input) |> ignore
    true
  } catch {
    _ => return false
  }
}

///|
pub fn parse(input : String) -> JsonValue!ParseError {
  let ctx = ParseContext::make(input)
  let val = parse_value!(ctx)
  lex_skip_whitespace(ctx)
  if ctx.view.is_empty() {
    val
  } else {
    invalid_char!(ctx, ctx.view[0])
  }
}

///|
fn parse_value(ctx : ParseContext) -> JsonValue!ParseError {
  let tok = lex_value!(ctx)
  parse_value2!(ctx, tok)
}

///|
fn parse_value2(ctx : ParseContext, tok : Token) -> JsonValue!ParseError {
  match tok {
    Null => Null
    True => True
    False => False
    Number(n) => Number(n)
    String(s) => String(s)
    LBrace => parse_object!(ctx)
    LBracket => parse_array!(ctx)
    _ => abort("unreachable")
  }
}

///|
fn parse_object(ctx : ParseContext) -> JsonValue!ParseError {
  let map = Map::new()
  loop lex_property_name!(ctx) {
    RBrace => Object(map)
    String(name) => {
      guard let Colon = lex_after_property_name!(ctx)
      map[name] = parse_value!(ctx)
      match lex_after_object_value!(ctx) {
        Comma => continue lex_property_name2!(ctx)
        RBrace => Object(map)
        _ => abort("unreachable")
      }
    }
    _ => abort("unreachable")
  }
}

///|
fn parse_array(ctx : ParseContext) -> JsonValue!ParseError {
  let vec = []
  loop lex_value!(ctx, allow_rbracket=true) {
    RBracket => Array(vec)
    tok => {
      vec.push(parse_value2!(ctx, tok))
      let tok2 = lex_after_array_value!(ctx)
      match tok2 {
        Comma => continue lex_value!(ctx, allow_rbracket=false)
        RBracket => Array(vec)
        _ => abort("unreachable")
      }
    }
  }
}
