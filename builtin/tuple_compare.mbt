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
pub fn Tuple2::compare[T0 : Compare, T1 : Compare](
  self : (T0, T1),
  other : (T0, T1)
) -> Int {
  let t0 = self.0.compare(other.0)
  guard t0 == 0 else { return t0 }
  self.1.compare(other.1)
}

///|
pub fn Tuple3::compare[T0 : Compare, T1 : Compare, T2 : Compare](
  self : (T0, T1, T2),
  other : (T0, T1, T2)
) -> Int {
  let t0 = self.0.compare(other.0)
  guard t0 == 0 else { return t0 }
  let t1 = self.1.compare(other.1)
  guard t1 == 0 else { return t1 }
  self.2.compare(other.2)
}

///|
pub fn Tuple4::compare[T0 : Compare, T1 : Compare, T2 : Compare, T3 : Compare](
  self : (T0, T1, T2, T3),
  other : (T0, T1, T2, T3)
) -> Int {
  let t0 = self.0.compare(other.0)
  guard t0 == 0 else { return t0 }
  let t1 = self.1.compare(other.1)
  guard t1 == 0 else { return t1 }
  let t2 = self.2.compare(other.2)
  guard t2 == 0 else { return t2 }
  self.3.compare(other.3)
}

///|
pub fn Tuple5::compare[T0 : Compare, T1 : Compare, T2 : Compare, T3 : Compare, T4 : Compare](
  self : (T0, T1, T2, T3, T4),
  other : (T0, T1, T2, T3, T4)
) -> Int {
  let t0 = self.0.compare(other.0)
  guard t0 == 0 else { return t0 }
  let t1 = self.1.compare(other.1)
  guard t1 == 0 else { return t1 }
  let t2 = self.2.compare(other.2)
  guard t2 == 0 else { return t2 }
  let t3 = self.3.compare(other.3)
  guard t3 == 0 else { return t3 }
  self.4.compare(other.4)
}

///|
pub fn Tuple6::compare[T0 : Compare, T1 : Compare, T2 : Compare, T3 : Compare, T4 : Compare, T5 : Compare](
  self : (T0, T1, T2, T3, T4, T5),
  other : (T0, T1, T2, T3, T4, T5)
) -> Int {
  let t0 = self.0.compare(other.0)
  guard t0 == 0 else { return t0 }
  let t1 = self.1.compare(other.1)
  guard t1 == 0 else { return t1 }
  let t2 = self.2.compare(other.2)
  guard t2 == 0 else { return t2 }
  let t3 = self.3.compare(other.3)
  guard t3 == 0 else { return t3 }
  let t4 = self.4.compare(other.4)
  guard t4 == 0 else { return t4 }
  self.5.compare(other.5)
}

///|
pub fn Tuple7::compare[T0 : Compare, T1 : Compare, T2 : Compare, T3 : Compare, T4 : Compare, T5 : Compare, T6 : Compare](
  self : (T0, T1, T2, T3, T4, T5, T6),
  other : (T0, T1, T2, T3, T4, T5, T6)
) -> Int {
  let t0 = self.0.compare(other.0)
  guard t0 == 0 else { return t0 }
  let t1 = self.1.compare(other.1)
  guard t1 == 0 else { return t1 }
  let t2 = self.2.compare(other.2)
  guard t2 == 0 else { return t2 }
  let t3 = self.3.compare(other.3)
  guard t3 == 0 else { return t3 }
  let t4 = self.4.compare(other.4)
  guard t4 == 0 else { return t4 }
  let t5 = self.5.compare(other.5)
  guard t5 == 0 else { return t5 }
  self.6.compare(other.6)
}

///|
pub fn Tuple8::compare[T0 : Compare, T1 : Compare, T2 : Compare, T3 : Compare, T4 : Compare, T5 : Compare, T6 : Compare, T7 : Compare](
  self : (T0, T1, T2, T3, T4, T5, T6, T7),
  other : (T0, T1, T2, T3, T4, T5, T6, T7)
) -> Int {
  let t0 = self.0.compare(other.0)
  guard t0 == 0 else { return t0 }
  let t1 = self.1.compare(other.1)
  guard t1 == 0 else { return t1 }
  let t2 = self.2.compare(other.2)
  guard t2 == 0 else { return t2 }
  let t3 = self.3.compare(other.3)
  guard t3 == 0 else { return t3 }
  let t4 = self.4.compare(other.4)
  guard t4 == 0 else { return t4 }
  let t5 = self.5.compare(other.5)
  guard t5 == 0 else { return t5 }
  let t6 = self.6.compare(other.6)
  guard t6 == 0 else { return t6 }
  self.7.compare(other.7)
}

