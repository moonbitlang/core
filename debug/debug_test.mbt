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
test "inspect" {
  @debug.debug_inspect(
    Some("msg"),
    content=(
      #|Some("msg")
    ),
  )
  @debug.debug_inspect(
    ["data1", "data2"],
    content=(
      #|["data1", "data2"]
    ),
  )
}

///|
fn output(x : Result[Unit, Error]) -> StringView {
  match x {
    Err(Failure::Failure(s)) =>
      if s lexmatch? (_, "FAILED:", next) {
        "FAILED:\{next}"
      } else {
        s
      }
    Ok(_) => "ok"
    Err(e) =>
      if "\{e}" lexmatch? (_, "FAILED:", next) {
        "FAILED:\{next}"
      } else {
        "\{e}"
      }
  }
}

///|
enum Point {
  Point(x~ : Int, y~ : Int)
} derive(Eq, Debug)

///|
test "assert_eq for extra value kinds" {
  inspect(
    output(try? @debug.assert_eq(-2.0, 1.0)),
    content=(
      #|FAILED: `-2 != 1`
      #|diff:
      #|--2 +1
    ),
  )
  inspect(
    output(try? @debug.assert_eq(((1.5 : Float), 1), ((1.5 : Float), 2))),
    content=(
      #|FAILED: `(1.5, 1) != (1.5, 2)`
      #|diff:
      #|(1.5, -1, +2)
    ),
  )
  inspect(
    output(try? @debug.assert_eq(('a', 1), ('a', 2))),
    content=(
      #|FAILED: `('a', 1) != ('a', 2)`
      #|diff:
      #|('a', -1, +2)
    ),
  )
  inspect(
    output(try? @debug.assert_eq({ "x": 1, "y": 2 }, { "x": 1, "y": 3 })),
    content=(
      #|FAILED: `{ "x": 1, "y": 2 } != { "x": 1, "y": 3 }`
      #|diff:
      #|{ "x": 1, "y": -2 +3 }
    ),
  )
  inspect(
    output(
      try? @debug.assert_eq(Point::Point(x=1, y=2), Point::Point(x=1, y=3)),
    ),
    content=(
      #|FAILED: `Point(x=1, y=2) != Point(x=1, y=3)`
      #|diff:
      #|Point(x=1, -y=2, +y=3)
    ),
  )
  inspect(
    output(
      try? @debug.assert_eq(@list.from_array([1, 2]), @list.from_array([1, 3])),
    ),
    content=(
      #|FAILED: `<List: [1, 2]> != <List: [1, 3]>`
      #|diff:
      #|<List: -[1, 2], +[1, 3]>
    ),
  )
}

///|
test "assert_eq for matcher paths" {
  inspect(
    output(try? @debug.assert_eq([1, 2, 3], [2, 1, 3])),
    content=(
      #|FAILED: `[1, 2, 3] != [2, 1, 3]`
      #|diff:
      #|[1, ~2
      #| -> 2, 3]
    ),
  )
  inspect(
    output(try? @debug.assert_eq(([1, 3], [2]), ([3], [1, 2]))),
    content=(
      #|FAILED: `([1, 3], [2]) != ([3], [1, 2])`
      #|diff:
      #|-([1, 3], [2]) +([3], [1, 2])
    ),
  )
  inspect(
    output(
      try? @debug.assert_eq({ "a": [1, 3], "b": [2] }, { "a": [3], "b": [1, 2] }),
    ),
    content=(
      #|FAILED: `{ "a": [1, 3], "b": [2] } != { "a": [3], "b": [1, 2] }`
      #|diff:
      #|{ "a": [~1
      #| -> 1, 3], "b": [2] }
    ),
  )
  inspect(
    output(
      try? @debug.assert_eq({ "a": [1, 2], "b": [3] }, { "a": [2], "b": [9, 3] }),
    ),
    content=(
      #|FAILED: `{ "a": [1, 2], "b": [3] } != { "a": [2], "b": [9, 3] }`
      #|diff:
      #|{ "a": [-1, 2], "b": [+9, 3] }
    ),
  )
}

