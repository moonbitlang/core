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
/// Try to get this element as a Null
#deprecated("Suggestion: `if json is Null { Some(()) } else { None }`")
pub fn Json::as_null(self : Json) -> Unit? {
  guard self is Null else { return None }
  Some(())
}

///|
/// Try to get this element as a Boolean
#deprecated("Suggestion: `if json is True { Some(true) } else if json is False { Some(false) } else { None }`")
pub fn Json::as_bool(self : Json) -> Bool? {
  match self {
    True => Some(true)
    False => Some(false)
    _ => None
  }
}

///|
/// Try to get this element as a Number
#deprecated("Suggestion: `if json is Number(n) { Some(n) } else { None }`")
pub fn Json::as_number(self : Json) -> Double? {
  guard self is Number(n, ..) else { return None }
  Some(n)
}

///|
/// Try to get this element as a String
#deprecated("Suggestion: `if json is String(s) { Some(s) } else { None }`")
pub fn Json::as_string(self : Json) -> String? {
  guard self is String(s) else { return None }
  Some(s)
}

///|
/// Try to get this element as an Array
#deprecated("Suggestion: `if json is Array(array) { Some(array) } else { None }`")
pub fn Json::as_array(self : Json) -> Array[Json]? {
  guard self is Array(arr) else { return None }
  Some(arr)
}

///|
/// Try to get this element as a Json Array and get the element at the `index` as a Json Value
#deprecated("Suggestion: `if json is Array(array) { array.get(index) } else { None }`")
pub fn Json::item(self : Json, index : Int) -> Json? {
  if self is Array(arr) {
    arr.get(index)
  } else {
    None
  }
}

///|
/// Try to get this element as an Object
#deprecated
pub fn Json::as_object(self : Json) -> Map[String, Json]? {
  guard self is Object(obj) else { return None }
  Some(obj)
}

///|
/// Try to get this element as a Json Object and get the element with the `key` as a Json Value
#deprecated("Suggestion: `if json is Object(obj) { obj.get(key) } else { None }`")
pub fn Json::value(self : Json, key : String) -> Json? {
  if self is Object(obj) {
    obj.get(key)
  } else {
    None
  }
}
