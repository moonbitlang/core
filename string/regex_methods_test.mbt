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
fn has_unpaired_surrogate(str : StringView) -> Bool {
  let mut index = 0
  while index < str.length() {
    let code_unit = str.code_unit_at(index)
    if code_unit.is_leading_surrogate() {
      if index + 1 >= str.length() {
        return true
      }
      if !str.code_unit_at(index + 1).is_trailing_surrogate() {
        return true
      }
      index += 2
    } else {
      if code_unit.is_trailing_surrogate() {
        return true
      }
      index += 1
    }
  }
  false
}

///|
test "split/basic" {
  let regex = @string.Regex(" ")
  let result = regex.split("hello world test").to_array()
  inspect(result.length(), content="3")
  inspect(result[0], content="hello")
  inspect(result[1], content="world")
  inspect(result[2], content="test")
}

///|
test "split/multiple_spaces" {
  let regex = @string.Regex("[[:space:]]+")
  let result = regex.split("hello   world\t\ntest").to_array()
  inspect(result.length(), content="3")
  inspect(result[0], content="hello")
  inspect(result[1], content="world")
  inspect(result[2], content="test")
}

///|
test "split/digit_delimiter" {
  let regex = @string.Regex("[[:digit:]]+")
  let result = regex.split("abc123def456ghi").to_array()
  inspect(result.length(), content="3")
  inspect(result[0], content="abc")
  inspect(result[1], content="def")
  inspect(result[2], content="ghi")
}

///|
test "split/no_match" {
  let regex = @string.Regex("xyz")
  let result = regex.split("hello world test").to_array()
  inspect(result.length(), content="1")
  inspect(result[0], content="hello world test")
}

///|
test "split/pattern_at_start" {
  let regex = @string.Regex("^hello")
  let result = regex.split("hello world test").to_array()
  inspect(result.length(), content="2")
  inspect(result[0], content="")
  inspect(result[1], content=" world test")
}

///|
test "split/pattern_at_end" {
  let regex = @string.Regex("test$")
  let result = regex.split("hello world test").to_array()
  inspect(result.length(), content="2")
  inspect(result[0], content="hello world ")
  inspect(result[1], content="")
}

///|
test "split/consecutive_delimiters" {
  let regex = @string.Regex(",")
  let result = regex.split("a,,b,,,c").to_array()
  inspect(result.length(), content="6")
  inspect(result[0], content="a")
  inspect(result[1], content="")
  inspect(result[2], content="b")
  inspect(result[3], content="")
  inspect(result[4], content="")
  inspect(result[5], content="c")
}

///|
test "split/empty_string" {
  let regex = @string.Regex("a")
  let result = regex.split("").to_array()
  inspect(result.length(), content="1")
  inspect(result[0], content="")
}

///|
test "split/single_character" {
  let regex = @string.Regex("a")
  let result = regex.split("banana").to_array()
  inspect(result.length(), content="4")
  inspect(result[0], content="b")
  inspect(result[1], content="n")
  inspect(result[2], content="n")
  inspect(result[3], content="")
}

///|
test "split/unicode" {
  let regex = @string.Regex("，")
  let result = regex.split("你好，世界，谢谢").to_array()
  inspect(result.length(), content="3")
  inspect(result[0], content="你好")
  inspect(result[1], content="世界")
  inspect(result[2], content="谢谢")
}

///|
test "split/alternation_pattern" {
  let regex = @string.Regex("[,;]")
  let result = regex.split("a,b;c,d").to_array()
  inspect(result.length(), content="4")
  inspect(result[0], content="a")
  inspect(result[1], content="b")
  inspect(result[2], content="c")
  inspect(result[3], content="d")
}

///|
test "split/complex_pattern" {
  let regex = @string.Regex("[[:alpha:]]+")
  let result = regex.split("123abc456def789").to_array()
  inspect(result.length(), content="3")
  inspect(result[0], content="123")
  inspect(result[1], content="456")
  inspect(result[2], content="789")
}

///|
test "split/single_element_no_split" {
  let regex = @string.Regex(",")
  let result = regex.split("hello").to_array()
  inspect(result.length(), content="1")
  inspect(result[0], content="hello")
}

///|
test "split/entire_match" {
  let regex = @string.Regex(".+")
  let result = regex.split("hello").to_array()
  inspect(result.length(), content="2")
  inspect(result[0], content="")
  inspect(result[1], content="")
}

///|
test "split/word_boundaries" {
  let regex = @string.Regex("\\b")
  let result = regex.split("hello world").to_array()
  inspect(result.length(), content="5")
  inspect(result[0], content="")
  inspect(result[1], content="hello")
  inspect(result[2], content=" ")
  inspect(result[3], content="world")
  inspect(result[4], content="")
}

///|
test "split/non_word_boundary_does_not_break_surrogate_pair" {
  let regex = @string.Regex("\\B")
  let result = regex.split("a😀b").to_array()
  let mut has_broken_part = false
  for part in result {
    has_broken_part = has_broken_part || has_unpaired_surrogate(part)
  }
  inspect(has_broken_part, content="false")
}

