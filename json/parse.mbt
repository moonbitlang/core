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
  let val = ctx.parse_value!()
  ctx.lex_skip_whitespace()
  if ctx.offset >= ctx.end_offset {
    val
  } else {
    ctx.invalid_char!()
  }
}

///|
fn ParseContext::parse_value(ctx : ParseContext) -> JsonValue!ParseError {
  let tok = ctx.lex_value!(allow_rbracket=false)
  ctx.parse_value2!(tok)
}

///|
fn ParseContext::parse_value2(
  ctx : ParseContext,
  tok : Token
) -> JsonValue!ParseError {
  match tok {
    Null => Json::null()
    True => Json::boolean(true)
    False => Json::boolean(false)
    Number(n) => Json::number(n)
    String(s) => Json::string(s)
    LBrace => ctx.parse_object!()
    LBracket => ctx.parse_array!()
    RBracket | RBrace | Comma => abort("unreachable")
  }
}

///|
fn ParseContext::parse_object(ctx : ParseContext) -> JsonValue!ParseError {
  let map = Map::new()
  loop ctx.lex_property_name!() {
    RBrace => Json::object(map)
    String(name) => {
      ctx.lex_after_property_name!()
      map[name] = ctx.parse_value!()
      match ctx.lex_after_object_value!() {
        Comma => continue ctx.lex_property_name2!()
        RBrace => Json::object(map)
        _ => abort("unreachable")
      }
    }
    _ => abort("unreachable")
  }
}

///|
fn ParseContext::parse_array(ctx : ParseContext) -> JsonValue!ParseError {
  let vec = []
  loop ctx.lex_value!(allow_rbracket=true) {
    RBracket => Json::array(vec)
    tok => {
      vec.push(ctx.parse_value2!(tok))
      let tok2 = ctx.lex_after_array_value!()
      match tok2 {
        Comma => continue ctx.lex_value!(allow_rbracket=false)
        RBracket => Json::array(vec)
        _ => abort("unreachable")
      }
    }
  }
}
