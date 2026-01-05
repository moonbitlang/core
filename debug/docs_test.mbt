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

  inspect(
    render(repeat(10).debug(), max_depth=100, compact_threshold=100),
    content=(
      #|Cons(
      #|  { answer: 1, xs: [1, 2, 3], tag: Ok("test string result") },
      #|  Cons(
      #|    { answer: 1, xs: [1, 2, 3], tag: Ok("test string result") },
      #|    Cons(
      #|      { answer: 1, xs: [1, 2, 3], tag: Ok("test string result") },
      #|      Cons(
      #|        { answer: 1, xs: [1, 2, 3], tag: Ok("test string result") },
      #|        Cons(
      #|          { answer: 1, xs: [1, 2, 3], tag: Ok("test string result") },
      #|          Cons(
      #|            { answer: 1, xs: [1, 2, 3], tag: Ok("test string result") },
      #|            Cons(
      #|              { answer: 1, xs: [1, 2, 3], tag: Ok("test string result") },
      #|              Cons(
      #|                { answer: 1, xs: [1, 2, 3], tag: Ok("test string result") },
      #|                Cons(
      #|                  { answer: 1, xs: [1, 2, 3], tag: Ok("test string result") },
      #|                  Cons({ answer: 1, xs: [1, 2, 3], tag: Ok("test string result") }, Nil),
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
  inspect(
    render(repeat(10).debug(), max_depth=100, compact_threshold=10),
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
    "answer": Repr::int(example.answer),
    "xs": Repr::array(example.xs.map(fn(x) { Repr::int(x) })),
    "tag": tag_repr(example.tag),
  })
}

///|
test "docs: custom type pretty_print" {
  let sample : Example = { answer: 42, xs: [1, 2, 3], tag: Ok("done") }
  let r = example_repr(sample)
  inspect(
    render(r, compact_threshold=100),
    content=(
      #|{ answer: 42, xs: [1, 2, 3], tag: Ok("done") }
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
    "snake_case_ok": Repr::int(value.snake_case_ok),
    "with space": Repr::int(value.with_space),
    "k-v": Repr::int(value.k_dash_v),
    "CamelCase": Repr::int(value.camel_case),
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
  inspect(
    render(r, compact_threshold=100),
    content=(
      #|{ snake_case_ok: 1, "with space": 2, "k-v": 3, "CamelCase": 4 }
    ),
  )
}

///|
struct Numbers {
  xs : Array[Int]
}

///|
fn numbers_repr(value : Numbers) -> Repr {
  Repr::array(value.xs.map(fn(x) { Repr::int(x) }))
}

///|
test "docs: threshold controls single-line vs multi-line" {
  let sample : Numbers = { xs: [1, 2, 3] }
  let r = numbers_repr(sample)
  let compact = render(r)
  let expanded = render(r, compact_threshold=0)
  inspect(compact, content="[1, 2, 3]")
  inspect(
    expanded,
    content=(
      #|[
      #|  1,
      #|  2,
      #|  3,
      #|]
    ),
  )
}

///|
test "docs: nested arrays expand with trailing commas" {
  let r = Repr::array([
    Repr::array([Repr::int(1), Repr::int(2)]),
    Repr::array([Repr::int(3)]),
  ])
  inspect(
    render(r, compact_threshold=0),
    content=(
      #|[
      #|  [
      #|    1,
      #|    2,
      #|  ],
      #|  [3],
      #|]
    ),
  )
}

///|
test "docs: record containing arrays expands" {
  let r = Repr::record({
    "xs": Repr::array([Repr::int(1), Repr::int(2), Repr::int(3)]),
    "ys": Repr::array([]),
  })
  inspect(
    render(r, compact_threshold=0),
    content=(
      #|{
      #|  xs: [
      #|    1,
      #|    2,
      #|    3,
      #|  ],
      #|  ys: [],
      #|}
    ),
  )
}

///|
test "docs: nested record expands" {
  let r = Repr::record({
    "outer": Repr::record({
      "a": Repr::int(1),
      "b": Repr::record({ "c": Repr::int(2) }),
    }),
  })
  inspect(
    render(r, compact_threshold=0),
    content=(
      #|{
      #|  outer: {
      #|    a: 1,
      #|    b: { c: 2 },
      #|  },
      #|}
    ),
  )
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
      Repr::ctor("Point", [(Some("x"), Repr::int(x)), (Some("y"), Repr::int(y))])
    Line(a, b) =>
      Repr::ctor("Line", [(None, shape_repr(a)), (None, shape_repr(b))])
  }
}

///|
test "docs: labeled enum arguments are printed" {
  let sample : Shape = Line(Point(x=1, y=2), Point(x=3, y=4))
  let r = shape_repr(sample)
  inspect(
    render(r, compact_threshold=100),
    content="Line(Point(x=1, y=2), Point(x=3, y=4))",
  )
}

///|
test "docs: enums expand with trailing commas" {
  let r = Repr::ctor("Enum", [
    (None, Repr::literal("a")),
    (None, Repr::literal("b")),
    (None, Repr::literal("c")),
  ])
  inspect(
    render(r, compact_threshold=0),
    content=(
      #|Enum(
      #|  a,
      #|  b,
      #|  c,
      #|)
    ),
  )
}

///|
test "docs: nested enums + arrays expand consistently" {
  let r = Repr::ctor("Outer", [
    (
      None,
      Repr::ctor("Inner", [
        (None, Repr::array([Repr::int(1), Repr::int(2)])),
        (None, Repr::record({ "k": Repr::int(3) })),
      ]),
    ),
  ])
  inspect(
    render(r, compact_threshold=0),
    content=(
      #|Outer(
      #|  Inner(
      #|    [
      #|      1,
      #|      2,
      #|    ],
      #|    { k: 3 },
      #|  ),
      #|)
    ),
  )
}

///|
struct DictExample {
  entries : Array[(String, Int)]
}

///|
fn dict_repr(value : DictExample) -> Repr {
  Repr::dict(
    value.entries.map(fn(pair) {
      let (k, v) = pair
      (Repr::string(k), Repr::int(v))
    }),
  )
}

///|
test "docs: dict prints as k: v pairs" {
  let sample : DictExample = { entries: [("a", 1), ("b", 2)] }
  let r = dict_repr(sample)
  inspect(
    render(r, compact_threshold=100),
    content=(
      #|{ "a": 1, "b": 2 }
    ),
  )
}

///|
test "docs: dict expands with quoted keys + trailing commas" {
  let sample : DictExample = { entries: [("a", 1), ("b", 2)] }
  let r = dict_repr(sample)
  inspect(
    render(r, compact_threshold=0),
    content=(
      #|{
      #|  "a": 1,
      #|  "b": 2,
      #|}
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
  Repr::opaque_(value.label, [Repr::array(value.xs.map(fn(x) { Repr::int(x) }))])
}

///|
test "docs: opaque wrappers show tag and children" {
  let sample : OpaqueExample = { label: "Vec", xs: [1, 2] }
  let r = opaque_repr(sample)
  inspect(render(r, compact_threshold=100), content="<Vec: [1, 2]>")
}
