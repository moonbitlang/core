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
  ctx.lex_skip_whitespace()
  if ctx.offset >= ctx.end_offset {
    val
  } else {
    invalid_char!(ctx)
  }
}

///|
fn parse_value(ctx : ParseContext) -> JsonValue!ParseError {
  let tok = ctx.lex_value!()
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
  loop ctx.lex_property_name!() {
    RBrace => Object(map)
    String(name) => {
      guard let Colon = ctx.lex_after_property_name!()
      map[name] = parse_value!(ctx)
      match ctx.lex_after_object_value!() {
        Comma => continue ctx.lex_property_name2!()
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
  loop ctx.lex_value!(allow_rbracket=true) {
    RBracket => Array(vec)
    tok => {
      vec.push(parse_value2!(ctx, tok))
      let tok2 = ctx.lex_after_array_value!()
      match tok2 {
        Comma => continue ctx.lex_value!(allow_rbracket=false)
        RBracket => Array(vec)
        _ => abort("unreachable")
      }
    }
  }
}
