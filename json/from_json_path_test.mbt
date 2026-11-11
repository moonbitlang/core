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
/// Keeps an independent snapshot of the context it was decoded at.
priv struct At(@json.DecodeContext)

///|
impl @json.FromJson for At with fn from_json(_json, path) {
  At(path.copy())
}

///|
/// Decodes an `Int`, keeping the error instead of raising it.
priv struct Lenient(@json.JsonDecodeError?)

///|
impl @json.FromJson for Lenient with fn from_json(json, path) {
  let _ : Int32 = @json.FromJson::from_json(json, path) catch {
    err => return Lenient(Some(err))
  }
  Lenient(None)
}

///|
fn lenient_paths(values : ArrayView[Lenient]) -> Array[String] {
  values.map(v => {
    match v.0 {
      Some(JsonDecodeError((path, _))) => path.to_string()
      None => "ok"
    }
  })
}

///|
test "FromJson for Array preserves copied contexts and caught errors" {
  let json = @json.parse("[\"a\", \"b\", \"c\"]")
  let kept : Array[Lenient] = @json.from_json(json)
  debug_inspect(
    lenient_paths(kept),
    content=(
      #|["/0", "/1", "/2"]
    ),
  )
  let at : Array[At] = @json.from_json(json)
  debug_inspect(
    at.map(a => a.0.to_string()),
    content=(
      #|["/0", "/1", "/2"]
    ),
  )
}

///|
test "FromJson for ArrayView and FixedArray preserve copied contexts and caught errors" {
  let json = @json.parse("[\"a\", 1, \"c\"]")
  let view : ArrayView[Lenient] = @json.from_json(json)
  debug_inspect(
    lenient_paths(view),
    content=(
      #|["/0", "ok", "/2"]
    ),
  )
  let fixed : FixedArray[Lenient] = @json.from_json(json)
  debug_inspect(
    lenient_paths([ for x in fixed => x ]),
    content=(
      #|["/0", "ok", "/2"]
    ),
  )
  let at : FixedArray[At] = @json.from_json(json)
  debug_inspect(
    [
      for a in at => a.0.to_string()
    ],
    content=(
      #|["/0", "/1", "/2"]
    ),
  )
}

///|
test "FromJson for Map preserves copied contexts and caught errors" {
  let json = @json.parse("{\"x\": \"a\", \"y\": \"b\"}")
  let kept : Map[String, Lenient] = @json.from_json(json)
  let paths = kept.to_array().map(kv => (kv.0, lenient_paths([kv.1])[0]))
  debug_inspect(
    paths,
    content=(
      #|[("x", "/x"), ("y", "/y")]
    ),
  )
  let at : Map[String, At] = @json.from_json(json)
  let paths = at.to_array().map(kv => (kv.0, kv.1.0.to_string()))
  debug_inspect(
    paths,
    content=(
      #|[("x", "/x"), ("y", "/y")]
    ),
  )
}

///|
test "kept paths stay valid under a nested decode" {
  let json = @json.parse("{\"rows\": [[\"a\", 1], [2, \"b\"]]}")
  let kept : Map[String, Array[Array[Lenient]]] = @json.from_json(json)
  let rows = kept.get("rows").unwrap()
  debug_inspect(
    rows.map(row => lenient_paths(row)),
    content=(
      #|[["/rows/0/0", "ok"], ["ok", "/rows/1/1"]]
    ),
  )
}

///|
// Exercise the compatibility alias in both type and method positions.
priv struct SavedChild(@json.JsonPath, @json.JsonDecodeError)

///|
impl @json.FromJson for SavedChild with fn from_json(_json, context) {
  let child = context.add_key("extra~/").add_index(7)
  SavedChild(@json.JsonPath::copy(child), child.error("custom error"))
}

///|
test "copied child contexts and custom errors snapshot all ancestors" {
  let saved : Array[Map[String, Array[SavedChild]]] = @json.from_json([
    { "a~/": [0, 1], "b": [2] },
    { "c": [3] },
  ])
  let paths = []
  let errors = []
  for object in saved {
    for _, children in object {
      for child in children {
        paths.push(child.0.to_string())
        let JsonDecodeError((context, message)) = child.1
        errors.push((context.to_string(), message))
      }
    }
  }
  debug_inspect(
    paths,
    content=(
      #|[
      #|  "/0/a~0~1/0/extra~0~1/7",
      #|  "/0/a~0~1/1/extra~0~1/7",
      #|  "/0/b/0/extra~0~1/7",
      #|  "/1/c/0/extra~0~1/7",
      #|]
    ),
  )
  debug_inspect(
    errors,
    content=(
      #|[
      #|  ("/0/a~0~1/0/extra~0~1/7", "custom error"),
      #|  ("/0/a~0~1/1/extra~0~1/7", "custom error"),
      #|  ("/0/b/0/extra~0~1/7", "custom error"),
      #|  ("/1/c/0/extra~0~1/7", "custom error"),
      #|]
    ),
  )
}
