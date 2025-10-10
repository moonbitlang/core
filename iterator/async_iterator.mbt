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
pub(all) struct AsyncIterator[A](async () -> A?)

///|
pub async fn[A] AsyncIterator::next(self : AsyncIterator[A]) -> A? {
  self()
}

///|
pub async fn[A, B] AsyncIterator::map(
  self : AsyncIterator[A],
  f : (A) -> B,
) -> AsyncIterator[B] {
  AsyncIterator(fn() {
    match self.next() {
      Some(x) => Some(f(x))
      None => None
    }
  })
}