///|
test "assert_eq" {
  inspect(output(try? @debug.assert_eq(1, 1)), content="ok")
  inspect(
    output(try? @debug.assert_eq(1, 2)),
    content=(
      #|FAILED: `1 != 2`
      #|diff:
      #|-1 +2
    ),
  )
  inspect(
    output(try? @debug.assert_eq("a", "b")),
    content=(
      #|FAILED: `"a" != "b"`
      #|diff:
      #|-"a" +"b"
    ),
  )
  inspect(output(try? @debug.assert_eq([1, 2, 3], [1, 2, 3])), content="ok")
  inspect(
    output(try? @debug.assert_eq([1, 2, 3], [1, 222, 3])),
    content=(
      #|FAILED: `[1, 2, 3] != [1, 222, 3]`
      #|diff:
      #|[1, -2, +222, 3]
    ),
  )
  inspect(
    output(try? @debug.assert_eq((true, "string", 123), (true, "s", 1))),
    content=(
      #|FAILED: `(true, "string", 123) != (true, "s", 1)`
      #|diff:
      #|(true, -"string", -123, +"s", +1)
    ),
  )
  inspect(
    output(try? @debug.assert_eq({ "k1": 1.0, "k2": 2 }, { "k1": 2, "k3": 5 })),
    content=(
      #|FAILED: `{ "k1": 1, "k2": 2 } != { "k1": 2, "k3": 5 }`
      #|diff:
      #|{ "k1": -1 +2, -"k2": 2, +"k3": 5 }
    ),
  )
  inspect(
    output(try? @debug.assert_eq(1, 2, msg="numbers mismatch")),
    content="FAILED: numbers mismatch",
  )
  inspect(
    output(try? @debug.assert_eq(Some(1), Some(2))),
    content=(
      #|FAILED: `Some(1) != Some(2)`
      #|diff:
      #|Some(-1, +2)
    ),
  )
  inspect(
    output(try? @debug.assert_eq(Result::Ok(1), Err("e"))),
    content=(
      #|FAILED: `Ok(1) != Err("e")`
      #|diff:
      #|-Ok(1) +Err("e")
    ),
  )
}

///|
test "assert_eq for arrays" {
  inspect(
    output(try? @debug.assert_eq([1, 2], [1, 2, 3])),
    content=(
      #|FAILED: `[1, 2] != [1, 2, 3]`
      #|diff:
      #|[1, 2, +3]
    ),
  )
  inspect(
    output(try? @debug.assert_eq([1, 2], [1, 2, 3, 4])),
    content=(
      #|FAILED: `[1, 2] != [1, 2, 3, 4]`
      #|diff:
      #|[1, 2, +3, +4]
    ),
  )
  inspect(
    output(try? @debug.assert_eq([1, 2, 3], [1, 2])),
    content=(
      #|FAILED: `[1, 2, 3] != [1, 2]`
      #|diff:
      #|[1, 2, -3]
    ),
  )
  inspect(
    output(try? @debug.assert_eq([1, 2, 3, 4], [1, 2])),
    content=(
      #|FAILED: `[1, 2, 3, 4] != [1, 2]`
      #|diff:
      #|[1, 2, -3, -4]
    ),
  )
  inspect(
    output(try? @debug.assert_eq([1, 2, 3, 4], [1, 4])),
    content=(
      #|FAILED: `[1, 2, 3, 4] != [1, 4]`
      #|diff:
      #|[1, -2, -3, 4]
    ),
  )
  inspect(
    output(try? @debug.assert_eq([1, 4], [1, 2, 3, 4])),
    content=(
      #|FAILED: `[1, 4] != [1, 2, 3, 4]`
      #|diff:
      #|[1, +2, +3, 4]
    ),
  )
  inspect(
    output(try? @debug.assert_eq([1, 3, 4], [1, 2, 3, 4])),
    content=(
      #|FAILED: `[1, 3, 4] != [1, 2, 3, 4]`
      #|diff:
      #|[1, +2, 3, 4]
    ),
  )
  inspect(
    output(try? @debug.assert_eq([1, 2, 3, 4], [1, 3, 4])),
    content=(
      #|FAILED: `[1, 2, 3, 4] != [1, 3, 4]`
      #|diff:
      #|[1, -2, 3, 4]
    ),
  )
  inspect(
    output(try? @debug.assert_eq([2, 3], [1, 2, 3])),
    content=(
      #|FAILED: `[2, 3] != [1, 2, 3]`
      #|diff:
      #|[+1, 2, 3]
    ),
  )
  inspect(
    output(try? @debug.assert_eq([1, 2, 3], [1, 3])),
    content=(
      #|FAILED: `[1, 2, 3] != [1, 3]`
      #|diff:
      #|[1, -2, 3]
    ),
  )
}

