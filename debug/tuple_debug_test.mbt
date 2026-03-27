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
test "tuple Debug implementations" {
  @debug.debug_inspect(
    (1, "a"),
    content=(
      #|(1, "a")
    ),
  )

  @debug.debug_inspect(
    (1, "a", true),
    content=(
      #|(1, "a", true)
    ),
  )

  @debug.debug_inspect(
    (1, "a", true, 2.0),
    content=(
      #|(1, "a", true, 2)
    ),
  )

  @debug.debug_inspect(
    (1, "a", true, 2.0, 'c'),
    content=(
      #|(1, "a", true, 2, 'c')
    ),
  )

  @debug.debug_inspect(
    (1, "a", true, 2.0, 'c', 6),
    content=(
      #|(1, "a", true, 2, 'c', 6)
    ),
  )

  @debug.debug_inspect(
    (1, "a", true, 2.0, 'c', 6, "g"),
    content=(
      #|(1, "a", true, 2, 'c', 6, "g")
    ),
  )

  @debug.debug_inspect(
    (1, "a", true, 2.0, 'c', 6, "g", false),
    content=(
      #|(1, "a", true, 2, 'c', 6, "g", false)
    ),
  )

  @debug.debug_inspect(
    (1, "a", true, 2.0, 'c', 6, "g", false, 9N),
    content=(
      #|(1, "a", true, 2, 'c', 6, "g", false, 9)
    ),
  )

  @debug.debug_inspect(
    (1, "a", true, 2.0, 'c', 6, "g", false, 9, "j"),
    content=(
      #|(1, "a", true, 2, 'c', 6, "g", false, 9, "j")
    ),
  )

  @debug.debug_inspect(
    (1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11),
    content=(
      #|(1, "a", true, 2, 'c', 6, "g", false, 9, "j", 11)
    ),
  )

  @debug.debug_inspect(
    (1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l"),
    content=(
      #|(1, "a", true, 2, 'c', 6, "g", false, 9, "j", 11, "l")
    ),
  )

  @debug.debug_inspect(
    (1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l", 13),
    content=(
      #|(1, "a", true, 2, 'c', 6, "g", false, 9, "j", 11, "l", 13)
    ),
  )

  @debug.debug_inspect(
    (1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n"),
    content=(
      #|(1, "a", true, 2, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n")
    ),
  )

  @debug.debug_inspect(
    (1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n", 15),
    content=(
      #|(1, "a", true, 2, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n", 15)
    ),
  )

  @debug.debug_inspect(
    (1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n", 15, "p"),
    content=(
      #|(
      #|  1,
      #|  "a",
      #|  true,
      #|  2,
      #|  'c',
      #|  6,
      #|  "g",
      #|  false,
      #|  9,
      #|  "j",
      #|  11,
      #|  "l",
      #|  13,
      #|  "n",
      #|  15,
      #|  "p",
      #|)
    ),
  )

  @debug.debug_inspect(
    (
      1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n", 15, "p", 17,
    ),
    content=(
      #|(
      #|  1,
      #|  "a",
      #|  true,
      #|  2,
      #|  'c',
      #|  6,
      #|  "g",
      #|  false,
      #|  9,
      #|  "j",
      #|  11,
      #|  "l",
      #|  13,
      #|  "n",
      #|  15,
      #|  "p",
      #|  17,
      #|)
    ),
  )

  @debug.debug_inspect(
    (
      1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n", 15, "p", 17,
      "r",
    ),
    content=(
      #|(
      #|  1,
      #|  "a",
      #|  true,
      #|  2,
      #|  'c',
      #|  6,
      #|  "g",
      #|  false,
      #|  9,
      #|  "j",
      #|  11,
      #|  "l",
      #|  13,
      #|  "n",
      #|  15,
      #|  "p",
      #|  17,
      #|  "r",
      #|)
    ),
  )

  @debug.debug_inspect(
    (
      1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n", 15, "p", 17,
      "r", 19,
    ),
    content=(
      #|(
      #|  1,
      #|  "a",
      #|  true,
      #|  2,
      #|  'c',
      #|  6,
      #|  "g",
      #|  false,
      #|  9,
      #|  "j",
      #|  11,
      #|  "l",
      #|  13,
      #|  "n",
      #|  15,
      #|  "p",
      #|  17,
      #|  "r",
      #|  19,
      #|)
    ),
  )

  @debug.debug_inspect(
    (
      1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n", 15, "p", 17,
      "r", 19, "t",
    ),
    content=(
      #|(
      #|  1,
      #|  "a",
      #|  true,
      #|  2,
      #|  'c',
      #|  6,
      #|  "g",
      #|  false,
      #|  9,
      #|  "j",
      #|  11,
      #|  "l",
      #|  13,
      #|  "n",
      #|  15,
      #|  "p",
      #|  17,
      #|  "r",
      #|  19,
      #|  "t",
      #|)
    ),
  )

  @debug.debug_inspect(
    (
      1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n", 15, "p", 17,
      "r", 19, "t", 21,
    ),
    content=(
      #|(
      #|  1,
      #|  "a",
      #|  true,
      #|  2,
      #|  'c',
      #|  6,
      #|  "g",
      #|  false,
      #|  9,
      #|  "j",
      #|  11,
      #|  "l",
      #|  13,
      #|  "n",
      #|  15,
      #|  "p",
      #|  17,
      #|  "r",
      #|  19,
      #|  "t",
      #|  21,
      #|)
    ),
  )

  @debug.debug_inspect(
    (
      1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n", 15, "p", 17,
      "r", 19, "t", 21, "v",
    ),
    content=(
      #|(
      #|  1,
      #|  "a",
      #|  true,
      #|  2,
      #|  'c',
      #|  6,
      #|  "g",
      #|  false,
      #|  9,
      #|  "j",
      #|  11,
      #|  "l",
      #|  13,
      #|  "n",
      #|  15,
      #|  "p",
      #|  17,
      #|  "r",
      #|  19,
      #|  "t",
      #|  21,
      #|  "v",
      #|)
    ),
  )
}
