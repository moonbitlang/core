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
/// The specification of a JSON number's rendering is exactly the shortest
/// round-tripping decimal form of the double, i.e. `Double::to_string`. The
/// integral fast path in `stringify` must be indistinguishable from it. This
/// oracle is the definition, not a copy of the implementation.
fn check_number(d : Double) -> Unit raise {
  let got = Json::number(d).stringify()
  assert_eq(got, d.to_string())
}

///|
/// Exhaustive over a dense band around zero, where the fast path is taken.
test "stringify number matches Double::to_string exhaustively near zero" {
  for i in -2000..<=2000 {
    check_number(i.to_double())
  }
}

///|
/// The boundaries of the fast path's admissible range, on both sides. A
/// mistake in the range guard shows up here and nowhere else.
test "stringify number matches Double::to_string at fast-path boundaries" {
  let boundaries : Array[Double] = [
    0.0, -0.0, 1.0, -1.0, 2147483646.0, 2147483647.0, // Int::max_value and just below
     2147483648.0, 2147483649.0, // just above: must fall back to Ryu
     -2147483647.0, -2147483648.0, // Int::min_value
     -2147483649.0, -2147483650.0, // just below: must fall back
     4294967296.0, 9007199254740992.0, // 2^32, 2^53
     -9007199254740992.0, 1.0e15, 1.0e16, 1.0e17, -1.0e15,
  ]
  for d in boundaries {
    check_number(d)
  }
}

///|
/// Non-integral values must never take the integer path, including ones whose
/// truncation is in range.
test "stringify number matches Double::to_string for non-integral values" {
  let values : Array[Double] = [
    0.5, -0.5, 1.5, -1.5, 3.14159, -3.14159, 0.1, 0.2, 1.0e-7, -1.0e-7, 2147483646.5,
    -2147483647.5, 1.7976931348623157e308, -1.7976931348623157e308, 5.0e-324, 2.2250738585072014e-308,
  ]
  for d in values {
    check_number(d)
  }
}

///|
/// Nested inside a document, so the fast path is exercised through the real
/// stringify loop rather than only at the root.
test "stringify number fast path agrees inside documents" {
  let arr : Array[Json] = []
  for i in -50..<=50 {
    arr.push(Json::number(i.to_double()))
    arr.push(Json::number(i.to_double() + 0.25))
  }
  let doc : Json = { "values": arr.to_json() }
  let out = doc.stringify()
  let expected = StringBuilder(size_hint=0)
  expected.write_string("{\"values\":[")
  for i in -50..<=50 {
    if i > -50 {
      expected.write_string(",")
    }
    expected.write_string(i.to_double().to_string())
    expected.write_string(",")
    expected.write_string((i.to_double() + 0.25).to_string())
  }
  expected.write_string("]}")
  assert_eq(out, expected.to_string())
}
