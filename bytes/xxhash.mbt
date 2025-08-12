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

// https://github.com/Cyan4973/xxHash/blob/dev/doc/xxhash_spec.md#xxh32-algorithm-description

///|
pub impl Hash for Bytes with hash_combine(self, hasher) {
  hasher.combine_bytes(self)
}

///|
test "Bytes hash_combine" {
  let data : Bytes = [1, 2, 3, 4]
  let hasher = Hasher::new()
  data.hash_combine(hasher)
  assert_true(hasher.finalize() != 0)
}
