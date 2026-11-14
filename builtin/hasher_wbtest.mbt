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
/// does while a module loads, and returns how many times it was called.
///
/// Without a global `crypto`, a fake one whose `getRandomValues` throws is
/// installed instead, so the refused path is tested on every host.
#cfg(target="js")
extern "js" fn with_refused_get_random_values(f : () -> Int32) -> Int32 =
  #|(f) => {
  #|  let calls = 0;
  #|  const refuse = () => {
  #|    calls += 1;
  #|    throw new Error("refused");
  #|  };
  #|  const crypto = globalThis.crypto;
  #|  const [obj, key, value] = crypto === undefined
  #|    ? [globalThis, "crypto", { getRandomValues: refuse }]
  #|    : [crypto, "getRandomValues", refuse];
  #|  // Throws, failing the test, if the property cannot be replaced
  #|  const saved = Object.getOwnPropertyDescriptor(obj, key);
  #|  Object.defineProperty(obj, key, { value, configurable: true, writable: true });
  #|  try {
  #|    f();
  #|  } finally {
  #|    if (saved === undefined) {
  #|      delete obj[key];
  #|    } else {
  #|      Object.defineProperty(obj, key, saved);
  #|    }
  #|  }
  #|  return calls;
  #|}

///|
/// Calls `f` while `globalThis.crypto` is undefined, as on hosts without Web
/// Crypto.
#cfg(target="js")
extern "js" fn with_missing_crypto(f : () -> Int32) -> Unit =
  #|(f) => {
  #|  const saved = Object.getOwnPropertyDescriptor(globalThis, "crypto");
  #|  Object.defineProperty(globalThis, "crypto", {
  #|    value: undefined,
  #|    configurable: true,
  #|    writable: true,
  #|  });
  #|  try {
  #|    f();
  #|  } finally {
  #|    if (saved === undefined) {
  #|      delete globalThis.crypto;
  #|    } else {
  #|      Object.defineProperty(globalThis, "crypto", saved);
  #|    }
  #|  }
  #|}

///|
/// Whether `globalThis.crypto` has an own `getRandomValues`, which the stub
/// above must not leave behind.
#cfg(target="js")
extern "js" fn crypto_has_own_get_random_values() -> Bool =
  #|() => globalThis.crypto !== undefined &&
  #|  Object.hasOwn(globalThis.crypto, "getRandomValues")

///|
#cfg(target="js")
test "random_seed falls back when getRandomValues is refused" {
  let had_own = crypto_has_own_get_random_values()
  inspect(with_refused_get_random_values(random_seed), content="1")
  inspect(crypto_has_own_get_random_values() == had_own, content="true")
}

///|
#cfg(target="js")
test "random_seed falls back without Web Crypto" {
  with_missing_crypto(() => random_seed())
}
