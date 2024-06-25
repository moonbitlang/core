// Copyright 2024 International Digital Economy Academy
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

test "panic blit_negative_length" {
  let b1 = Bytes::of_string("abcdef")
  let b2 = Bytes::of_string("ABCDEF")
  // Attempt to blit with a negative length
  b1.blit(2, b2, 3, -1)
}

test "panic blit_out_of_bounds_src" {
  let b1 = Bytes::of_string("abcdef")
  let b2 = Bytes::of_string("ABCDEF")
  // Attempt to blit with src_offset + length exceeding src length
  b1.blit(4, b2, 10, 4)
}

test "panic blit_out_of_bounds_dst" {
  let b1 = Bytes::of_string("abcdef")
  let b2 = Bytes::of_string("ABCDEF")
  // Attempt to blit with dst_offset + length exceeding dst length
  b1.blit(8, b2, 6, 6)
}
