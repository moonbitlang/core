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
test "shrink tuple" {
  let x = (120, true)
  debug_inspect(
    @shrink.Shrink::shrink(x).collect(),
    content=(
      #|[
      #|  (119, true),
      #|  (117, true),
      #|  (113, true),
      #|  (105, true),
      #|  (90, true),
      #|  (60, true),
      #|  (0, true),
      #|  (120, false),
      #|]
    ),
  )
}

///|
test "shrink 6-tuple" {
  let x = (20, 'A', 30U, true, true, true)
  debug_inspect(
    @shrink.Shrink::shrink(x).collect(),
    content=(
      #|[
      #|  (19, 'A', 30, true, true, true),
      #|  (18, 'A', 30, true, true, true),
      #|  (15, 'A', 30, true, true, true),
      #|  (10, 'A', 30, true, true, true),
      #|  (0, 'A', 30, true, true, true),
      #|  (20, 'a', 30, true, true, true),
      #|  (20, 'b', 30, true, true, true),
      #|  (20, 'c', 30, true, true, true),
      #|  (20, 'A', 29, true, true, true),
      #|  (20, 'A', 27, true, true, true),
      #|  (20, 'A', 23, true, true, true),
      #|  (20, 'A', 15, true, true, true),
      #|  (20, 'A', 0, true, true, true),
      #|  (20, 'A', 30, false, true, true),
      #|  (20, 'A', 30, true, false, true),
      #|  (20, 'A', 30, true, true, false),
      #|]
    ),
  )
}
