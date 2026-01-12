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
struct Context {
  mut next_expr_id : Int
  mut book : SlotBook
  mut book_dirty : Bool
}

///|
pub fn Context::new() -> Context {
  Context::{
    next_expr_id: EXPR_ID_RESERVED + 1,
    book: SlotBook::empty(),
    book_dirty: false,
  }
}

///|
fn Context::new_expr_id(ctx : Context) -> ExprId {
  let id = ctx.next_expr_id
  ctx.next_expr_id += 1
  id
}
