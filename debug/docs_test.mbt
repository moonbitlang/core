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
enum Tag {
  Ok(String)
}

///|
struct Example {
  answer : Int
  xs : Array[Int]
  tag : Tag
}

///|
enum List {
  Cons(Example, List)
  Nil
}

///|
fn List::debug(x : Self) -> Repr {
  match x {
    Cons(a, b) =>
      Repr::ctor("Cons", [(None, example_repr(a)), (None, List::debug(b))])
    Nil => Repr::ctor("Nil", [])
  }
}

///|
test "Nested List" {
  let rcd = { answer: 1, xs: [1, 2, 3], tag: Ok("test string result") }
  fn repeat(n) {
    if n == 0 {
      Nil
    } else {
      Cons(rcd, repeat(n - 1))
    }
  }

  @builtin.inspect(
    render(repeat(10).debug(), max_depth=100),
    content=(
      #|Cons(
      #|  {
      #|    answer: 1,
      #|    xs: [1, 2, 3],
      #|    tag: Ok("test string result"),
      #|  },
      #|  Cons(
      #|    {
      #|      answer: 1,
      #|      xs: [1, 2, 3],
      #|      tag: Ok("test string result"),
      #|    },
      #|    Cons(
      #|      {
      #|        answer: 1,
      #|        xs: [1, 2, 3],
      #|        tag: Ok("test string result"),
      #|      },
      #|      Cons(
      #|        {
      #|          answer: 1,
      #|          xs: [1, 2, 3],
      #|          tag: Ok("test string result"),
      #|        },
      #|        Cons(
      #|          {
      #|            answer: 1,
      #|            xs: [1, 2, 3],
      #|            tag: Ok("test string result"),
      #|          },
      #|          Cons(
      #|            {
      #|              answer: 1,
      #|              xs: [1, 2, 3],
      #|              tag: Ok("test string result"),
      #|            },
      #|            Cons(
      #|              {
      #|                answer: 1,
      #|                xs: [1, 2, 3],
      #|                tag: Ok("test string result"),
      #|              },
      #|              Cons(
      #|                {
      #|                  answer: 1,
      #|                  xs: [1, 2, 3],
      #|                  tag: Ok("test string result"),
      #|                },
      #|                Cons(
      #|                  {
      #|                    answer: 1,
      #|                    xs: [1, 2, 3],
      #|                    tag: Ok("test string result"),
      #|                  },
      #|                  Cons(
      #|                    {
      #|                      answer: 1,
      #|                      xs: [1, 2, 3],
      #|                      tag: Ok("test string result"),
      #|                    },
      #|                    Nil,
      #|                  ),
      #|                ),
      #|              ),
      #|            ),
      #|          ),
      #|        ),
      #|      ),
      #|    ),
      #|  ),
      #|)
    ),
  )
}

///|
fn tag_repr(tag : Tag) -> Repr {
  match tag {
    Ok(value) => Repr::ctor("Ok", [(None, Repr::string(value))])
  }
}

///|
fn example_repr(example : Example) -> Repr {
  Repr::record({
    "answer": Repr::integer(example.answer.to_string()),
    "xs": Repr::array(example.xs.map(fn(x) { Repr::integer(x.to_string()) })),
    "tag": tag_repr(example.tag),
  })
}

///|
test "docs: custom type pretty_print" {
  let sample : Example = { answer: 42, xs: [1, 2, 3], tag: Ok("done") }
  let r = example_repr(sample)
  @builtin.inspect(
    render(r),
    content=(
      #|{
      #|  answer: 42,
      #|  xs: [1, 2, 3],
      #|  tag: Ok("done"),
      #|}
    ),
  )
}

///|
struct WeirdKeys {
  snake_case_ok : Int
  with_space : Int
  k_dash_v : Int
  camel_case : Int
}

///|
fn weird_keys_repr(value : WeirdKeys) -> Repr {
  Repr::record({
    "snake_case_ok": Repr::integer(value.snake_case_ok.to_string()),
    "with space": Repr::integer(value.with_space.to_string()),
    "k-v": Repr::integer(value.k_dash_v.to_string()),
    "CamelCase": Repr::integer(value.camel_case.to_string()),
  })
}

///|
test "docs: record keys are quoted when needed" {
  let sample : WeirdKeys = {
    snake_case_ok: 1,
    with_space: 2,
    k_dash_v: 3,
    camel_case: 4,
  }
  let r = weird_keys_repr(sample)
  @builtin.inspect(
    render(r),
    content=(
      #|{
      #|  snake_case_ok: 1,
      #|  "with space": 2,
      #|  "k-v": 3,
      #|  "CamelCase": 4,
      #|}
    ),
  )
}

