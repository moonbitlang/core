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
pub impl[A : Show, B : Show] Show for (A, B) with output(self, logger) {
  let (a, b) = self
  logger.write_string("(")
  logger.write_object(a)
  logger.write_string(", ")
  logger.write_object(b)
  logger.write_string(")")
}

///|
pub impl[A : Show, B : Show, C : Show] Show for (A, B, C) with output(
  self,
  logger,
) {
  let (a, b, c) = self
  logger.write_string("(")
  logger.write_object(a)
  logger.write_string(", ")
  logger.write_object(b)
  logger.write_string(", ")
  logger.write_object(c)
  logger.write_string(")")
}

///|
pub impl[A : Show, B : Show, C : Show, D : Show] Show for (A, B, C, D) with output(
  self,
  logger,
) {
  let (a, b, c, d) = self
  logger.write_string("(")
  logger.write_object(a)
  logger.write_string(", ")
  logger.write_object(b)
  logger.write_string(", ")
  logger.write_object(c)
  logger.write_string(", ")
  logger.write_object(d)
  logger.write_string(")")
}

///|
pub impl[A : Show, B : Show, C : Show, D : Show, E : Show] Show for (
  A,
  B,
  C,
  D,
  E,
) with output(self, logger) {
  let (a, b, c, d, e) = self
  logger.write_string("(")
  logger.write_object(a)
  logger.write_string(", ")
  logger.write_object(b)
  logger.write_string(", ")
  logger.write_object(c)
  logger.write_string(", ")
  logger.write_object(d)
  logger.write_string(", ")
  logger.write_object(e)
  logger.write_string(")")
}

///|
pub impl[A : Show, B : Show, C : Show, D : Show, E : Show, F : Show] Show for (
  A,
  B,
  C,
  D,
  E,
  F,
) with output(self, logger) {
  let (a, b, c, d, e, f) = self
  logger.write_string("(")
  logger.write_object(a)
  logger.write_string(", ")
  logger.write_object(b)
  logger.write_string(", ")
  logger.write_object(c)
  logger.write_string(", ")
  logger.write_object(d)
  logger.write_string(", ")
  logger.write_object(e)
  logger.write_string(", ")
  logger.write_object(f)
  logger.write_string(")")
}

///|
pub impl[A : Show, B : Show, C : Show, D : Show, E : Show, F : Show, G : Show] Show for (
  A,
  B,
  C,
  D,
  E,
  F,
  G,
) with output(self, logger) {
  let (a, b, c, d, e, f, g) = self
  logger.write_string("(")
  logger.write_object(a)
  logger.write_string(", ")
  logger.write_object(b)
  logger.write_string(", ")
  logger.write_object(c)
  logger.write_string(", ")
  logger.write_object(d)
  logger.write_string(", ")
  logger.write_object(e)
  logger.write_string(", ")
  logger.write_object(f)
  logger.write_string(", ")
  logger.write_object(g)
  logger.write_string(")")
}

///|
pub impl[
  T0 : Show,
  T1 : Show,
  T2 : Show,
  T3 : Show,
  T4 : Show,
  T5 : Show,
  T6 : Show,
  T7 : Show,
] Show for (T0, T1, T2, T3, T4, T5, T6, T7) with output(self, logger) {
  let (x0, x1, x2, x3, x4, x5, x6, x7) = self
  logger.write_string("(")
  logger.write_object(x0)
  logger.write_string(", ")
  logger.write_object(x1)
  logger.write_string(", ")
  logger.write_object(x2)
  logger.write_string(", ")
  logger.write_object(x3)
  logger.write_string(", ")
  logger.write_object(x4)
  logger.write_string(", ")
  logger.write_object(x5)
  logger.write_string(", ")
  logger.write_object(x6)
  logger.write_string(", ")
  logger.write_object(x7)
  logger.write_string(")")
}

///|
pub impl[
  T0 : Show,
  T1 : Show,
  T2 : Show,
  T3 : Show,
  T4 : Show,
  T5 : Show,
  T6 : Show,
  T7 : Show,
  T8 : Show,
] Show for (T0, T1, T2, T3, T4, T5, T6, T7, T8) with output(self, logger) {
  let (x0, x1, x2, x3, x4, x5, x6, x7, x8) = self
  logger.write_string("(")
  logger.write_object(x0)
  logger.write_string(", ")
  logger.write_object(x1)
  logger.write_string(", ")
  logger.write_object(x2)
  logger.write_string(", ")
  logger.write_object(x3)
  logger.write_string(", ")
  logger.write_object(x4)
  logger.write_string(", ")
  logger.write_object(x5)
  logger.write_string(", ")
  logger.write_object(x6)
  logger.write_string(", ")
  logger.write_object(x7)
  logger.write_string(", ")
  logger.write_object(x8)
  logger.write_string(")")
}

