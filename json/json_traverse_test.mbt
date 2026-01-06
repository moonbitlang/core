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
/// pseudo code is as below
// Json = Null | Bool | Num | Str | Arr[List[Json]] | Obj[Map<String, Json>]
// Return Option<Json>: None = “drop this node”
// fn prune_loc(v: Json) -> Option<Json> {
//   match v {
//     Null | Bool(_) | Num(_) | Str(_) => Some(v),

//     Arr(xs) => {
//       let ys = xs
//         .map(prune_loc)
//         .filter_map(id); // keep only Some
//       Some(Arr(ys)) // arrays are retained even if empty
//     }

//     Obj(m) => {
//       // 1) drop "loc"
//       let m1 = m.remove_key("loc");

//       // 2) prune children, dropping empties
//       let m2 = Map::new();
//       for (k, child) in m1 {
//         match prune_loc(child) {
//           Some(c2) => m2.insert(k, c2),
//           None => {} // drop this key
//         }
//       }

//       // 3) drop map if empty
//       if m2.is_empty() { None } else { Some(Obj(m2)) }
//     }
//   }
// }
fn Json::prune_loc(self : Json) -> Json? {
  match self {
    Null | True | False | Number(_, ..) | String(_) => Some(self)
    Array(arr) => {
      let pruned_arr = Array::new()
      for item in arr {
        match item.prune_loc() {
          Some(pruned_item) => pruned_arr.push(pruned_item)
          None => () // drop this item
        }
      }
      Some(Json::array(pruned_arr))
    }
    Object(obj) => {
      // 1) create a new map without "loc" key
      let new_obj = Map::new()

      // 2) iterate through all keys except "loc"
      for key, value in obj {
        if key != "loc" {
          match value.prune_loc() {
            Some(pruned_value) => new_obj.set(key, pruned_value)
            None => () // drop this key-value pair
          }
        }
      }

      // 3) return None if the object is empty, otherwise return the pruned object
      if new_obj.is_empty() {
        None
      } else {
        Some(Json::object(new_obj))
      }
    }
  }
}

///|
fn Json::prune_loc_test(self : Json) -> Json {
  match self.prune_loc() {
    Some(pruned) => pruned
    None => "Empty"
  }
}

///|
test "prune_loc - primitive values" {
  // Null, True, False, Number, String should be preserved as-is
  inspect(null.prune_loc(), content="Some(Null)")
  inspect(Json::boolean(true).prune_loc(), content="Some(True)")
  inspect(Json::boolean(false).prune_loc(), content="Some(False)")
  inspect(Json::number(42.0).prune_loc(), content="Some(Number(42))")
  inspect(Json::string("hello").prune_loc(), content="Some(String(\"hello\"))")
}

///|
test "prune_loc - arrays" {
  // Empty array
  inspect(Json::array([]).prune_loc(), content="Some(Array([]))")

  // Array with primitives
  let arr1 = Json::array([
    null,
    Json::boolean(true),
    Json::number(123.0),
    Json::string("test"),
  ])
  @json.inspect(
    arr1.prune_loc_test(),
    content=[null, true, 123, "test"], // FIXME: support null
  )

  // Nested arrays
  let arr2 : Json = [[1, 2], []]
  @json.inspect(arr2.prune_loc(), content=[[[1, 2], []]])
}

///|
test "prune_loc - objects without loc" {
  // Empty object
  inspect(Json::object(Map::new()).prune_loc(), content="None")

  // Object with no "loc" key
  let obj1 : Json = { "name": Json::string("John"), "age": Json::number(30.0) }
  @json.inspect(obj1.prune_loc(), content=[{ "name": "John", "age": 30 }])
}

///|
test "prune_loc - objects with loc key" {
  // Object with only "loc" key should be dropped
  let obj_only_loc : Json = {
    "loc": Json::object({
      "line": Json::number(10.0),
      "column": Json::number(5.0),
    }),
  }
  @json.inspect(obj_only_loc.prune_loc(), content=null) // FIXME: None -> Null

  // Object with "loc" and other keys - "loc" should be removed
  let obj_with_loc : Json = {
    "type": Json::string("function"),
    "name": Json::string("myFunc"),
    "loc": Json::object({
      "line": Json::number(10.0),
      "column": Json::number(5.0),
    }),
  }
  @json.inspect(obj_with_loc.prune_loc(), content=[
    { "type": "function", "name": "myFunc" },
  ])
}

///|
test "prune_loc - nested objects" {
  // Nested object where inner object becomes empty after pruning
  let nested1 : Json = {
    "outer": Json::object({ "loc": Json::string("should be removed") }),
    "value": Json::number(42.0),
  }
  @json.inspect(nested1.prune_loc(), content=[{ "value": 42 }])

  // Nested object where all objects are pruned
  let nested2 : Json = {
    "inner": Json::object({ "loc": Json::string("remove me") }),
  }
  @json.inspect(
    nested2.prune_loc(),
    content=null, // FIXME: None -> Null
  )
}

///|
test "prune_loc - complex mixed structure" {
  let complex : Json = {
    "ast": {
      "type": "Program",
      "body": [
        {
          "type": "FunctionDeclaration",
          "name": "test",
          "loc": { "start": 1.0, "end": 10.0 },
          "params": [],
        },
        {
          "type": "ReturnStatement",
          "argument": 42.0,
          "loc": { "start": 11.0, "end": 20.0 },
        },
      ],
      "loc": { "start": 0.0, "end": 25.0 },
    },
  }
  let result = complex.prune_loc_test()
  @json.inspect(
    result,
    content={
      "ast": {
        "type": "Program",
        "body": [
          { "type": "FunctionDeclaration", "name": "test", "params": [] },
          { "type": "ReturnStatement", "argument": 42 },
        ],
      },
    }, // FIXME: None -> Null
  )
}

///|
test "prune_loc - array with objects containing loc" {
  let arr_with_loc_objects : Json = [
    { "value": 1.0, "loc": "pos1" },
    {
      "loc": "pos2", // this object should be dropped
    },
    { "value": 3.0 },
  ]
  @json.inspect(arr_with_loc_objects.prune_loc_test(), content=[
    { "value": 1 },
    { "value": 3 },
  ])
}
