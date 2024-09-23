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

pub impl[A : Show, B : Show] Show for (A, B) with output(self, logger) {
  let (a, b) = self
  logger
  ..write_string("(")
  ..write_object(a)
  ..write_string(", ")
  ..write_object(b)
  .write_string(")")
}

pub fn to_string[A : Show, B : Show](self : (A, B)) -> String {
  Show::to_string(self)
}

pub impl[A : Show, B : Show, C : Show] Show for (A, B, C) with output(
  self,
  logger
) {
  let (a, b, c) = self
  logger
  ..write_string("(")
  ..write_object(a)
  ..write_string(", ")
  ..write_object(b)
  ..write_string(", ")
  ..write_object(c)
  .write_string(")")
}

pub fn to_string[A : Show, B : Show, C : Show](self : (A, B, C)) -> String {
  Show::to_string(self)
}

pub impl[A : Show, B : Show, C : Show, D : Show] Show for (A, B, C, D) with output(
  self,
  logger
) {
  let (a, b, c, d) = self
  logger
  ..write_string("(")
  ..write_object(a)
  ..write_string(", ")
  ..write_object(b)
  ..write_string(", ")
  ..write_object(c)
  ..write_string(", ")
  ..write_object(d)
  .write_string(")")
}

pub fn to_string[A : Show, B : Show, C : Show, D : Show](
  self : (A, B, C, D)
) -> String {
  Show::to_string(self)
}

pub impl[A : Show, B : Show, C : Show, D : Show, E : Show] Show for (
  A,
  B,
  C,
  D,
  E,
) with output(self, logger) {
  let (a, b, c, d, e) = self
  logger
  ..write_string("(")
  ..write_object(a)
  ..write_string(", ")
  ..write_object(b)
  ..write_string(", ")
  ..write_object(c)
  ..write_string(", ")
  ..write_object(d)
  ..write_string(", ")
  ..write_object(e)
  .write_string(")")
}

pub fn to_string[A : Show, B : Show, C : Show, D : Show, E : Show](
  self : (A, B, C, D, E)
) -> String {
  Show::to_string(self)
}

pub impl[A : Show, B : Show, C : Show, D : Show, E : Show, F : Show] Show for (
  A,
  B,
  C,
  D,
  E,
  F,
) with output(self, logger) {
  let (a, b, c, d, e, f) = self
  logger
  ..write_string("(")
  ..write_object(a)
  ..write_string(", ")
  ..write_object(b)
  ..write_string(", ")
  ..write_object(c)
  ..write_string(", ")
  ..write_object(d)
  ..write_string(", ")
  ..write_object(e)
  ..write_string(", ")
  ..write_object(f)
  .write_string(")")
}

pub fn to_string[A : Show, B : Show, C : Show, D : Show, E : Show, F : Show](
  self : (A, B, C, D, E, F)
) -> String {
  Show::to_string(self)
}

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
  logger
  ..write_string("(")
  ..write_object(a)
  ..write_string(", ")
  ..write_object(b)
  ..write_string(", ")
  ..write_object(c)
  ..write_string(", ")
  ..write_object(d)
  ..write_string(", ")
  ..write_object(e)
  ..write_string(", ")
  ..write_object(f)
  ..write_string(", ")
  ..write_object(g)
  .write_string(")")
}

pub fn to_string[A : Show, B : Show, C : Show, D : Show, E : Show, F : Show, G : Show](
  self : (A, B, C, D, E, F, G)
) -> String {
  Show::to_string(self)
}

