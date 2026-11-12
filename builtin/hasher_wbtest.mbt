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
/// Calls `f` while `crypto.getRandomValues` throws, as Cloudflare Workers
/// does while a module loads.
#cfg(target="js")
extern "js" fn with_refused_get_random_values(f : () -> Int32) -> Int32 =
  #|(f) => {
  #|  const crypto = globalThis.crypto;
  #|  if (crypto === undefined) {
  #|    return f(); // already the fallback
  #|  }
  #|  const original = crypto.getRandomValues;
  #|  crypto.getRandomValues = () => { throw new Error("refused"); };
  #|  try {
  #|    return f();
  #|  } finally {
  #|    crypto.getRandomValues = original;
  #|  }
  #|}

///|
#cfg(target="js")
test "random_seed falls back when getRandomValues is refused" {
  ignore(with_refused_get_random_values(random_seed))
}
