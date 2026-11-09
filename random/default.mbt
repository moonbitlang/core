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
let default_rand : @lazy.Lazy[Rand] = Lazy(() => Rand())

///|
/// Returns a non-negative pseudo-random `Int32` using a shared generator.
/// With a positive `limit`, the result is uniformly distributed in `0..<limit`.
/// If `limit` is omitted, the result is in `0..<2^31`.
/// Aborts if an explicitly supplied `limit` is zero or negative.
///
/// The generator is initialized on first use, using platform entropy when
/// available and a fixed default seed otherwise. Subsequent calls advance
/// the same generator. Use `Rand::chacha8(seed~)` for an independent,
/// reproducible sequence.
/// The shared generator is not thread-safe; calls from multiple threads
/// require external synchronization.
///
/// # Example
/// ```mbt check
/// test {
///   let die = @random.int32(limit=6) + 1
///   inspect(die >= 1 && die <= 6, content="true")
/// }
/// ```
pub fn int32(limit? : Int32) -> Int32 {
  match limit {
    None => default_rand.force().int()
    Some(limit) => {
      guard limit > 0 else { abort("int32: limit must be positive") }
      default_rand.force().int(limit~)
    }
  }
}
