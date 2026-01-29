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
#callsite(autofill(loc))
fn capture_loc(loc~ : SourceLoc) -> SourceLoc {
  loc
}

///|
test "debug repr for core values" {
  @debug.debug_inspect(1L, content="1")
  @debug.debug_inspect(1U, content="1")
  @debug.debug_inspect((), content="()")
}

///|
test "debug repr for iterators and map" {
  let iter : Iter[Unit] = Iter::new(() => None)
  let iter_str = @debug.to_string(iter)
  assert_true(iter_str.contains("Iter"))
  let iter2 : Iter2[Unit, Unit] = Iter2::new(() => None)
  let iter2_str = @debug.to_string(iter2)
  assert_true(iter2_str.contains("Iter2"))
  let map = { "a": 1 }
  let map_str = @debug.to_string(map)
  assert_true(map_str.contains("a"))
}

///|
test "render unit and omitted repr" {
  inspect(render(Repr::unit()), content="()")
  inspect(render(Repr::omitted()), content="...")
}

///|
test "render empty containers" {
  inspect(render(Repr::array([])), content="[]")
  inspect(render(Repr::record({})), content="{}")
}

///|
test "repr traverse rewrites integers" {
  let repr = Repr::tuple([Repr::integer("1"), Repr::integer("2")])
  let rewritten = repr.traverse(_ => Repr::omitted())
  inspect(render(rewritten), content="...")
}

///|
test "repr record with empty key" {
  let repr = Repr::record({ "": Repr::integer("1") })
  let rendered = render(repr)
  assert_true(rendered.contains("\"\""))
}

///|
test "repr tuple constructor prints as tuple" {
  let repr = Repr::ctor("Tuple", [
    (None, Repr::integer("1")),
    (None, Repr::integer("2")),
  ])
  inspect(render(repr), content="(1, 2)")
}

///|
test "render prunes depth while keeping labels" {
  let items = Array::makei(20, i => Repr::integer((i + 10).to_string()))
  let repr = Repr::record({ "field": Repr::array(items) })
  let rendered = render(repr, max_depth=1)
  assert_true(rendered.contains("field"))
  assert_true(rendered.contains("..."))
}

///|
test "render map entry with multiline value" {
  let items = Array::makei(20, i => Repr::integer((i + 10).to_string()))
  let repr = Repr::map([(Repr::string("key"), Repr::array(items))])
  let rendered = render(repr)
  assert_true(rendered.contains(":"))
  assert_true(rendered.contains("\n"))
}

///|
test "render labeled enum arg with multiline value" {
  let items = Array::makei(20, i => Repr::integer((i + 10).to_string()))
  let repr = Repr::ctor("Wrap", [(Some("value"), Repr::array(items))])
  let rendered = render(repr)
  assert_true(rendered.contains("value="))
  assert_true(rendered.contains("\n"))
}

///|
test "debug inspect error path" {
  let result = try? @debug.debug_inspect(1)
  let is_err = match result {
    Ok(_) => false
    Err(_) => true
  }
  inspect(is_err, content="true")
}

///|
test "debug source loc repr" {
  let loc = capture_loc()
  let repr = @debug.to_string(loc)
  assert_true(repr.contains("SourceLoc"))
}

///|
test "render enum with empty literal arg" {
  let repr = Repr::ctor("Wrap", [(None, Repr::literal(""))])
  inspect(render(repr), content="Wrap()")
}

///|
test "render enum skips empty literal arg among others" {
  let repr = Repr::ctor("Wrap", [
    (None, Repr::literal("")),
    (None, Repr::integer("1")),
  ])
  let rendered = render(repr)
  assert_true(rendered.contains("Wrap"))
  assert_true(rendered.contains("1"))
}

///|
test "render array with empty literal item" {
  let repr = Repr::array([Repr::literal(""), Repr::integer("1")])
  let rendered = render(repr)
  assert_true(rendered.contains("1"))
}