///|
pub impl[
  T0 : Show,
  T1 : Show,
  T2 : Show,
  T3 : Show,
  T4 : Show,
  T5 : Show,
  T6 : Show,
  T7 : Show,
  T8 : Show,
  T9 : Show,
] Show for (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9) with output(self, logger) {
  let (x0, x1, x2, x3, x4, x5, x6, x7, x8, x9) = self
  logger.write_string("(")
  logger.write_object(x0)
  logger.write_string(", ")
  logger.write_object(x1)
  logger.write_string(", ")
  logger.write_object(x2)
  logger.write_string(", ")
  logger.write_object(x3)
  logger.write_string(", ")
  logger.write_object(x4)
  logger.write_string(", ")
  logger.write_object(x5)
  logger.write_string(", ")
  logger.write_object(x6)
  logger.write_string(", ")
  logger.write_object(x7)
  logger.write_string(", ")
  logger.write_object(x8)
  logger.write_string(", ")
  logger.write_object(x9)
  logger.write_string(")")
}

///|
pub impl[
  T0 : Show,
  T1 : Show,
  T2 : Show,
  T3 : Show,
  T4 : Show,
  T5 : Show,
  T6 : Show,
  T7 : Show,
  T8 : Show,
  T9 : Show,
  T10 : Show,
] Show for (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10) with output(
  self,
  logger,
) {
  let (x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10) = self
  logger.write_string("(")
  logger.write_object(x0)
  logger.write_string(", ")
  logger.write_object(x1)
  logger.write_string(", ")
  logger.write_object(x2)
  logger.write_string(", ")
  logger.write_object(x3)
  logger.write_string(", ")
  logger.write_object(x4)
  logger.write_string(", ")
  logger.write_object(x5)
  logger.write_string(", ")
  logger.write_object(x6)
  logger.write_string(", ")
  logger.write_object(x7)
  logger.write_string(", ")
  logger.write_object(x8)
  logger.write_string(", ")
  logger.write_object(x9)
  logger.write_string(", ")
  logger.write_object(x10)
  logger.write_string(")")
}

///|
pub impl[
  T0 : Show,
  T1 : Show,
  T2 : Show,
  T3 : Show,
  T4 : Show,
  T5 : Show,
  T6 : Show,
  T7 : Show,
  T8 : Show,
  T9 : Show,
  T10 : Show,
  T11 : Show,
] Show for (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11) with output(
  self,
  logger,
) {
  let (x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11) = self
  logger.write_string("(")
  logger.write_object(x0)
  logger.write_string(", ")
  logger.write_object(x1)
  logger.write_string(", ")
  logger.write_object(x2)
  logger.write_string(", ")
  logger.write_object(x3)
  logger.write_string(", ")
  logger.write_object(x4)
  logger.write_string(", ")
  logger.write_object(x5)
  logger.write_string(", ")
  logger.write_object(x6)
  logger.write_string(", ")
  logger.write_object(x7)
  logger.write_string(", ")
  logger.write_object(x8)
  logger.write_string(", ")
  logger.write_object(x9)
  logger.write_string(", ")
  logger.write_object(x10)
  logger.write_string(", ")
  logger.write_object(x11)
  logger.write_string(")")
}

///|
pub impl[
  T0 : Show,
  T1 : Show,
  T2 : Show,
  T3 : Show,
  T4 : Show,
  T5 : Show,
  T6 : Show,
  T7 : Show,
  T8 : Show,
  T9 : Show,
  T10 : Show,
  T11 : Show,
  T12 : Show,
] Show for (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12) with output(
  self,
  logger,
) {
  let (x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12) = self
  logger.write_string("(")
  logger.write_object(x0)
  logger.write_string(", ")
  logger.write_object(x1)
  logger.write_string(", ")
  logger.write_object(x2)
  logger.write_string(", ")
  logger.write_object(x3)
  logger.write_string(", ")
  logger.write_object(x4)
  logger.write_string(", ")
  logger.write_object(x5)
  logger.write_string(", ")
  logger.write_object(x6)
  logger.write_string(", ")
  logger.write_object(x7)
  logger.write_string(", ")
  logger.write_object(x8)
  logger.write_string(", ")
  logger.write_object(x9)
  logger.write_string(", ")
  logger.write_object(x10)
  logger.write_string(", ")
  logger.write_object(x11)
  logger.write_string(", ")
  logger.write_object(x12)
  logger.write_string(")")
}

