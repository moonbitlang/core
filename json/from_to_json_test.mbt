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
test "map JSON conversion sizes the result for live entries" {
  let source : Map[String, Int32] = Map(
    [
      for i in 0..<256 => (i.to_string(), i)
    ],
  )
  source.clear()
  source["first"] = 1
  source["second"] = 2
  source["third"] = 3
  let json = Json(source)
  guard json is Object(object) else { fail("expected object") }
  inspect(object.capacity(), content="4")
  // Also decode an explicitly sparse Json object, bypassing ToJson's sizing.
  let sparse = source.map((_, value) => Json(value))
  let decoded : Map[String, Int32] = @json.from_json(Json::object(sparse))
  inspect(decoded.capacity(), content="4")
  assert_eq(decoded.to_array(), source.to_array())
}

///|
// Older compilers expand this derive through deprecated String::to_json.
#warnings("-deprecated")
priv enum Expr {
  Add(Expr, Expr)
  Sub(Expr, Expr)
  Mul(Expr, Expr)
  Div(Expr, Expr)
  Val(String)
} derive(@json.ToJson, @json.FromJson, Debug, Eq)

///|
test {
  let e = Expr::Add(Val("x"), Val("y"))
  let ej = @json.ToJson::to_json(e)
  inspect(
    ej.stringify(),
    content=(
      #|["Add",["Val","x"],["Val","y"]]
    ),
  )
  let e0 : Expr = @json.from_json(ej)
  debug_inspect(
    e0,
    content=(
      #|Add(Val("x"), Val("y"))
    ),
  )
  assert_true(e0 == e)
}
