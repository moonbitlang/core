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
test "split/basic" {
  let regex = @bytes.BytesRegex(" ")
  let result = regex.split(b"hello world test").to_array()
  inspect(result.length(), content="3")
  inspect(result[0], content="b\"hello\"")
  inspect(result[1], content="b\"world\"")
  inspect(result[2], content="b\"test\"")
}

///|
test "split/multiple_delimiters" {
  let regex = @bytes.BytesRegex("[,:;]")
  let result = regex.split(b"a,b;c:d").to_array()
  inspect(result.length(), content="4")
  inspect(result[0], content="b\"a\"")
  inspect(result[1], content="b\"b\"")
  inspect(result[2], content="b\"c\"")
  inspect(result[3], content="b\"d\"")
}

///|
test "split/no_match" {
  let regex = @bytes.BytesRegex("xyz")
  let result = regex.split(b"hello world").to_array()
  inspect(result.length(), content="1")
  inspect(result[0], content="b\"hello world\"")
}

///|
test "split/consecutive_delimiters" {
  let regex = @bytes.BytesRegex(",")
  let result = regex.split(b"a,,b,,,c").to_array()
  inspect(result.length(), content="6")
  inspect(result[0], content="b\"a\"")
  inspect(result[1], content="b\"\"")
  inspect(result[2], content="b\"b\"")
  inspect(result[3], content="b\"\"")
  inspect(result[4], content="b\"\"")
  inspect(result[5], content="b\"c\"")
}

///|
test "split/entire_match" {
  let regex = @bytes.BytesRegex(".+")
  let result = regex.split(b"hello").to_array()
  inspect(result.length(), content="2")
  inspect(result[0], content="b\"\"")
  inspect(result[1], content="b\"\"")
}

///|
test "replace_by/zero_width_edge_case" {
  let regex = @bytes.BytesRegex("")
  let result = regex.replace_by(b"abc", _m => b"x")
  inspect(result, content="b\"xaxbxcx\"")
}

///|
test "replace_by/limit_basic" {
  let regex = @bytes.BytesRegex("[[:digit:]]+")
  let result = regex.replace_by(b"a1b22c333", _m => b"#", limit=2)
  inspect(result, content="b\"a#b#c333\"")
}

///|
test "replace_by/limit_zero" {
  let regex = @bytes.BytesRegex("[[:digit:]]+")
  let result = regex.replace_by(b"a1b22", _m => b"#", limit=0)
  inspect(result, content="b\"a1b22\"")
}

///|
test "replace_by/limit_with_empty_pattern" {
  let regex = @bytes.BytesRegex("")
  let result = regex.replace_by(b"abc", _m => b"x", limit=2)
  inspect(result, content="b\"xaxbc\"")
}

///|
test "split/word_boundaries" {
  let regex = @bytes.BytesRegex("\\b")
  let result = regex.split(b"hello world").to_array()
  inspect(result.length(), content="5")
  inspect(result[0], content="b\"\"")
  inspect(result[1], content="b\"hello\"")
  inspect(result[2], content="b\" \"")
  inspect(result[3], content="b\"world\"")
  inspect(result[4], content="b\"\"")
}

///|
test "find/capture_groups_and_named_groups" {
  let regex = @bytes.BytesRegex("(?<word>[a-z]+)-(?<num>[0-9]+)")
  let words = regex
    .find(b"ab-12 cd-345")
    .map(m => m.named_group("word").unwrap())
    .collect()
  let nums = regex.find(b"ab-12 cd-345").map(m => m.group(2).unwrap()).collect()
  let spans = regex
    .find(b"ab-12 cd-345")
    .map(m => (m.before().length(), m.content().length(), m.after().length()))
    .collect()
  let missing = regex
    .find(b"ab-12 cd-345")
    .map(m => m.named_group("missing"))
    .collect()
  inspect(words, content="[b\"ab\", b\"cd\"]")
  inspect(nums, content="[b\"12\", b\"345\"]")
  inspect(spans, content="[(0, 5, 7), (6, 6, 0)]")
  inspect(missing, content="[None, None]")
}

///|
test "find/next_and_exhaustion" {
  let regex = @bytes.BytesRegex("[[:digit:]]+")
  let iter = regex.find(b"a1b22")
  guard iter.next() is Some(first) else { fail("Expected first match") }
  guard iter.next() is Some(second) else { fail("Expected second match") }
  inspect(first.content(), content="b\"1\"")
  inspect(second.content(), content="b\"22\"")
  guard iter.next() is None else { fail("Expected iterator exhausted") }
}

///|
test "find/no_match" {
  let regex = @bytes.BytesRegex("xyz")
  let iter = regex.find(b"hello world")
  guard iter.next() is None else { fail("Expected no match") }
}

///|
test "find/word_boundary_positions" {
  let regex = @bytes.BytesRegex("\\b")
  let positions = regex
    .find(b"hello world")
    .map(m => m.before().length())
    .collect()
  inspect(positions, content="[0, 5, 6, 11]")
}

///|
test "find/empty_pattern_progress_and_empty_input" {
  let regex = @bytes.BytesRegex("")
  let positions = regex.find(b"abc").map(m => m.before().length()).collect()
  let empty_positions = regex.find(b"").map(m => m.before().length()).collect()
  inspect(positions, content="[0, 1, 2, 3]")
  inspect(empty_positions, content="[0]")
}

///|
test "split/empty_pattern_non_empty_and_empty_input" {
  let regex = @bytes.BytesRegex("")
  let result = regex.split(b"abc").to_array()
  let empty_result = regex.split(b"").to_array()
  inspect(result, content="[b\"\", b\"a\", b\"b\", b\"c\", b\"\"]")
  inspect(empty_result, content="[b\"\", b\"\"]")
}
