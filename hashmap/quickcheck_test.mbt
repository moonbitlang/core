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
fn model_set(model : Array[(Int32, Int32)], key : Int32, value : Int32) -> Unit {
  for i, entry in model {
    if entry.0 == key {
      model[i] = (key, value)
      return
    }
  }
  model.push((key, value))
}

///|
fn model_remove(model : Array[(Int32, Int32)], key : Int32) -> Unit {
  for i, entry in model {
    if entry.0 == key {
      model.remove(i) |> ignore
      return
    }
  }
}

///|
fn agrees_with_model(
  map : @hashmap.HashMap[Int32, Int32],
  model : Array[(Int32, Int32)],
) -> Bool {
  if map.length() != model.length() {
    return false
  }
  for entry in model {
    if map.get(entry.0) != Some(entry.1) {
      return false
    }
  }
  let actual = map.to_array()
  actual.sort()
  let expected = model.copy()
  expected.sort()
  actual == expected
}

///|
test "quickcheck: mutations agree with an association-array model" {
  @quickcheck.check((ops : Array[(Int32, Int32)]) => {
    let map : @hashmap.HashMap[Int32, Int32] = HashMap([])
    let model : Array[(Int32, Int32)] = []
    for op in ops {
      // A small key space deliberately generates replacements and removals.
      let key = op.0 % 31
      if op.1 % 4 == 0 {
        map.remove(key)
        model_remove(model, key)
      } else {
        map.set(key, op.1)
        model_set(model, key, op.1)
      }
      if !agrees_with_model(map, model) {
        return false
      }
    }
    true
  })
}