pub impl[T0 : Show, T1 : Show, T2 : Show, T3 : Show, T4 : Show, T5 : Show, T6 : Show, T7 : Show] Show for (
  T0,
  T1,
  T2,
  T3,
  T4,
  T5,
  T6,
  T7,
) with output(self, logger) {
  let (x0, x1, x2, x3, x4, x5, x6, x7) = self
  logger
  ..write_string("(")
  ..write_object(x0)
  ..write_string(", ")
  ..write_object(x1)
  ..write_string(", ")
  ..write_object(x2)
  ..write_string(", ")
  ..write_object(x3)
  ..write_string(", ")
  ..write_object(x4)
  ..write_string(", ")
  ..write_object(x5)
  ..write_string(", ")
  ..write_object(x6)
  ..write_string(", ")
  ..write_object(x7)
  .write_string(")")
}

pub fn to_string[T0 : Show, T1 : Show, T2 : Show, T3 : Show, T4 : Show, T5 : Show, T6 : Show, T7 : Show](
  self : (T0, T1, T2, T3, T4, T5, T6, T7)
) -> String {
  Show::to_string(self)
}

pub impl[T0 : Show, T1 : Show, T2 : Show, T3 : Show, T4 : Show, T5 : Show, T6 : Show, T7 : Show, T8 : Show] Show for (
  T0,
  T1,
  T2,
  T3,
  T4,
  T5,
  T6,
  T7,
  T8,
) with output(self, logger) {
  let (x0, x1, x2, x3, x4, x5, x6, x7, x8) = self
  logger
  ..write_string("(")
  ..write_object(x0)
  ..write_string(", ")
  ..write_object(x1)
  ..write_string(", ")
  ..write_object(x2)
  ..write_string(", ")
  ..write_object(x3)
  ..write_string(", ")
  ..write_object(x4)
  ..write_string(", ")
  ..write_object(x5)
  ..write_string(", ")
  ..write_object(x6)
  ..write_string(", ")
  ..write_object(x7)
  ..write_string(", ")
  ..write_object(x8)
  .write_string(")")
}

pub fn to_string[T0 : Show, T1 : Show, T2 : Show, T3 : Show, T4 : Show, T5 : Show, T6 : Show, T7 : Show, T8 : Show](
  self : (T0, T1, T2, T3, T4, T5, T6, T7, T8)
) -> String {
  Show::to_string(self)
}

pub impl[T0 : Show, T1 : Show, T2 : Show, T3 : Show, T4 : Show, T5 : Show, T6 : Show, T7 : Show, T8 : Show, T9 : Show] Show for (
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
) with output(self, logger) {
  let (x0, x1, x2, x3, x4, x5, x6, x7, x8, x9) = self
  logger
  ..write_string("(")
  ..write_object(x0)
  ..write_string(", ")
  ..write_object(x1)
  ..write_string(", ")
  ..write_object(x2)
  ..write_string(", ")
  ..write_object(x3)
  ..write_string(", ")
  ..write_object(x4)
  ..write_string(", ")
  ..write_object(x5)
  ..write_string(", ")
  ..write_object(x6)
  ..write_string(", ")
  ..write_object(x7)
  ..write_string(", ")
  ..write_object(x8)
  ..write_string(", ")
  ..write_object(x9)
  .write_string(")")
}

pub fn to_string[T0 : Show, T1 : Show, T2 : Show, T3 : Show, T4 : Show, T5 : Show, T6 : Show, T7 : Show, T8 : Show, T9 : Show](
  self : (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9)
) -> String {
  Show::to_string(self)
}

pub impl[T0 : Show, T1 : Show, T2 : Show, T3 : Show, T4 : Show, T5 : Show, T6 : Show, T7 : Show, T8 : Show, T9 : Show, T10 : Show] Show for (
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
) with output(self, logger) {
  let (x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10) = self
  logger
  ..write_string("(")
  ..write_object(x0)
  ..write_string(", ")
  ..write_object(x1)
  ..write_string(", ")
  ..write_object(x2)
  ..write_string(", ")
  ..write_object(x3)
  ..write_string(", ")
  ..write_object(x4)
  ..write_string(", ")
  ..write_object(x5)
  ..write_string(", ")
  ..write_object(x6)
  ..write_string(", ")
  ..write_object(x7)
  ..write_string(", ")
  ..write_object(x8)
  ..write_string(", ")
  ..write_object(x9)
  ..write_string(", ")
  ..write_object(x10)
  .write_string(")")
}