///|
pub fn Tuple9::compare[T0 : Compare, T1 : Compare, T2 : Compare, T3 : Compare, T4 : Compare, T5 : Compare, T6 : Compare, T7 : Compare, T8 : Compare](
  self : (T0, T1, T2, T3, T4, T5, T6, T7, T8),
  other : (T0, T1, T2, T3, T4, T5, T6, T7, T8)
) -> Int {
  let t0 = self.0.compare(other.0)
  guard t0 == 0 else { return t0 }
  let t1 = self.1.compare(other.1)
  guard t1 == 0 else { return t1 }
  let t2 = self.2.compare(other.2)
  guard t2 == 0 else { return t2 }
  let t3 = self.3.compare(other.3)
  guard t3 == 0 else { return t3 }
  let t4 = self.4.compare(other.4)
  guard t4 == 0 else { return t4 }
  let t5 = self.5.compare(other.5)
  guard t5 == 0 else { return t5 }
  let t6 = self.6.compare(other.6)
  guard t6 == 0 else { return t6 }
  let t7 = self.7.compare(other.7)
  guard t7 == 0 else { return t7 }
  self.8.compare(other.8)
}

///|
pub fn Tuple10::compare[T0 : Compare, T1 : Compare, T2 : Compare, T3 : Compare, T4 : Compare, T5 : Compare, T6 : Compare, T7 : Compare, T8 : Compare, T9 : Compare](
  self : (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9),
  other : (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9)
) -> Int {
  let t0 = self.0.compare(other.0)
  guard t0 == 0 else { return t0 }
  let t1 = self.1.compare(other.1)
  guard t1 == 0 else { return t1 }
  let t2 = self.2.compare(other.2)
  guard t2 == 0 else { return t2 }
  let t3 = self.3.compare(other.3)
  guard t3 == 0 else { return t3 }
  let t4 = self.4.compare(other.4)
  guard t4 == 0 else { return t4 }
  let t5 = self.5.compare(other.5)
  guard t5 == 0 else { return t5 }
  let t6 = self.6.compare(other.6)
  guard t6 == 0 else { return t6 }
  let t7 = self.7.compare(other.7)
  guard t7 == 0 else { return t7 }
  let t8 = self.8.compare(other.8)
  guard t8 == 0 else { return t8 }
  self.9.compare(other.9)
}

///|
pub fn Tuple11::compare[T0 : Compare, T1 : Compare, T2 : Compare, T3 : Compare, T4 : Compare, T5 : Compare, T6 : Compare, T7 : Compare, T8 : Compare, T9 : Compare, T10 : Compare](
  self : (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10),
  other : (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10)
) -> Int {
  let t0 = self.0.compare(other.0)
  guard t0 == 0 else { return t0 }
  let t1 = self.1.compare(other.1)
  guard t1 == 0 else { return t1 }
  let t2 = self.2.compare(other.2)
  guard t2 == 0 else { return t2 }
  let t3 = self.3.compare(other.3)
  guard t3 == 0 else { return t3 }
  let t4 = self.4.compare(other.4)
  guard t4 == 0 else { return t4 }
  let t5 = self.5.compare(other.5)
  guard t5 == 0 else { return t5 }
  let t6 = self.6.compare(other.6)
  guard t6 == 0 else { return t6 }
  let t7 = self.7.compare(other.7)
  guard t7 == 0 else { return t7 }
  let t8 = self.8.compare(other.8)
  guard t8 == 0 else { return t8 }
  let t9 = self.9.compare(other.9)
  guard t9 == 0 else { return t9 }
  self.10.compare(other.10)
}

///|
pub fn Tuple12::compare[T0 : Compare, T1 : Compare, T2 : Compare, T3 : Compare, T4 : Compare, T5 : Compare, T6 : Compare, T7 : Compare, T8 : Compare, T9 : Compare, T10 : Compare, T11 : Compare](
  self : (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11),
  other : (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11)
) -> Int {
  let t0 = self.0.compare(other.0)
  guard t0 == 0 else { return t0 }
  let t1 = self.1.compare(other.1)
  guard t1 == 0 else { return t1 }
  let t2 = self.2.compare(other.2)
  guard t2 == 0 else { return t2 }
  let t3 = self.3.compare(other.3)
  guard t3 == 0 else { return t3 }
  let t4 = self.4.compare(other.4)
  guard t4 == 0 else { return t4 }
  let t5 = self.5.compare(other.5)
  guard t5 == 0 else { return t5 }
  let t6 = self.6.compare(other.6)
  guard t6 == 0 else { return t6 }
  let t7 = self.7.compare(other.7)
  guard t7 == 0 else { return t7 }
  let t8 = self.8.compare(other.8)
  guard t8 == 0 else { return t8 }
  let t9 = self.9.compare(other.9)
  guard t9 == 0 else { return t9 }
  let t10 = self.10.compare(other.10)
  guard t10 == 0 else { return t10 }
  self.11.compare(other.11)
}

