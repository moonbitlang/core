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

test "prng" {
  let r = @rand.Rand::new()
  assert_eq!(r.uintN(10), 7)
  assert_eq!(r.uintN(10), 0)
  assert_eq!(r.uintN(10), 5)
  assert_eq!(r.int(), 1064320769)
  assert_eq!(r.double64(), 0.3318940049218405)
  assert_eq!(r.intN(10), 0)
}
