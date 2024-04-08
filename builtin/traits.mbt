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

/// Trait for types whose elements can test for equality
pub trait Eq {
  op_equal(Self, Self) -> Bool
}

/// Trait for types whose elements are ordered
///
/// The return value of [compare] is:
/// - zero, if the two arguments are equal
/// - negative, if the first argument is smaller
/// - positive, if the second argument is greater
pub trait Compare: Eq {
  compare(Self, Self) -> Int
}

/// Trait for types that can be hashed
pub trait Hash {
  hash(Self) -> Int
}

/// Trait for types with a default value
pub trait Default {
  default() -> Self
}

/// Trait for types that can be converted to `String`
pub trait Show {
  to_string(Self) -> String
}