///|
struct Numbers {
  xs : Array[Int]
}

///|
fn numbers_repr(value : Numbers) -> Repr {
  Repr::array(value.xs.map(fn(x) { Repr::integer(x.to_string()) }))
}

///|
test "docs: threshold controls single-line vs multi-line" {
  let sample : Numbers = { xs: [1, 2, 3] }
  let r = numbers_repr(sample)
  let compact = render(r)
  let expanded = render(r)
  @builtin.inspect(compact, content="[1, 2, 3]")
  @builtin.inspect(expanded, content="[1, 2, 3]")
}

///|
test "docs: nested arrays expand with trailing commas" {
  let r = Repr::array([
    Repr::array([Repr::integer("1"), Repr::integer("2")]),
    Repr::array([Repr::integer("3")]),
  ])
  @builtin.inspect(render(r), content="[[1, 2], [3]]")
}

///|
test "docs: record containing arrays expands" {
  let r = Repr::record({
    "xs": Repr::array([
      Repr::integer("1"),
      Repr::integer("2"),
      Repr::integer("3"),
    ]),
    "ys": Repr::array([]),
  })
  @builtin.inspect(render(r), content="{ xs: [1, 2, 3], ys: [] }")
}

///|
test "docs: nested record expands" {
  let r = Repr::record({
    "outer": Repr::record({
      "a": Repr::integer("1"),
      "b": Repr::record({ "c": Repr::integer("2") }),
    }),
  })
  @builtin.inspect(render(r), content="{ outer: { a: 1, b: { c: 2 } } }")
}

///|
enum Shape {
  Point(x~ : Int, y~ : Int)
  Line(Shape, Shape)
}

///|
fn shape_repr(shape : Shape) -> Repr {
  match shape {
    Point(x~, y~) =>
      Repr::ctor("Point", [
        (Some("x"), Repr::integer(x.to_string())),
        (Some("y"), Repr::integer(y.to_string())),
      ])
    Line(a, b) =>
      Repr::ctor("Line", [(None, shape_repr(a)), (None, shape_repr(b))])
  }
}

///|
test "docs: labeled enum arguments are printed" {
  let sample : Shape = Line(Point(x=1, y=2), Point(x=3, y=4))
  let r = shape_repr(sample)
  @builtin.inspect(
    render(r),
    content=(
      #|Line(
      #|  Point(x=1, y=2),
      #|  Point(x=3, y=4),
      #|)
    ),
  )
}

///|
test "docs: enums expand with trailing commas" {
  let r = Repr::ctor("Enum", [
    (None, Repr::literal("a")),
    (None, Repr::literal("b")),
    (None, Repr::literal("c")),
  ])
  @builtin.inspect(render(r), content="Enum(a, b, c)")
}

///|
test "docs: nested enums + arrays expand consistently" {
  let r = Repr::ctor("Outer", [
    (
      None,
      Repr::ctor("Inner", [
        (None, Repr::array([Repr::integer("1"), Repr::integer("2")])),
        (None, Repr::record({ "k": Repr::integer("3") })),
      ]),
    ),
  ])
  @builtin.inspect(render(r), content="Outer(Inner([1, 2], { k: 3 }))")
}

///|
struct DictExample {
  entries : Array[(String, Int)]
}

///|
fn dict_repr(value : DictExample) -> Repr {
  Repr::map(
    value.entries.map(fn(pair) {
      let (k, v) = pair
      (Repr::string(k), Repr::integer(v.to_string()))
    }),
  )
}

///|
test "docs: dict prints as k: v pairs" {
  let sample : DictExample = { entries: [("a", 1), ("b", 2)] }
  let r = dict_repr(sample)
  @builtin.inspect(
    render(r),
    content=(
      #|{ "a": 1, "b": 2 }
    ),
  )
}

///|
test "docs: dict expands with quoted keys + trailing commas" {
  let sample : DictExample = { entries: [("a", 1), ("b", 2)] }
  let r = dict_repr(sample)
  @builtin.inspect(
    render(r),
    content=(
      #|{ "a": 1, "b": 2 }
    ),
  )
}

///|
struct OpaqueExample {
  label : String
  xs : Array[Int]
}

///|
fn opaque_repr(value : OpaqueExample) -> Repr {
  Repr::opaque_(
    value.label,
    Repr::array(value.xs.map(fn(x) { Repr::integer(x.to_string()) })),
  )
}

///|
test "docs: opaque wrappers show tag and children" {
  let sample : OpaqueExample = { label: "Vec", xs: [1, 2] }
  let r = opaque_repr(sample)
  @builtin.inspect(render(r), content="<Vec: [1, 2]>")
}