///|
pub impl[
  T0 : Show,
  T1 : Show,
  T2 : Show,
  T3 : Show,
  T4 : Show,
  T5 : Show,
  T6 : Show,
  T7 : Show,
  T8 : Show,
  T9 : Show,
  T10 : Show,
  T11 : Show,
  T12 : Show,
  T13 : Show,
] Show for (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13) with output(
  self,
  logger,
) {
  let (x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13) = self
  logger.write_string("(")
  logger.write_object(x0)
  logger.write_string(", ")
  logger.write_object(x1)
  logger.write_string(", ")
  logger.write_object(x2)
  logger.write_string(", ")
  logger.write_object(x3)
  logger.write_string(", ")
  logger.write_object(x4)
  logger.write_string(", ")
  logger.write_object(x5)
  logger.write_string(", ")
  logger.write_object(x6)
  logger.write_string(", ")
  logger.write_object(x7)
  logger.write_string(", ")
  logger.write_object(x8)
  logger.write_string(", ")
  logger.write_object(x9)
  logger.write_string(", ")
  logger.write_object(x10)
  logger.write_string(", ")
  logger.write_object(x11)
  logger.write_string(", ")
  logger.write_object(x12)
  logger.write_string(", ")
  logger.write_object(x13)
  logger.write_string(")")
}

///|
pub impl[
  T0 : Show,
  T1 : Show,
  T2 : Show,
  T3 : Show,
  T4 : Show,
  T5 : Show,
  T6 : Show,
  T7 : Show,
  T8 : Show,
  T9 : Show,
  T10 : Show,
  T11 : Show,
  T12 : Show,
  T13 : Show,
  T14 : Show,
] Show for (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14) with output(
  self,
  logger,
) {
  let (x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14) = self
  logger.write_string("(")
  logger.write_object(x0)
  logger.write_string(", ")
  logger.write_object(x1)
  logger.write_string(", ")
  logger.write_object(x2)
  logger.write_string(", ")
  logger.write_object(x3)
  logger.write_string(", ")
  logger.write_object(x4)
  logger.write_string(", ")
  logger.write_object(x5)
  logger.write_string(", ")
  logger.write_object(x6)
  logger.write_string(", ")
  logger.write_object(x7)
  logger.write_string(", ")
  logger.write_object(x8)
  logger.write_string(", ")
  logger.write_object(x9)
  logger.write_string(", ")
  logger.write_object(x10)
  logger.write_string(", ")
  logger.write_object(x11)
  logger.write_string(", ")
  logger.write_object(x12)
  logger.write_string(", ")
  logger.write_object(x13)
  logger.write_string(", ")
  logger.write_object(x14)
  logger.write_string(")")
}

///|
pub impl[
  T0 : Show,
  T1 : Show,
  T2 : Show,
  T3 : Show,
  T4 : Show,
  T5 : Show,
  T6 : Show,
  T7 : Show,
  T8 : Show,
  T9 : Show,
  T10 : Show,
  T11 : Show,
  T12 : Show,
  T13 : Show,
  T14 : Show,
  T15 : Show,
] Show for (
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
) with output(self, logger) {
  let (x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15) = self
  logger.write_string("(")
  logger.write_object(x0)
  logger.write_string(", ")
  logger.write_object(x1)
  logger.write_string(", ")
  logger.write_object(x2)
  logger.write_string(", ")
  logger.write_object(x3)
  logger.write_string(", ")
  logger.write_object(x4)
  logger.write_string(", ")
  logger.write_object(x5)
  logger.write_string(", ")
  logger.write_object(x6)
  logger.write_string(", ")
  logger.write_object(x7)
  logger.write_string(", ")
  logger.write_object(x8)
  logger.write_string(", ")
  logger.write_object(x9)
  logger.write_string(", ")
  logger.write_object(x10)
  logger.write_string(", ")
  logger.write_object(x11)
  logger.write_string(", ")
  logger.write_object(x12)
  logger.write_string(", ")
  logger.write_object(x13)
  logger.write_string(", ")
  logger.write_object(x14)
  logger.write_string(", ")
  logger.write_object(x15)
  logger.write_string(")")
}
