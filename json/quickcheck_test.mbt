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

// Property-based tests for the json package.
//
// The tests are built around a hand-written `Generator[Json]` that produces
// arbitrarily nested documents with adversarial numbers (bit-pattern doubles
// covering subnormals, -0.0, and extreme magnitudes) and arbitrary Unicode
// strings, plus a structural shrinker so counterexamples minimize to small
// documents.

///|
/// Doubles drawn from uniformly random bit patterns, so subnormals, -0.0,
/// and extreme magnitudes all appear. Non-finite patterns fall back to a
/// finite value since JSON cannot represent NaN or infinities as numbers.
priv struct FiniteDouble(Double) derive(@debug.Debug)

///|
impl @quickcheck.Arbitrary for FiniteDouble with fn arbitrary(_size, state) {
  let bits = state.next_int64()
  let value = bits.reinterpret_as_double()
  if value.is_nan() || value.is_inf() {
    FiniteDouble(bits.to_double())
  } else {
    FiniteDouble(value)
  }
}

///|
impl @shrink.Shrink for FiniteDouble with fn shrink(self) {
  @shrink.Shrink::shrink(self.0).map(value => FiniteDouble(value))
}

///|
/// Numbers mix small integers (the common case in real documents) with
/// adversarial bit-pattern doubles.
fn number_gen() -> @quickcheck.Generator[Json] {
  let small_int = @quickcheck.int_range(-1000, 1001).map(i => {
    Json::number(i.to_double())
  })
  let finite_double : @quickcheck.Generator[FiniteDouble] = @quickcheck.spawn()
  let bit_pattern = finite_double.map(d => Json::number(d.0))
  @quickcheck.frequency([(2, small_int), (1, bit_pattern)])
}

///|
fn leaf_gen() -> @quickcheck.Generator[Json] {
  let bool_gen : @quickcheck.Generator[Bool] = @quickcheck.spawn()
  let string_gen : @quickcheck.Generator[String] = @quickcheck.spawn()
  @quickcheck.frequency([
    (1, @quickcheck.pure(Json::null())),
    (1, bool_gen.map(b => Json::boolean(b))),
    (2, number_gen()),
    (2, string_gen.map(s => Json::string(s))),
  ])
}

///|
fn json_gen(depth : Int) -> @quickcheck.Generator[Json] {
  if depth <= 0 {
    return leaf_gen()
  }
  let element = json_gen(depth - 1)
  let string_gen : @quickcheck.Generator[String] = @quickcheck.spawn()
  let array = @quickcheck.int_range(0, 5)
    .flat_map(n => element.array_with_size(n))
    .map(xs => Json::array(xs))
  let object = @quickcheck.int_range(0, 5)
    .flat_map(n => string_gen.zip(element).array_with_size(n))
    .map(pairs => {
      let members : Map[String, Json] = Map([])
      for pair in pairs {
        let (key, value) = pair
        members[key] = value
      }
      Json::object(members)
    })
  @quickcheck.frequency([(2, leaf_gen()), (1, array), (1, object)])
}

///|
/// Wrapper giving `Json` the `Arbitrary`/`Shrink`/`Debug` instances the
/// quickcheck driver needs.
priv struct ArbJson(Json) derive(@debug.Debug)

///|
impl @quickcheck.Arbitrary for ArbJson with fn arbitrary(size, state) {
  // Depth grows with the driver's size so early cases stay tiny and later
  // cases nest several levels deep.
  let depth = size / 20
  let depth = if depth > 4 { 4 } else { depth }
  ArbJson(json_gen(depth).run(size, state))
}

///|
/// Structural shrinker: a container shrinks to null, to any of its children,
/// to itself with one child removed, and to itself with one child shrunk, so
/// a failing document minimizes to the smallest structure that still fails.
fn shrink_json(json : Json) -> Array[Json] {
  match json {
    Null => []
    True | False => [Json::null()]
    Number(n, ..) =>
      if n == 0.0 {
        [Json::null()]
      } else {
        [Json::null(), Json::number(0.0)]
      }
    String(s) => {
      let out = [Json::null()]
      for smaller in @shrink.Shrink::shrink(s) {
        out.push(Json::string(smaller))
      }
      out
    }
    Array(elements) => {
      let out = [Json::null()]
      for element in elements {
        out.push(element)
      }
      for i in 0..<elements.length() {
        let dropped = elements.copy()
        ignore(dropped.remove(i))
        out.push(Json::array(dropped))
      }
      for i in 0..<elements.length() {
        for smaller in shrink_json(elements[i]) {
          let replaced = elements.copy()
          replaced[i] = smaller
          out.push(Json::array(replaced))
        }
      }
      out
    }
    Object(members) => {
      let out = [Json::null()]
      let pairs = members.to_array()
      for pair in pairs {
        out.push(pair.1)
      }
      for i in 0..<pairs.length() {
        let smaller_members : Map[String, Json] = Map([])
        for j, pair in pairs {
          if i != j {
            smaller_members[pair.0] = pair.1
          }
        }
        out.push(Json::object(smaller_members))
      }
      for i in 0..<pairs.length() {
        for smaller in shrink_json(pairs[i].1) {
          let replaced : Map[String, Json] = Map([])
          for j, pair in pairs {
            replaced[pair.0] = if i == j { smaller } else { pair.1 }
          }
          out.push(Json::object(replaced))
        }
      }
      out
    }
  }
}

