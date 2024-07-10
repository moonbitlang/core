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

fn groud_truth(hashes : Array[Int]) -> Int {
  let b = Bytes::make(hashes.length() * 4)
  for i = 0; i < hashes.length(); i = i + 1 {
    let h = hashes[i]
    b[4 * i] = h.land(0xFF).to_byte()
    b[4 * i + 1] = h.lsr(8).land(0xFF).to_byte()
    b[4 * i + 2] = h.lsr(16).land(0xFF).to_byte()
    b[4 * i + 3] = h.lsr(24).land(0xFF).to_byte()
  }
  b.hash()
}

test "hash" {
  inspect(
    (1, 2).hash() == groud_truth([1, 2].map(fn(n) { n.hash() })),
    content="true",
  )!
  inspect(
    (1, 2, 3).hash() == groud_truth([1, 2, 3].map(fn(n) { n.hash() })),
    content="true",
  )!
  inspect(
    (1, 2, 3, 4).hash() == groud_truth([1, 2, 3, 4].map(fn(n) { n.hash() })),
    content="true",
  )!
  inspect(
    (1, 2, 3, 4, 5).hash() == groud_truth(
      [1, 2, 3, 4, 5].map(fn(n) { n.hash() }),
    ),
    content="true",
  )!
  inspect(
    (1, 2, 3, 4, 5, 6).hash() == groud_truth(
      [1, 2, 3, 4, 5, 6].map(fn(n) { n.hash() }),
    ),
    content="true",
  )!
  inspect(
    (1, 2, 3, 4, 5, 6, 7).hash() == groud_truth(
      [1, 2, 3, 4, 5, 6, 7].map(fn(n) { n.hash() }),
    ),
    content="true",
  )!
  inspect(
    (1, 2, 3, 4, 5, 6, 7, 8).hash() == groud_truth(
      [1, 2, 3, 4, 5, 6, 7, 8].map(fn(n) { n.hash() }),
    ),
    content="true",
  )!
}