///|
pub fn Tuple13::compare[T0 : Compare, T1 : Compare, T2 : Compare, T3 : Compare, T4 : Compare, T5 : Compare, T6 : Compare, T7 : Compare, T8 : Compare, T9 : Compare, T10 : Compare, T11 : Compare, T12 : Compare](
  self : (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12),
  other : (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12)
) -> Int {
  let t0 = self.0.compare(other.0)
  guard t0 == 0 else { return t0 }
  let t1 = self.1.compare(other.1)
  guard t1 == 0 else { return t1 }
  let t2 = self.2.compare(other.2)
  guard t2 == 0 else { return t2 }
  let t3 = self.3.compare(other.3)
  guard t3 == 0 else { return t3 }
  let t4 = self.4.compare(other.4)
  guard t4 == 0 else { return t4 }
  let t5 = self.5.compare(other.5)
  guard t5 == 0 else { return t5 }
  let t6 = self.6.compare(other.6)
  guard t6 == 0 else { return t6 }
  let t7 = self.7.compare(other.7)
  guard t7 == 0 else { return t7 }
  let t8 = self.8.compare(other.8)
  guard t8 == 0 else { return t8 }
  let t9 = self.9.compare(other.9)
  guard t9 == 0 else { return t9 }
  let t10 = self.10.compare(other.10)
  guard t10 == 0 else { return t10 }
  let t11 = self.11.compare(other.11)
  guard t11 == 0 else { return t11 }
  self.12.compare(other.12)
}

///|
pub fn Tuple14::compare[T0 : Compare, T1 : Compare, T2 : Compare, T3 : Compare, T4 : Compare, T5 : Compare, T6 : Compare, T7 : Compare, T8 : Compare, T9 : Compare, T10 : Compare, T11 : Compare, T12 : Compare, T13 : Compare](
  self : (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13),
  other : (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13)
) -> Int {
  let t0 = self.0.compare(other.0)
  guard t0 == 0 else { return t0 }
  let t1 = self.1.compare(other.1)
  guard t1 == 0 else { return t1 }
  let t2 = self.2.compare(other.2)
  guard t2 == 0 else { return t2 }
  let t3 = self.3.compare(other.3)
  guard t3 == 0 else { return t3 }
  let t4 = self.4.compare(other.4)
  guard t4 == 0 else { return t4 }
  let t5 = self.5.compare(other.5)
  guard t5 == 0 else { return t5 }
  let t6 = self.6.compare(other.6)
  guard t6 == 0 else { return t6 }
  let t7 = self.7.compare(other.7)
  guard t7 == 0 else { return t7 }
  let t8 = self.8.compare(other.8)
  guard t8 == 0 else { return t8 }
  let t9 = self.9.compare(other.9)
  guard t9 == 0 else { return t9 }
  let t10 = self.10.compare(other.10)
  guard t10 == 0 else { return t10 }
  let t11 = self.11.compare(other.11)
  guard t11 == 0 else { return t11 }
  let t12 = self.12.compare(other.12)
  guard t12 == 0 else { return t12 }
  self.13.compare(other.13)
}

///|
pub fn Tuple15::compare[T0 : Compare, T1 : Compare, T2 : Compare, T3 : Compare, T4 : Compare, T5 : Compare, T6 : Compare, T7 : Compare, T8 : Compare, T9 : Compare, T10 : Compare, T11 : Compare, T12 : Compare, T13 : Compare, T14 : Compare](
  self : (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14),
  other : (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14)
) -> Int {
  let t0 = self.0.compare(other.0)
  guard t0 == 0 else { return t0 }
  let t1 = self.1.compare(other.1)
  guard t1 == 0 else { return t1 }
  let t2 = self.2.compare(other.2)
  guard t2 == 0 else { return t2 }
  let t3 = self.3.compare(other.3)
  guard t3 == 0 else { return t3 }
  let t4 = self.4.compare(other.4)
  guard t4 == 0 else { return t4 }
  let t5 = self.5.compare(other.5)
  guard t5 == 0 else { return t5 }
  let t6 = self.6.compare(other.6)
  guard t6 == 0 else { return t6 }
  let t7 = self.7.compare(other.7)
  guard t7 == 0 else { return t7 }
  let t8 = self.8.compare(other.8)
  guard t8 == 0 else { return t8 }
  let t9 = self.9.compare(other.9)
  guard t9 == 0 else { return t9 }
  let t10 = self.10.compare(other.10)
  guard t10 == 0 else { return t10 }
  let t11 = self.11.compare(other.11)
  guard t11 == 0 else { return t11 }
  let t12 = self.12.compare(other.12)
  guard t12 == 0 else { return t12 }
  let t13 = self.13.compare(other.13)
  guard t13 == 0 else { return t13 }
  self.14.compare(other.14)
}

