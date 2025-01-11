// Copyright 2025 International Digital Economy Academy
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
pub fn op_equal[T0 : Eq, T1 : Eq](self : (T0, T1), other : (T0, T1)) -> Bool {
  self.0 == other.0 && self.1 == other.1
}

///|
pub fn op_equal[T0 : Eq, T1 : Eq, T2 : Eq](
  self : (T0, T1, T2),
  other : (T0, T1, T2)
) -> Bool {
  self.0 == other.0 && self.1 == other.1 && self.2 == other.2
}

///|
pub fn op_equal[T0 : Eq, T1 : Eq, T2 : Eq, T3 : Eq](
  self : (T0, T1, T2, T3),
  other : (T0, T1, T2, T3)
) -> Bool {
  self.0 == other.0 &&
  self.1 == other.1 &&
  self.2 == other.2 &&
  self.3 == other.3
}

///|
pub fn op_equal[T0 : Eq, T1 : Eq, T2 : Eq, T3 : Eq, T4 : Eq](
  self : (T0, T1, T2, T3, T4),
  other : (T0, T1, T2, T3, T4)
) -> Bool {
  self.0 == other.0 &&
  self.1 == other.1 &&
  self.2 == other.2 &&
  self.3 == other.3 &&
  self.4 == other.4
}

///|
pub fn op_equal[T0 : Eq, T1 : Eq, T2 : Eq, T3 : Eq, T4 : Eq, T5 : Eq](
  self : (T0, T1, T2, T3, T4, T5),
  other : (T0, T1, T2, T3, T4, T5)
) -> Bool {
  self.0 == other.0 &&
  self.1 == other.1 &&
  self.2 == other.2 &&
  self.3 == other.3 &&
  self.4 == other.4 &&
  self.5 == other.5
}

///|
pub fn op_equal[T0 : Eq, T1 : Eq, T2 : Eq, T3 : Eq, T4 : Eq, T5 : Eq, T6 : Eq](
  self : (T0, T1, T2, T3, T4, T5, T6),
  other : (T0, T1, T2, T3, T4, T5, T6)
) -> Bool {
  self.0 == other.0 &&
  self.1 == other.1 &&
  self.2 == other.2 &&
  self.3 == other.3 &&
  self.4 == other.4 &&
  self.5 == other.5 &&
  self.6 == other.6
}

///|
pub fn op_equal[T0 : Eq, T1 : Eq, T2 : Eq, T3 : Eq, T4 : Eq, T5 : Eq, T6 : Eq, T7 : Eq](
  self : (T0, T1, T2, T3, T4, T5, T6, T7),
  other : (T0, T1, T2, T3, T4, T5, T6, T7)
) -> Bool {
  self.0 == other.0 &&
  self.1 == other.1 &&
  self.2 == other.2 &&
  self.3 == other.3 &&
  self.4 == other.4 &&
  self.5 == other.5 &&
  self.6 == other.6 &&
  self.7 == other.7
}

///|
pub fn op_equal[T0 : Eq, T1 : Eq, T2 : Eq, T3 : Eq, T4 : Eq, T5 : Eq, T6 : Eq, T7 : Eq, T8 : Eq](
  self : (T0, T1, T2, T3, T4, T5, T6, T7, T8),
  other : (T0, T1, T2, T3, T4, T5, T6, T7, T8)
) -> Bool {
  self.0 == other.0 &&
  self.1 == other.1 &&
  self.2 == other.2 &&
  self.3 == other.3 &&
  self.4 == other.4 &&
  self.5 == other.5 &&
  self.6 == other.6 &&
  self.7 == other.7 &&
  self.8 == other.8
}

///|
pub fn op_equal[T0 : Eq, T1 : Eq, T2 : Eq, T3 : Eq, T4 : Eq, T5 : Eq, T6 : Eq, T7 : Eq, T8 : Eq, T9 : Eq](
  self : (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9),
  other : (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9)
) -> Bool {
  self.0 == other.0 &&
  self.1 == other.1 &&
  self.2 == other.2 &&
  self.3 == other.3 &&
  self.4 == other.4 &&
  self.5 == other.5 &&
  self.6 == other.6 &&
  self.7 == other.7 &&
  self.8 == other.8 &&
  self.9 == other.9
}