pub fn to_string[T0 : Show, T1 : Show, T2 : Show, T3 : Show, T4 : Show, T5 : Show, T6 : Show, T7 : Show, T8 : Show, T9 : Show, T10 : Show](
  self : (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10)
) -> String {
  Show::to_string(self)
}

pub impl[T0 : Show, T1 : Show, T2 : Show, T3 : Show, T4 : Show, T5 : Show, T6 : Show, T7 : Show, T8 : Show, T9 : Show, T10 : Show, T11 : Show] Show for (
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
) with output(self, logger) {
  let (x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11) = self
  logger
  ..write_string("(")
  ..write_object(x0)
  ..write_string(", ")
  ..write_object(x1)
  ..write_string(", ")
  ..write_object(x2)
  ..write_string(", ")
  ..write_object(x3)
  ..write_string(", ")
  ..write_object(x4)
  ..write_string(", ")
  ..write_object(x5)
  ..write_string(", ")
  ..write_object(x6)
  ..write_string(", ")
  ..write_object(x7)
  ..write_string(", ")
  ..write_object(x8)
  ..write_string(", ")
  ..write_object(x9)
  ..write_string(", ")
  ..write_object(x10)
  ..write_string(", ")
  ..write_object(x11)
  .write_string(")")
}

pub fn to_string[T0 : Show, T1 : Show, T2 : Show, T3 : Show, T4 : Show, T5 : Show, T6 : Show, T7 : Show, T8 : Show, T9 : Show, T10 : Show, T11 : Show](
  self : (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11)
) -> String {
  Show::to_string(self)
}

pub impl[T0 : Show, T1 : Show, T2 : Show, T3 : Show, T4 : Show, T5 : Show, T6 : Show, T7 : Show, T8 : Show, T9 : Show, T10 : Show, T11 : Show, T12 : Show] Show for (
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
) with output(self, logger) {
  let (x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12) = self
  logger
  ..write_string("(")
  ..write_object(x0)
  ..write_string(", ")
  ..write_object(x1)
  ..write_string(", ")
  ..write_object(x2)
  ..write_string(", ")
  ..write_object(x3)
  ..write_string(", ")
  ..write_object(x4)
  ..write_string(", ")
  ..write_object(x5)
  ..write_string(", ")
  ..write_object(x6)
  ..write_string(", ")
  ..write_object(x7)
  ..write_string(", ")
  ..write_object(x8)
  ..write_string(", ")
  ..write_object(x9)
  ..write_string(", ")
  ..write_object(x10)
  ..write_string(", ")
  ..write_object(x11)
  ..write_string(", ")
  ..write_object(x12)
  .write_string(")")
}

pub fn to_string[T0 : Show, T1 : Show, T2 : Show, T3 : Show, T4 : Show, T5 : Show, T6 : Show, T7 : Show, T8 : Show, T9 : Show, T10 : Show, T11 : Show, T12 : Show](
  self : (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12)
) -> String {
  Show::to_string(self)
}

pub impl[T0 : Show, T1 : Show, T2 : Show, T3 : Show, T4 : Show, T5 : Show, T6 : Show, T7 : Show, T8 : Show, T9 : Show, T10 : Show, T11 : Show, T12 : Show, T13 : Show] Show for (
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
) with output(self, logger) {
  let (x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13) = self
  logger
  ..write_string("(")
  ..write_object(x0)
  ..write_string(", ")
  ..write_object(x1)
  ..write_string(", ")
  ..write_object(x2)
  ..write_string(", ")
  ..write_object(x3)
  ..write_string(", ")
  ..write_object(x4)
  ..write_string(", ")
  ..write_object(x5)
  ..write_string(", ")
  ..write_object(x6)
  ..write_string(", ")
  ..write_object(x7)
  ..write_string(", ")
  ..write_object(x8)
  ..write_string(", ")
  ..write_object(x9)
  ..write_string(", ")
  ..write_object(x10)
  ..write_string(", ")
  ..write_object(x11)
  ..write_string(", ")
  ..write_object(x12)
  ..write_string(", ")
  ..write_object(x13)
  .write_string(")")
}