///|
pub fn Tuple16::compare[T0 : Compare, T1 : Compare, T2 : Compare, T3 : Compare, T4 : Compare, T5 : Compare, T6 : Compare, T7 : Compare, T8 : Compare, T9 : Compare, T10 : Compare, T11 : Compare, T12 : Compare, T13 : Compare, T14 : Compare, T15 : Compare](
  self : (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14, T15),
  other : (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14, T15)
) -> Int {
  let t0 = self.0.compare(other.0)
  guard t0 == 0 else { return t0 }
  let t1 = self.1.compare(other.1)
  guard t1 == 0 else { return t1 }
  let t2 = self.2.compare(other.2)
  guard t2 == 0 else { return t2 }
  let t3 = self.3.compare(other.3)
  guard t3 == 0 else { return t3 }
  let t4 = self.4.compare(other.4)
  guard t4 == 0 else { return t4 }
  let t5 = self.5.compare(other.5)
  guard t5 == 0 else { return t5 }
  let t6 = self.6.compare(other.6)
  guard t6 == 0 else { return t6 }
  let t7 = self.7.compare(other.7)
  guard t7 == 0 else { return t7 }
  let t8 = self.8.compare(other.8)
  guard t8 == 0 else { return t8 }
  let t9 = self.9.compare(other.9)
  guard t9 == 0 else { return t9 }
  let t10 = self.10.compare(other.10)
  guard t10 == 0 else { return t10 }
  let t11 = self.11.compare(other.11)
  guard t11 == 0 else { return t11 }
  let t12 = self.12.compare(other.12)
  guard t12 == 0 else { return t12 }
  let t13 = self.13.compare(other.13)
  guard t13 == 0 else { return t13 }
  let t14 = self.14.compare(other.14)
  guard t14 == 0 else { return t14 }
  self.15.compare(other.15)
}

// the type alias below are used to declare methods on tuple as:
//
//    fn TupleN::meth(...)
//
// so that this methods won't pollute the toplevel namespace of `builtin`

///|
typealias Tuple2[T0, T1] = (T0, T1)

///|
typealias Tuple3[T0, T1, T2] = (T0, T1, T2)

///|
typealias Tuple4[T0, T1, T2, T3] = (T0, T1, T2, T3)

///|
typealias Tuple5[T0, T1, T2, T3, T4] = (T0, T1, T2, T3, T4)

///|
typealias Tuple6[T0, T1, T2, T3, T4, T5] = (T0, T1, T2, T3, T4, T5)

///|
typealias Tuple7[T0, T1, T2, T3, T4, T5, T6] = (T0, T1, T2, T3, T4, T5, T6)

///|
typealias Tuple8[T0, T1, T2, T3, T4, T5, T6, T7] = (
  T0,
  T1,
  T2,
  T3,
  T4,
  T5,
  T6,
  T7,
)

///|
typealias Tuple9[T0, T1, T2, T3, T4, T5, T6, T7, T8] = (
  T0,
  T1,
  T2,
  T3,
  T4,
  T5,
  T6,
  T7,
  T8,
)

///|
typealias Tuple10[T0, T1, T2, T3, T4, T5, T6, T7, T8, T9] = (
  T0,
  T1,
  T2,
  T3,
  T4,
  T5,
  T6,
  T7,
  T8,
  T9,
)

///|
typealias Tuple11[T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10] = (
  T0,
  T1,
  T2,
  T3,
  T4,
  T5,
  T6,
  T7,
  T8,
  T9,
  T10,
)

///|
typealias Tuple12[T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11] = (
  T0,
  T1,
  T2,
  T3,
  T4,
  T5,
  T6,
  T7,
  T8,
  T9,
  T10,
  T11,
)

///|
typealias Tuple13[T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12] = (
  T0,
  T1,
  T2,
  T3,
  T4,
  T5,
  T6,
  T7,
  T8,
  T9,
  T10,
  T11,
  T12,
)

///|
typealias Tuple14[T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13] = (
  T0,
  T1,
  T2,
  T3,
  T4,
  T5,
  T6,
  T7,
  T8,
  T9,
  T10,
  T11,
  T12,
  T13,
)

///|
typealias Tuple15[T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14] = (
  T0,
  T1,
  T2,
  T3,
  T4,
  T5,
  T6,
  T7,
  T8,
  T9,
  T10,
  T11,
  T12,
  T13,
  T14,
)

///|
typealias Tuple16[T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14, T15] = (
  T0,
  T1,
  T2,
  T3,
  T4,
  T5,
  T6,
  T7,
  T8,
  T9,
  T10,
  T11,
  T12,
  T13,
  T14,
  T15,
)
