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

test "is_leading_surrogate_comprehensive" {
  // Test various leading surrogate values
  assert_eq(is_leading_surrogate(0xD800), true)  // min leading surrogate
  assert_eq(is_leading_surrogate(0xDBFF), true)  // max leading surrogate
  assert_eq(is_leading_surrogate(0xD900), true)  // middle leading surrogate
  assert_eq(is_leading_surrogate(0xDA00), true)  // another middle value
  
  // Test edge cases
  assert_eq(is_leading_surrogate(0xD7FF), false) // just below min
  assert_eq(is_leading_surrogate(0xDC00), false) // just above max (start of trailing)
  assert_eq(is_leading_surrogate(0x0000), false) // null character
  assert_eq(is_leading_surrogate(0xFFFF), false) // max unicode BMP
  
  // Test with actual emoji character codes
  let emoji_smile = "😀"
  assert_eq(is_leading_surrogate(emoji_smile.charcode_at(0)), true)
  assert_eq(is_leading_surrogate(emoji_smile.charcode_at(1)), false)
  
  let emoji_heart = "💖"
  assert_eq(is_leading_surrogate(emoji_heart.charcode_at(0)), true)
  assert_eq(is_leading_surrogate(emoji_heart.charcode_at(1)), false)
}

test "is_trailing_surrogate_comprehensive" {
  // Test various trailing surrogate values
  assert_eq(is_trailing_surrogate(0xDC00), true)  // min trailing surrogate
  assert_eq(is_trailing_surrogate(0xDFFF), true)  // max trailing surrogate
  assert_eq(is_trailing_surrogate(0xDD00), true)  // middle trailing surrogate
  assert_eq(is_trailing_surrogate(0xDE00), true)  // another middle value
  
  // Test edge cases
  assert_eq(is_trailing_surrogate(0xDBFF), false) // just below min (end of leading)
  assert_eq(is_trailing_surrogate(0xE000), false) // just above max
  assert_eq(is_trailing_surrogate(0x0000), false) // null character
  assert_eq(is_trailing_surrogate(0xFFFF), false) // max unicode BMP
  
  // Test with actual emoji character codes
  let emoji_smile = "😀"
  assert_eq(is_trailing_surrogate(emoji_smile.charcode_at(0)), false)
  assert_eq(is_trailing_surrogate(emoji_smile.charcode_at(1)), true)
  
  let emoji_heart = "💖"
  assert_eq(is_trailing_surrogate(emoji_heart.charcode_at(0)), false)
  assert_eq(is_trailing_surrogate(emoji_heart.charcode_at(1)), true)
}

test "code_point_of_surrogate_pair_comprehensive" {
  // Test various emoji characters
  let emoji_smile = "😀"
  let leading_smile = emoji_smile.charcode_at(0)
  let trailing_smile = emoji_smile.charcode_at(1)
  assert_eq(code_point_of_surrogate_pair(leading_smile, trailing_smile), '😀')
  
  let emoji_heart = "💖"
  let leading_heart = emoji_heart.charcode_at(0)
  let trailing_heart = emoji_heart.charcode_at(1)
  assert_eq(code_point_of_surrogate_pair(leading_heart, trailing_heart), '💖')
  
  let emoji_rocket = "🚀"
  let leading_rocket = emoji_rocket.charcode_at(0)
  let trailing_rocket = emoji_rocket.charcode_at(1)
  assert_eq(code_point_of_surrogate_pair(leading_rocket, trailing_rocket), '🚀')
  
  let emoji_cat = "🐱"
  let leading_cat = emoji_cat.charcode_at(0)
  let trailing_cat = emoji_cat.charcode_at(1)
  assert_eq(code_point_of_surrogate_pair(leading_cat, trailing_cat), '🐱')
  
  // Test with various other unicode characters that use surrogate pairs
  let musical_note = "🎵"
  let leading_note = musical_note.charcode_at(0)
  let trailing_note = musical_note.charcode_at(1)
  assert_eq(code_point_of_surrogate_pair(leading_note, trailing_note), '🎵')
  
  let thumbs_up = "👍"
  let leading_thumbs = thumbs_up.charcode_at(0)
  let trailing_thumbs = thumbs_up.charcode_at(1)
  assert_eq(code_point_of_surrogate_pair(leading_thumbs, trailing_thumbs), '👍')
}

test "surrogate_pair_edge_cases" {
  // Test minimum surrogate pair values
  let min_leading = 0xD800
  let min_trailing = 0xDC00
  let min_char = code_point_of_surrogate_pair(min_leading, min_trailing)
  // This should create a valid character (U+10000)
  assert_eq(min_char.to_int(), 0x10000)
  
  // Test maximum surrogate pair values
  let max_leading = 0xDBFF
  let max_trailing = 0xDFFF
  let max_char = code_point_of_surrogate_pair(max_leading, max_trailing)
  // This should create U+10FFFF
  assert_eq(max_char.to_int(), 0x10FFFF)
  
  // Test middle values
  let mid_leading = 0xD900
  let mid_trailing = 0xDD00
  let mid_char = code_point_of_surrogate_pair(mid_leading, mid_trailing)
  // This should create a valid character in the supplementary plane
  assert_eq(mid_char.to_int() >= 0x10000, true)
  assert_eq(mid_char.to_int() <= 0x10FFFF, true)
}

test "surrogate_verification_with_strings" {
  // Test that various emoji strings have proper surrogate pairs
  let emojis = ["😀", "🌟", "💖", "🚀", "🎵", "👍", "🐱", "🌈", "⭐", "🔥"]
  
  for emoji in emojis {
    // Each emoji should have exactly 2 code units (surrogate pair)
    assert_eq(emoji.length(), 2)
    
    // First code unit should be a leading surrogate
    assert_eq(is_leading_surrogate(emoji.charcode_at(0)), true)
    
    // Second code unit should be a trailing surrogate
    assert_eq(is_trailing_surrogate(emoji.charcode_at(1)), true)
    
    // Reconstructing the character should give back the original
    let reconstructed = code_point_of_surrogate_pair(
      emoji.charcode_at(0),
      emoji.charcode_at(1)
    )
    assert_eq(reconstructed.to_string(), emoji)
  }
}