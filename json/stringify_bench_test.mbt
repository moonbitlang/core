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
fn stringify_bench_doc(n : Int) -> Json {
  let arr : Array[Json] = Array::new(capacity=n)
  for i in 0..<n {
    arr.push({
      "id": Json::number(i.to_double()),
      "name": Json::string("user-\{i}"),
      "email": Json::string("user\{i}@example.com"),
      "bio": Json::string(
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit \{i}",
      ),
      "tags": ["alpha", "beta", "gamma"],
    })
  }
  { "users": Json::array(arr) }
}

///|
test "bench json stringify string-heavy n=1000" (it : @bench.T) {
  let doc = stringify_bench_doc(1000)
  it.bench(fn() { it.keep(doc.stringify()) })
}

///|
test "bench json stringify pretty indent=4 n=200" (it : @bench.T) {
  let doc = stringify_bench_doc(200)
  it.bench(fn() { it.keep(doc.stringify(indent=4)) })
}

///|
test "bench json stringify escape-heavy n=500" (it : @bench.T) {
  let arr : Array[Json] = Array::new(capacity=500)
  for i in 0..<500 {
    arr.push(Json::string("line1\nline2\t\"quoted\" back\\slash \{i}"))
  }
  let doc = Json::array(arr)
  it.bench(fn() { it.keep(doc.stringify()) })
}

///|
test "stringify handles unpaired surrogates like the char-by-char path" {
  // A lone leading surrogate right after an escapable character must not
  // trip the fast path or abort; it should round-trip verbatim.
  let lone = "😀".unsafe_substring(start=0, end=1)
  let malformed = "\n" + lone
  let out = Json::string(malformed).stringify()
  inspect(out.length(), content="5") // quote + \n escape (2) + lone + quote
  assert_true(out.contains(lone))
  // Malformed but escape-free strings take the bulk fast path.
  let out2 = Json::string(lone).stringify()
  inspect(out2.length(), content="3")
}
