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
/// A mutex for synchronization between multiple tasks.
/// Essentially a mutex is just a semaphore of size one.
#valtype
struct Mutex {
  semaphore : Semaphore
}

///|
/// Create a new mutex.
/// The mutex is initially in released state.
pub fn Mutex::Mutex() -> Mutex {
  { semaphore: Semaphore(1), }
}

///|
/// Acquire the mutex.
///
/// If the mutex is already acquired by someone else,
/// `acquire` will wait until the mutex is released.
///
/// If several tasks are both waiting for the mutex,
/// they will acquire the mutex in a first-come-first-serve manner
///
/// `acquire` is cancellation safe.
/// When `acquire` is cancelled, it will never trigger any side effect.
/// In particular, a cancelled `acquire` request will never actually acquire the mutex.
pub async fn Mutex::acquire(self : Mutex) -> Unit noraise {
  self.semaphore.acquire()
}

///|
/// Try to acquire the mutex, but do not wait for it.
/// If the mutex is currently available, it will be acquired and `true` will be returned.
/// If the mutex is currently not available, `false` will be returned.
///
/// `try_acquire` follow the same FIFO rule of `acquire`:
/// if there are `acquire` call waiting for the mutex, `try_acquire` always return `false`.
pub fn Mutex::try_acquire(self : Mutex) -> Bool {
  self.semaphore.try_acquire()
}

///|
/// Release the mutex.
/// The mutex must have been acquired, otherwise the program will abort.
pub fn Mutex::release(self : Mutex) -> Unit {
  self.semaphore.release()
}
