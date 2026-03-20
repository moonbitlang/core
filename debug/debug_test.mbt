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
      #|[1, -2 +222, 3]
    ),
  )
  inspect(
    output(try? @debug.assert_eq((true, "string", 123), (true, "s", 1))),
    content=(
      #|FAILED: `(true, "string", 123) != (true, "s", 1)`
      #|diff:
      #|(true, -"string" +"s", -123 +1)
    ),
  )
  inspect(
    output(try? @debug.assert_eq({ "k1": 1.0, "k2": 2 }, { "k1": 2, "k3": 5 })),
    content=(
      #|FAILED: `{ "k1": 1, "k2": 2 } != { "k1": 2, "k3": 5 }`
      #|diff:
      #|{ "k1": -1 +2, -"k2": 2 +"k3": 5 }
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
      #|Some(-1 +2)
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
      #|[1, -2 +4, -3, -4]
    ),
  )
  inspect(
    output(try? @debug.assert_eq([1, 4], [1, 2, 3, 4])),
    content=(
      #|FAILED: `[1, 4] != [1, 2, 3, 4]`
      #|diff:
      #|[1, -4 +2, +3, +4]
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