///|
impl @shrink.Shrink for ArbJson with fn shrink(self) {
  shrink_json(self.0).iter().map(json => ArbJson(json))
}

///|
fn json_depth(json : Json) -> Int {
  match json {
    Array(elements) => {
      let mut deepest = 0
      for element in elements {
        let d = json_depth(element)
        if d > deepest {
          deepest = d
        }
      }
      deepest + 1
    }
    Object(members) => {
      let mut deepest = 0
      for _, value in members {
        let d = json_depth(value)
        if d > deepest {
          deepest = d
        }
      }
      deepest + 1
    }
    _ => 0
  }
}

///|
fn json_node_count(json : Json) -> Int {
  match json {
    Array(elements) => {
      let mut count = 1
      for element in elements {
        count += json_node_count(element)
      }
      count
    }
    Object(members) => {
      let mut count = 1
      for _, value in members {
        count += json_node_count(value)
      }
      count
    }
    _ => 1
  }
}

///|
fn root_kind(json : Json) -> String {
  match json {
    Null => "null"
    True | False => "bool"
    Number(_, ..) => "number"
    String(_) => "string"
    Array(_) => "array"
    Object(_) => "object"
  }
}

///|
fn parse_succeeds(text : String) -> Bool {
  try {
    ignore(@json.parse(text))
    true
  } catch {
    _ => false
  }
}

///|
/// Maps an arbitrary Int into `0..<modulus` without discarding cases.
fn wrap_index(value : Int, modulus : Int) -> Int {
  let r = value % modulus
  if r < 0 {
    r + modulus
  } else {
    r
  }
}

///|
test "stringify/parse roundtrip on arbitrary Json" {
  @quickcheck.check((json : ArbJson) => {
    let original = json.0
    let text = original.stringify()
    @json.valid(text) && @json.parse(text) == original
  })
}

///|
test "roundtrip is unaffected by formatting options" {
  @quickcheck.check((input : (ArbJson, Int, Bool)) => {
    let (json, raw_indent, escape_slash) = input
    let original = json.0
    let text = original.stringify(
      indent=wrap_index(raw_indent, 9),
      escape_slash~,
    )
    @json.parse(text) == original
  })
}

///|
/// Every finite double survives printing and re-parsing bit-exactly,
/// including subnormals, -0.0, and integers beyond 2^53 (which parse to the
/// correctly rounded value with the source text preserved in `repr`).
test "every finite double roundtrips through JSON text" {
  @quickcheck.check((d : FiniteDouble) => {
    let number = Json::number(d.0)
    let back = @json.parse(number.stringify())
    back == number && back.stringify() == number.stringify()
  })
}

///|
test "valid agrees with parse on arbitrary strings" {
  @quickcheck.check((text : String) => parse_succeeds(text) == @json.valid(text))
}

///|
/// Mutates well-formed JSON text (a random insertion, and a random
/// truncation) and checks the parser stays total and consistent with
/// `valid` on near-valid input.
test "parse stays total on mutated JSON text" {
  @quickcheck.check((input : (ArbJson, Int, Char)) => {
    let (json, position, extra) = input
    let chars = json.0.stringify().to_array()
    let cut = wrap_index(position, chars.length() + 1)
    let truncated = String::from_array(chars[:cut])
    guard parse_succeeds(truncated) == @json.valid(truncated) else {
      return false
    }
    chars.insert(cut, extra)
    let mutated = String::from_array(chars)
    parse_succeeds(mutated) == @json.valid(mutated)
  })
}