///|
test "assert_eq for maps" {
  inspect(output(try? @debug.assert_eq({ "a": 1 }, { "a": 1 })), content="ok")
  inspect(
    output(try? @debug.assert_eq({ "a": 1, "b": 2 }, { "a": 1, "b": 3 })),
    content=(
      #|FAILED: `{ "a": 1, "b": 2 } != { "a": 1, "b": 3 }`
      #|diff:
      #|{ "a": 1, "b": -2 +3 }
    ),
  )
  inspect(
    output(try? @debug.assert_eq({ "a": 1 }, { "a": 1, "b": 2 })),
    content=(
      #|FAILED: `{ "a": 1 } != { "a": 1, "b": 2 }`
      #|diff:
      #|{ "a": 1, +"b": 2 }
    ),
  )
  inspect(
    output(try? @debug.assert_eq({ "a": 1, "b": 2 }, { "a": 1 })),
    content=(
      #|FAILED: `{ "a": 1, "b": 2 } != { "a": 1 }`
      #|diff:
      #|{ "a": 1, -"b": 2 }
    ),
  )
  inspect(
    output(try? @debug.assert_eq({ "a": 1, "b": 2 }, { "b": 2, "a": 1 })),
    content="ok",
  )
}

///|
test "assert_eq for nested structures" {
  inspect(
    output(try? @debug.assert_eq([[1, 3], [4]], [[1, 2, 3], [4]])),
    content=(
      #|FAILED: `[[1, 3], [4]] != [[1, 2, 3], [4]]`
      #|diff:
      #|[[1, +2, 3], [4]]
    ),
  )
  inspect(
    output(
      try? @debug.assert_eq({ "left": [1, 4], "right": [5, 6] }, {
        "left": [1, 2, 3, 4],
        "right": [5, 6],
      }),
    ),
    content=(
      #|FAILED: `{ "left": [1, 4], "right": [5, 6] } != { "left": [1, 2, 3, 4], "right": [5, 6] }`
      #|diff:
      #|{ "left": [1, +2, +3, 4], "right": [5, 6] }
    ),
  )
  inspect(
    output(
      try? @debug.assert_eq([{ "k": 1, "v": 1 }, { "k": 2, "v": 2 }], [
        { "k": 1, "v": 10 },
        { "k": 2, "v": 2 },
        { "k": 3, "v": 3 },
      ]),
    ),
    content=(
      #|FAILED: `[{ "k": 1, "v": 1 }, { "k": 2, "v": 2 }] != [{ "k": 1, "v": 10 }, { "k": 2, "v": 2 }, { "k": 3, "v": 3 }]`
      #|diff:
      #|[{ "k": 1, "v": -1 +10 }, { "k": 2, "v": 2 }, +{ "k": 3, "v": 3 }]
    ),
  )
  inspect(
    output(
      try? @debug.assert_eq({ "outer": [[1, 2], [3, 4]] }, {
        "outer": [[1, 2], [3, 4]],
      }),
    ),
    content="ok",
  )
}

///|
test "assert_eq for float" {
  // TODO: fix this
  inspect(
    output(try? @debug.assert_eq(1.0, 1.0 + 0.0000000000001)),
    content=(
      #|FAILED: `1 != 1.0000000000001`
      #|diff:
      #|1
    ),
  )
}

///|
test "repr" {
  let v = "3"
  inspect(
    "hello \{Debug::to_repr(v)}",
    content=(
      #|hello "3"
    ),
  )
}
