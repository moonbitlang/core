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

pub fn to_string[A : Show, B : Show](self : (A, B)) -> String {
  "(".to_string() + self.0.to_string() + ", " + self.1.to_string() + ")"
}

pub fn to_string[A : Show, B : Show, C : Show](self : (A, B, C)) -> String {
  "(".to_string() + self.0.to_string() + ", " + self.1.to_string() + ", " + self.2.to_string() +
  ")"
}

pub fn to_string[A : Show, B : Show, C : Show, D : Show](
  self : (A, B, C, D)
) -> String {
  "(".to_string() + self.0.to_string() + ", " + self.1.to_string() + ", " + self.2.to_string() +
  ", " + self.3.to_string() + ")"
}

pub fn to_string[A : Show, B : Show, C : Show, D : Show, E : Show](
  self : (A, B, C, D, E)
) -> String {
  "(".to_string() + self.0.to_string() + ", " + self.1.to_string() + ", " + self.2.to_string() +
  ", " + self.3.to_string() + ", " + self.4.to_string() + ")"
}

pub fn to_string[A : Show, B : Show, C : Show, D : Show, E : Show, F : Show](
  self : (A, B, C, D, E, F)
) -> String {
  let (a, b, c, d, e, f) = self
  "(\(a), \(b), \(c), \(d), \(e), \(f))"
}

pub fn to_string[A : Show, B : Show, C : Show, D : Show, E : Show, F : Show, G : Show](
  self : (A, B, C, D, E, F, G)
) -> String {
  let (a, b, c, d, e, f, g) = self
  "(\(a), \(b), \(c), \(d), \(e), \(f), \(g))"
}