///|
/// `max_nesting_depth` is (deprecated) plumbing used only to exercise the
/// depth-limit guard cheaply at randomized boundaries.
#warnings("-deprecated")
fn parse_outcome_with_limit(text : String, limit : Int) -> String {
  try {
    ignore(@json.parse(text, max_nesting_depth=limit))
    "parsed"
  } catch {
    DepthLimitExceeded => "depth limit"
    _ => "other error"
  }
}

///|
test "max_nesting_depth accepts exactly the documented depth" {
  @quickcheck.check((input : (Int, Int, Bool)) => {
    let (raw_depth, raw_delta, use_objects) = input
    let depth = wrap_index(raw_depth, 40) + 1
    // Concentrate the limit within +-2 of the actual depth so every run
    // probes the exact boundary instead of far-away values.
    let limit = depth + wrap_index(raw_delta, 5) - 2
    let text = if use_objects {
      "{\"k\":".repeat(depth) + "0" + "}".repeat(depth)
    } else {
      "[".repeat(depth) + "0" + "]".repeat(depth)
    }
    parse_outcome_with_limit(text, limit) ==
    (if limit >= depth { "parsed" } else { "depth limit" })
  })
}

///|
test "ToJson/FromJson roundtrips across the type zoo" {
  @quickcheck.check((x : Int) => {
    let back : Int = @json.from_json(@json.to_json(x))
    back == x
  })
  @quickcheck.check((x : UInt) => {
    let back : UInt = @json.from_json(@json.to_json(x))
    back == x
  })
  @quickcheck.check((x : Int64) => {
    let back : Int64 = @json.from_json(@json.to_json(x))
    back == x
  })
  @quickcheck.check((x : UInt64) => {
    let back : UInt64 = @json.from_json(@json.to_json(x))
    back == x
  })
  @quickcheck.check((x : FiniteDouble) => {
    let back : Double = @json.from_json(@json.to_json(x.0))
    back == x.0
  })
  @quickcheck.check((x : String) => {
    let back : String = @json.from_json(@json.to_json(x))
    back == x
  })
  @quickcheck.check((x : Char) => {
    let back : Char = @json.from_json(@json.to_json(x))
    back == x
  })
  @quickcheck.check((x : Bytes) => {
    let back : Bytes = @json.from_json(@json.to_json(x))
    back == x
  })
  // `None` maps to null while `Some(None)` maps to [null]; the roundtrip
  // must keep the two distinct.
  @quickcheck.check((x : Int??) => {
    let back : Int?? = @json.from_json(@json.to_json(x))
    back == x
  })
  @quickcheck.check((x : Result[Int, String]) => {
    let back : Result[Int, String] = @json.from_json(@json.to_json(x))
    back == x
  })
  @quickcheck.check((x : Array[Array[Int]]) => {
    let back : Array[Array[Int]] = @json.from_json(@json.to_json(x))
    back == x
  })
  @quickcheck.check((x : (Int, String, Bool)) => {
    let back : (Int, String, Bool) = @json.from_json(@json.to_json(x))
    back == x
  })
  @quickcheck.check((pairs : Array[(String, Int)]) => {
    let members : Map[String, Int] = Map([])
    for pair in pairs {
      members[pair.0] = pair.1
    }
    let back : Map[String, Int] = @json.from_json(@json.to_json(members))
    back == members
  })
  @quickcheck.check((json : ArbJson) => {
    let back : Json = @json.from_json(json.0)
    back == json.0
  })
}

///|
/// Pins the shape of the generated corpus using quickcheck observations, so
/// a future generator change that stops producing nested or large documents
/// shows up as a snapshot diff instead of silently weakening every property
/// above.
test "generated Json distribution stays healthy" {
  let report = @quickcheck.report(
    (json : ArbJson) => @json.parse(json.0.stringify()) == json.0,
    observe=json => {
      let j = json.0
      [
        @quickcheck.label(root_kind(j)),
        @quickcheck.classify(json_depth(j) >= 2, "nests >= 2 levels"),
        @quickcheck.classify(json_node_count(j) >= 10, "has >= 10 nodes"),
      ]
    },
    count=200,
  )
  debug_inspect(
    report,
    content=(
      #|Passed(
      #|  tests=200,
      #|  observations={
      #|    labels: {
      #|      <List: ["string"]>: 44,
      #|      <List: ["bool"]>: 21,
      #|      <List: ["number"]>: 39,
      #|      <List: ["null"]>: 30,
      #|      <List: ["array"]>: 38,
      #|      <List: ["object"]>: 28,
      #|    },
      #|    classes: { "nests >= 2 levels": 35, "has >= 10 nodes": 9 },
      #|  },
      #|)
    ),
  )
}
