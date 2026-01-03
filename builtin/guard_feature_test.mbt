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
enum Expr {
  Add(Expr, Expr)
  Sub(Expr, Expr)
  Mul(Expr, Expr)
  Div(Expr, Expr)
  Lit(Int)
  Var(String)
} derive(Show, ToJson, Eq)

///|
fn simplify(e : Expr) -> Expr {
  match e {
    Add(e1, Lit(0)) => simplify(e1)
    Add(Lit(0), e2) => simplify(e2)
    Mul(e1, Lit(1)) => simplify(e1)
    Mul(Lit(1), e2) => simplify(e2)
    Sub(e1, e2) if e1 == e2 => Lit(0)
    // guard is useful for in-exhaustive match
    // otherwise the else condition will be duplicated
    Mul(Lit(0), _) => Lit(0)
    Mul(_, Lit(0)) => Lit(0)
    _ => e
  }
}

///|
test "simplify" {
  let _ignored = Add(Div(Lit(1), Lit(2)), Div(Lit(1), Lit(2)))
  let e = Sub(Mul(Lit(1), Var("x")), Mul(Lit(1), Var("x")))
  @json.inspect(e, content=[
    "Sub",
    ["Mul", ["Lit", 1], ["Var", "x"]],
    ["Mul", ["Lit", 1], ["Var", "x"]],
  ])
  let simplified = simplify(e)
  @json.inspect(simplified, content=["Lit", 0])
}
