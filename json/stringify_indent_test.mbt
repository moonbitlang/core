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
/// Counts the leading spaces of a line. The oracle below compares this against
/// `indent * level` computed straight from the definition, rather than against
/// anything the implementation produces, so it cannot reproduce a bug in the
/// cached version.
fn leading_spaces(line : StringView) -> Int {
  let mut n = 0
  for c in line {
    if c != ' ' {
      break
    }
    n += 1
  }
  n
}

///|
/// `[[[...[0]...]]]` nested `depth` levels deep.
fn nest(depth : Int) -> Json {
  let mut value : Json = Json::number(0.0)
  for _ in 0..<depth {
    value = Json::array([value])
  }
  value
}

///|
/// Exhaustive over the interesting domain: every indent width 0..=6 crossed
/// with every nesting depth 0..=12. This spans both sides of the 8-space
/// lookup cutoff that the pre-cache implementation special-cased, which the
/// existing snapshots (indent 1/2/4/5/7 at shallow depth) never reach.
test "stringify indentation matches the definition at every depth and width" {
  for indent in 0..<=6 {
    for depth in 0..<=12 {
      let out = nest(depth).stringify(indent~)
      if indent == 0 {
        // Compact: no newlines at all.
        assert_eq(out.contains("\n"), false)
        continue
      }
      let lines = out.split("\n").collect()
      // depth opening brackets + the scalar + depth closing brackets
      assert_eq(lines.length(), depth * 2 + 1)
      for i in 0..<lines.length() {
        // Level rises to `depth` on the scalar line, then falls back.
        let level = if i <= depth { i } else { depth * 2 - i }
        let want = indent * level
        assert_eq(leading_spaces(lines[i]), want)
      }
    }
  }
}

///|
/// The cache is filled lazily as depth increases, so a document that revisits
/// shallower levels after going deep must still emit the right width. Guards
/// against an off-by-one or a stale entry in the incremental fill.
test "stringify indentation is stable when depth decreases again" {
  let value : Json = {
    "deep": [[[[[[Json::number(1.0)]]]]]],
    "shallow": Json::number(2.0),
  }
  let out = value.stringify(indent=3)
  for line in out.split("\n") {
    assert_eq(leading_spaces(line) % 3, 0)
  }
  inspect(out.contains("\n                  "), content="true")
}

///|
/// A non-positive `indent` selects the compact path. It must not reach
/// `String::repeat`, which aborts on a negative count, and must not allocate an
/// indentation unit that is never used.
test "stringify with non-positive indent is compact and never aborts" {
  let doc : Json = { "a": [Json::number(1.0), { "b": Json::number(2.0) }] }
  let compact = doc.stringify()
  assert_eq(doc.stringify(indent=0), compact)
  assert_eq(doc.stringify(indent=-1), compact)
  assert_eq(doc.stringify(indent=-1000000000), compact)
}

///|
/// A document that emits no indentation must not pay for the indentation unit,
/// however large `indent` is. This would abort or exhaust memory if the unit
/// were built eagerly per call.
test "stringify of a scalar ignores a huge indent" {
  inspect(Json::number(1.0).stringify(indent=1000000000), content="1")
  inspect((Json::array([]) : Json).stringify(indent=1000000000), content="[]")
}
