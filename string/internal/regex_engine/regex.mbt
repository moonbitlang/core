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
struct Regex {
  profile : Profile
  ctx : @automata.Context
  expr : @automata.Expr
  groups : ReadOnlyArray[String?]
  symbol_table : @symbol_map.Table
  symbol_repr : ReadOnlyArray[Rechar]
  start_states : Array[(Category, StateId)]
  state_table : @hashmap.HashMap[@automata.State, StateId]
  mut transition_table : FixedArray[StateId]
  mut final_table : FixedArray[
    @list.List[(Category, @automata.Slot, @automata.Status)],
  ]
  mut states : FixedArray[@automata.State]
  mut num_states : Int
}

///|
/// Function `group_names`.
pub fn Regex::group_names(self : Regex) -> ReadOnlyArray[String?] {
  self.groups
}

///|
fn Regex::new(
  profile : Profile,
  ctx : @automata.Context,
  expr : @automata.Expr,
  groups : ReadOnlyArray[String?],
  symbol_table : @symbol_map.Table,
  symbol_repr : ReadOnlyArray[Rechar],
) -> Regex {
  Regex::{
    profile,
    ctx,
    expr,
    groups,
    symbol_table,
    symbol_repr,
    start_states: [],
    state_table: @hashmap.HashMap::new(),
    transition_table: [],
    final_table: [],
    states: [],
    num_states: 0,
  }
}

///|
fn Regex::num_symbols(self : Regex) -> Int {
  self.symbol_repr.length()
}
