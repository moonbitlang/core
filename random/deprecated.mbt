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
#deprecated("Use `Rand::new()` instead")
pub fn new(seed? : Bytes = b"ABCDEFGHIJKLMNOPQRSTUVWXYZ123456") -> Rand {
  if seed.length() != 32 {
    abort("seed must be 32 bytes long")
  }
  @random_source.ChaCha8::new(seed) as &Source
}

///|
/// Create a new random number generator with [seed].
#deprecated("You may use `Rand::chacha8(seed~)` instead of `Rand::new(chacha8(seed~))")
pub fn chacha8(seed? : Bytes = b"ABCDEFGHIJKLMNOPQRSTUVWXYZ123456") -> &Source {
  @random_source.ChaCha8::new(seed)
}
