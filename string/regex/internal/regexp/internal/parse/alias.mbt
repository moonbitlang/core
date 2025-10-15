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
using @ast {type Ast}

///|
using @unicode {case_insensitive_char_class, compute_char_class_complement}

///|
let ranges_is_digit = @unicode.ranges_is_digit

///|
let ranges_is_not_digit = @unicode.ranges_is_not_digit

///|
let ranges_is_word = @unicode.ranges_is_word

///|
let ranges_is_not_word = @unicode.ranges_is_not_word

///|
let ranges_is_white_space_or_line_terminator = @unicode.ranges_is_white_space_or_line_terminator

///|
let ranges_is_not_white_space_or_line_terminator = @unicode.ranges_is_not_white_space_or_line_terminator

///|
let ranges_any = @unicode.ranges_any

///|
let ranges_any_not_new_line = @unicode.ranges_any_not_new_line
