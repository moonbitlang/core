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
pub struct Profile {
  lb : Rechar
  ub : Rechar
  valid : RecharSet
  word : RecharSet
  non_word : RecharSet
  digit : RecharSet
  non_digit : RecharSet
  space : RecharSet
  non_space : RecharSet
  line_terminator : RecharSet
  non_line_terminator : RecharSet
  case_insensitive : (RecharSet) -> RecharSet
  category : (Rechar) -> Category
}

///|
pub fn Profile::new(
  valid~ : RecharSet,
  word~ : RecharSet,
  digit~ : RecharSet,
  space~ : RecharSet,
  line_terminator~ : RecharSet,
  case_insensitive~ : (RecharSet) -> RecharSet,
  category~ : (Rechar) -> Category,
) -> Profile {
  guard valid.first_interval() is Some((lb, _)) else { panic() }
  guard valid.last_interval() is Some((_, ub)) else { panic() }
  let non_word = valid - word
  let non_digit = valid - digit
  let non_space = valid - space
  let non_line_terminator = valid - line_terminator
  Profile::{
    lb,
    ub,
    valid,
    word,
    non_word,
    digit,
    non_digit,
    space,
    non_space,
    line_terminator,
    non_line_terminator,
    case_insensitive,
    category,
  }
}