pub fn to_string[T0 : Show, T1 : Show, T2 : Show, T3 : Show, T4 : Show, T5 : Show, T6 : Show, T7 : Show, T8 : Show, T9 : Show, T10 : Show, T11 : Show, T12 : Show, T13 : Show](
  self : (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13)
) -> String {
  Show::to_string(self)
}

pub impl[T0 : Show, T1 : Show, T2 : Show, T3 : Show, T4 : Show, T5 : Show, T6 : Show, T7 : Show, T8 : Show, T9 : Show, T10 : Show, T11 : Show, T12 : Show, T13 : Show, T14 : Show] Show for (
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
) with output(self, logger) {
  let (x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14) = self
  logger
  ..write_string("(")
  ..write_object(x0)
  ..write_string(", ")
  ..write_object(x1)
  ..write_string(", ")
  ..write_object(x2)
  ..write_string(", ")
  ..write_object(x3)
  ..write_string(", ")
  ..write_object(x4)
  ..write_string(", ")
  ..write_object(x5)
  ..write_string(", ")
  ..write_object(x6)
  ..write_string(", ")
  ..write_object(x7)
  ..write_string(", ")
  ..write_object(x8)
  ..write_string(", ")
  ..write_object(x9)
  ..write_string(", ")
  ..write_object(x10)
  ..write_string(", ")
  ..write_object(x11)
  ..write_string(", ")
  ..write_object(x12)
  ..write_string(", ")
  ..write_object(x13)
  ..write_string(", ")
  ..write_object(x14)
  .write_string(")")
}

pub fn to_string[T0 : Show, T1 : Show, T2 : Show, T3 : Show, T4 : Show, T5 : Show, T6 : Show, T7 : Show, T8 : Show, T9 : Show, T10 : Show, T11 : Show, T12 : Show, T13 : Show, T14 : Show](
  self : (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14)
) -> String {
  Show::to_string(self)
}

pub impl[T0 : Show, T1 : Show, T2 : Show, T3 : Show, T4 : Show, T5 : Show, T6 : Show, T7 : Show, T8 : Show, T9 : Show, T10 : Show, T11 : Show, T12 : Show, T13 : Show, T14 : Show, T15 : Show] Show for (
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
  logger
  ..write_string("(")
  ..write_object(x0)
  ..write_string(", ")
  ..write_object(x1)
  ..write_string(", ")
  ..write_object(x2)
  ..write_string(", ")
  ..write_object(x3)
  ..write_string(", ")
  ..write_object(x4)
  ..write_string(", ")
  ..write_object(x5)
  ..write_string(", ")
  ..write_object(x6)
  ..write_string(", ")
  ..write_object(x7)
  ..write_string(", ")
  ..write_object(x8)
  ..write_string(", ")
  ..write_object(x9)
  ..write_string(", ")
  ..write_object(x10)
  ..write_string(", ")
  ..write_object(x11)
  ..write_string(", ")
  ..write_object(x12)
  ..write_string(", ")
  ..write_object(x13)
  ..write_string(", ")
  ..write_object(x14)
  ..write_string(", ")
  ..write_object(x15)
  .write_string(")")
}

pub fn to_string[T0 : Show, T1 : Show, T2 : Show, T3 : Show, T4 : Show, T5 : Show, T6 : Show, T7 : Show, T8 : Show, T9 : Show, T10 : Show, T11 : Show, T12 : Show, T13 : Show, T14 : Show, T15 : Show](
  self : (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14, T15)
) -> String {
  Show::to_string(self)
}
