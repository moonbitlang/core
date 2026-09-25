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
test "Queue capacity is forwarded to the backing deque" {
  inspect(Queue(([] : Array[Int]), capacity=16).inner.capacity(), content="16")
  inspect(Queue([1, 2, 3], capacity=1).inner.capacity(), content="3")
  inspect(Queue([1, 2, 3]).inner.capacity(), content="3")
}