///|
pub fn op_equal[T0 : Eq, T1 : Eq, T2 : Eq, T3 : Eq, T4 : Eq, T5 : Eq, T6 : Eq, T7 : Eq, T8 : Eq, T9 : Eq, T10 : Eq](
  self : (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10),
  other : (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10)
) -> Bool {
  self.0 == other.0 &&
  self.1 == other.1 &&
  self.2 == other.2 &&
  self.3 == other.3 &&
  self.4 == other.4 &&
  self.5 == other.5 &&
  self.6 == other.6 &&
  self.7 == other.7 &&
  self.8 == other.8 &&
  self.9 == other.9 &&
  self.10 == other.10
}

///|
pub fn op_equal[T0 : Eq, T1 : Eq, T2 : Eq, T3 : Eq, T4 : Eq, T5 : Eq, T6 : Eq, T7 : Eq, T8 : Eq, T9 : Eq, T10 : Eq, T11 : Eq](
  self : (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11),
  other : (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11)
) -> Bool {
  self.0 == other.0 &&
  self.1 == other.1 &&
  self.2 == other.2 &&
  self.3 == other.3 &&
  self.4 == other.4 &&
  self.5 == other.5 &&
  self.6 == other.6 &&
  self.7 == other.7 &&
  self.8 == other.8 &&
  self.9 == other.9 &&
  self.10 == other.10 &&
  self.11 == other.11
}

///|
pub fn op_equal[T0 : Eq, T1 : Eq, T2 : Eq, T3 : Eq, T4 : Eq, T5 : Eq, T6 : Eq, T7 : Eq, T8 : Eq, T9 : Eq, T10 : Eq, T11 : Eq, T12 : Eq](
  self : (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12),
  other : (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12)
) -> Bool {
  self.0 == other.0 &&
  self.1 == other.1 &&
  self.2 == other.2 &&
  self.3 == other.3 &&
  self.4 == other.4 &&
  self.5 == other.5 &&
  self.6 == other.6 &&
  self.7 == other.7 &&
  self.8 == other.8 &&
  self.9 == other.9 &&
  self.10 == other.10 &&
  self.11 == other.11 &&
  self.12 == other.12
}

///|
pub fn op_equal[T0 : Eq, T1 : Eq, T2 : Eq, T3 : Eq, T4 : Eq, T5 : Eq, T6 : Eq, T7 : Eq, T8 : Eq, T9 : Eq, T10 : Eq, T11 : Eq, T12 : Eq, T13 : Eq](
  self : (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13),
  other : (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13)
) -> Bool {
  self.0 == other.0 &&
  self.1 == other.1 &&
  self.2 == other.2 &&
  self.3 == other.3 &&
  self.4 == other.4 &&
  self.5 == other.5 &&
  self.6 == other.6 &&
  self.7 == other.7 &&
  self.8 == other.8 &&
  self.9 == other.9 &&
  self.10 == other.10 &&
  self.11 == other.11 &&
  self.12 == other.12 &&
  self.13 == other.13
}

///|
pub fn op_equal[T0 : Eq, T1 : Eq, T2 : Eq, T3 : Eq, T4 : Eq, T5 : Eq, T6 : Eq, T7 : Eq, T8 : Eq, T9 : Eq, T10 : Eq, T11 : Eq, T12 : Eq, T13 : Eq, T14 : Eq](
  self : (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14),
  other : (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14)
) -> Bool {
  self.0 == other.0 &&
  self.1 == other.1 &&
  self.2 == other.2 &&
  self.3 == other.3 &&
  self.4 == other.4 &&
  self.5 == other.5 &&
  self.6 == other.6 &&
  self.7 == other.7 &&
  self.8 == other.8 &&
  self.9 == other.9 &&
  self.10 == other.10 &&
  self.11 == other.11 &&
  self.12 == other.12 &&
  self.13 == other.13 &&
  self.14 == other.14
}

///|
pub fn op_equal[T0 : Eq, T1 : Eq, T2 : Eq, T3 : Eq, T4 : Eq, T5 : Eq, T6 : Eq, T7 : Eq, T8 : Eq, T9 : Eq, T10 : Eq, T11 : Eq, T12 : Eq, T13 : Eq, T14 : Eq, T15 : Eq](
  self : (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14, T15),
  other : (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14, T15)
) -> Bool {
  self.0 == other.0 &&
  self.1 == other.1 &&
  self.2 == other.2 &&
  self.3 == other.3 &&
  self.4 == other.4 &&
  self.5 == other.5 &&
  self.6 == other.6 &&
  self.7 == other.7 &&
  self.8 == other.8 &&
  self.9 == other.9 &&
  self.10 == other.10 &&
  self.11 == other.11 &&
  self.12 == other.12 &&
  self.13 == other.13 &&
  self.14 == other.14 &&
  self.15 == other.15
}