///|
test "split_replace/range_crossing_surrogate_gap_does_not_break_surrogate_pair" {
  let regex = @string.Regex("[\\uD7FF-\\uE000]")
  let split_result = regex.split("😀").to_array()
  inspect(split_result, content="[\"😀\"]")

  let replaced = regex.replace_by("😀", _m => "#")
  inspect(replaced, content="😀")
}

///|
test "replace_by/zero_width_edge_case" {
  let regex = @string.Regex("")
  let result = regex.replace_by("abc", _m => "x")
  inspect(result, content="xaxbxcx")
}

///|
test "replace_by/limit_basic" {
  let regex = @string.Regex("[[:digit:]]+")
  let result = regex.replace_by("a1b22c333", _m => "#", limit=2)
  inspect(result, content="a#b#c333")
}

///|
test "replace_by/limit_zero" {
  let regex = @string.Regex("[[:digit:]]+")
  let result = regex.replace_by("a1b22", _m => "#", limit=0)
  inspect(result, content="a1b22")
}

///|
test "replace_by/limit_with_empty_pattern_and_surrogate_pair" {
  let regex = @string.Regex("")
  let result = regex.replace_by("a😀b", _m => "x", limit=2)
  inspect(result, content="xax😀b")
}

///|
test "replace_by/zero_width_with_surrogate_pair" {
  let regex = @string.Regex("")
  let result = regex.replace_by("a😀b", _m => "x")
  inspect(result, content="xax😀xbx")
}

///|
test "replace_by/non_word_boundary_does_not_break_surrogate_pair" {
  let regex = @string.Regex("\\B")
  let result = regex.replace_by("a😀b", _m => "x")
  inspect(has_unpaired_surrogate(result), content="false")
}

///|
test "split/zero_width_with_surrogate_pair" {
  let regex = @string.Regex("")
  let result = regex.split("a😀b").to_array()
  inspect(result, content="[\"\", \"a\", \"😀\", \"b\", \"\"]")
}

///|
test "split/empty_pattern_empty_input" {
  let regex = @string.Regex("")
  let result = regex.split("").to_array()
  inspect(result, content="[\"\", \"\"]")
}

///|
test "split/long_string" {
  let regex = @string.Regex(",")
  let result = regex.split("a,b,c,d,e,f,g,h,i,j").to_array()
  inspect(result.length(), content="10")
  inspect(result[0], content="a")
  inspect(result[9], content="j")
}

///|
test "split/alternation_multiple" {
  let regex = @string.Regex("[abc]")
  let result = regex.split("xayazbzc").to_array()
  inspect(result.length(), content="5")
  inspect(result[0], content="x")
  inspect(result[1], content="y")
  inspect(result[2], content="z")
  inspect(result[3], content="z")
  inspect(result[4], content="")
}

///|
test "split/tab_and_newline" {
  let regex = @string.Regex("[\t\n]")
  let result = regex.split("a\tb\nc").to_array()
  inspect(result.length(), content="3")
  inspect(result[0], content="a")
  inspect(result[1], content="b")
  inspect(result[2], content="c")
}

///|
test "find/capture_groups_and_named_groups" {
  let regex = @string.Regex("(?<word>[a-z]+)-(?<num>[0-9]+)")
  let words = regex
    .find("ab-12 cd-345")
    .map(m => m.named_group("word").unwrap())
    .collect()
  let nums = regex.find("ab-12 cd-345").map(m => m.group(2).unwrap()).collect()
  let spans = regex
    .find("ab-12 cd-345")
    .map(m => (m.before().length(), m.content().length(), m.after().length()))
    .collect()
  let missing = regex
    .find("ab-12 cd-345")
    .map(m => m.named_group("missing"))
    .collect()
  inspect(words, content="[\"ab\", \"cd\"]")
  inspect(nums, content="[\"12\", \"345\"]")
  inspect(spans, content="[(0, 5, 7), (6, 6, 0)]")
  inspect(missing, content="[None, None]")
}

///|
test "find/next_and_exhaustion" {
  let regex = @string.Regex("[[:digit:]]+")
  let iter = regex.find("a1b22")
  guard iter.next() is Some(first) else { fail("Expected first match") }
  guard iter.next() is Some(second) else { fail("Expected second match") }
  inspect(first.content(), content="1")
  inspect(second.content(), content="22")
  guard iter.next() is None else { fail("Expected iterator exhausted") }
}

///|
test "find/no_match" {
  let regex = @string.Regex("xyz")
  let iter = regex.find("hello world")
  guard iter.next() is None else { fail("Expected no match") }
}

///|
test "find/word_boundary_positions" {
  let regex = @string.Regex("\\b")
  let positions = regex
    .find("hello world")
    .map(m => m.before().length())
    .collect()
  inspect(positions, content="[0, 5, 6, 11]")
}

///|
test "find/empty_pattern_progress_and_empty_input" {
  let regex = @string.Regex("")
  let positions = regex.find("abc").map(m => m.before().length()).collect()
  let surrogate_positions = regex
    .find("a😀b")
    .map(m => m.before().length())
    .collect()
  let empty_positions = regex.find("").map(m => m.before().length()).collect()
  inspect(positions, content="[0, 1, 2, 3]")
  inspect(surrogate_positions, content="[0, 1, 3, 4]")
  inspect(empty_positions, content="[0]")
}
