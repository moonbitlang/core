// Copyright 2024 International Digital Economy Academy
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

// Similar to Iter but used for two values
// It is useful for iterating over map entries
// without boxing
// It is useful for syntax sugar
// ```
//    foreach k, v := map { ... }
// ```
type Iter2[A, B] ((A, B) -> IterResult) -> IterResult

//TODO: Add intrinsic for Iter::run
pub fn run[A, B](self : Iter2[A, B], f : (A, B) -> IterResult) -> IterResult {
  (self._)(f)
}

pub impl[A : Show, B : Show] Show for Iter2[A, B] with output(self, logger) {
  Show::output(self.iter().to_array(), logger)
}

pub fn to_string[A : Show, B : Show](self : Iter2[A, B]) -> String {
  self.iter().to_array().to_string()
}

pub fn Iter2::new[A, B](
  f : ((A, B) -> IterResult) -> IterResult
) -> Iter2[A, B] {
  Iter2(f)
}

pub fn each[A, B](self : Iter2[A, B], f : (A, B) -> Unit) -> Unit {
  self.run(
    fn(a, b) {
      f(a, b)
      IterContinue
    },
  )
  |> ignore
}

pub fn iter[A, B](self : Iter2[A, B]) -> Iter[(A, B)] {
  Iter::new(fn(yield) { self.run(fn(a, b) { yield((a, b)) }) })
}

pub fn iter2[A, B](self : Iter2[A, B]) -> Iter2[A, B] {
  // This is a no-op to make sure
  // `for k,v in map.iter2() { ... }` 
  // still work    
  self
}

pub fn to_array[A, B](self : Iter2[A, B]) -> Array[(A, B)] {
  self.iter().to_array()
}
