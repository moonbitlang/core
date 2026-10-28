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
#deprecated("Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md")
pub impl[A : Show, B : Show] Show for (A, B)

///|
pub impl[A : Show, B : Show] Show for (A, B) with fn output(self, logger) {
  let (a, b) = self
  logger <+ "(\{a}, \{b})"
}

///|
#deprecated("Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md")
pub impl[A : Show, B : Show, C : Show] Show for (A, B, C)

///|
pub impl[A : Show, B : Show, C : Show] Show for (A, B, C) with fn output(
  self,
  logger,
) {
  let (a, b, c) = self
  logger <+ "(\{a}, \{b}, \{c})"
}

///|
#deprecated("Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md")
pub impl[A : Show, B : Show, C : Show, D : Show] Show for (A, B, C, D)

///|
pub impl[A : Show, B : Show, C : Show, D : Show] Show for (A, B, C, D) with fn output(
  self,
  logger,
) {
  let (a, b, c, d) = self
  logger <+ "(\{a}, \{b}, \{c}, \{d})"
}

///|
#deprecated("Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md")
pub impl[A : Show, B : Show, C : Show, D : Show, E : Show] Show for (
  A,
  B,
  C,
  D,
  E,
)

///|
pub impl[A : Show, B : Show, C : Show, D : Show, E : Show] Show for (
  A,
  B,
  C,
  D,
  E,
) with fn output(self, logger) {
  let (a, b, c, d, e) = self
  logger <+ "(\{a}, \{b}, \{c}, \{d}, \{e})"
}

///|
#deprecated("Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md")
pub impl[A : Show, B : Show, C : Show, D : Show, E : Show, F : Show] Show for (
  A,
  B,
  C,
  D,
  E,
  F,
)

///|
pub impl[A : Show, B : Show, C : Show, D : Show, E : Show, F : Show] Show for (
  A,
  B,
  C,
  D,
  E,
  F,
) with fn output(self, logger) {
  let (a, b, c, d, e, f) = self
  logger <+ "(\{a}, \{b}, \{c}, \{d}, \{e}, \{f})"
}

///|
#deprecated("Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md")
pub impl[A : Show, B : Show, C : Show, D : Show, E : Show, F : Show, G : Show] Show for (
  A,
  B,
  C,
  D,
  E,
  F,
  G,
)

///|
pub impl[A : Show, B : Show, C : Show, D : Show, E : Show, F : Show, G : Show] Show for (
  A,
  B,
  C,
  D,
  E,
  F,
  G,
) with fn output(self, logger) {
  let (a, b, c, d, e, f, g) = self
  logger <+ "(\{a}, \{b}, \{c}, \{d}, \{e}, \{f}, \{g})"
}

///|
#deprecated("Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md")
pub impl[
  T0 : Show,
  T1 : Show,
  T2 : Show,
  T3 : Show,
  T4 : Show,
  T5 : Show,
  T6 : Show,
  T7 : Show,
] Show for (T0, T1, T2, T3, T4, T5, T6, T7)

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
] Show for (T0, T1, T2, T3, T4, T5, T6, T7) with fn output(self, logger) {
  let (x0, x1, x2, x3, x4, x5, x6, x7) = self
  logger <+ "(\{x0}, \{x1}, \{x2}, \{x3}, \{x4}, \{x5}, \{x6}, \{x7})"
}

///|
#deprecated("Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md")
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
] Show for (T0, T1, T2, T3, T4, T5, T6, T7, T8)

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
] Show for (T0, T1, T2, T3, T4, T5, T6, T7, T8) with fn output(self, logger) {
  let (x0, x1, x2, x3, x4, x5, x6, x7, x8) = self
  logger <+ "(\{x0}, \{x1}, \{x2}, \{x3}, \{x4}, \{x5}, \{x6}, \{x7}, \{x8})"
}

///|
#deprecated("Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md")
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
] Show for (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9)

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
] Show for (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9) with fn output(self, logger) {
  let (x0, x1, x2, x3, x4, x5, x6, x7, x8, x9) = self
  logger <+
    "(\{x0}, \{x1}, \{x2}, \{x3}, \{x4}, \{x5}, \{x6}, \{x7}, \{x8}, \{x9})"
}

///|
#deprecated("Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md")
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
] Show for (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10)

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
] Show for (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10) with fn output(
  self,
  logger,
) {
  let (x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10) = self
  logger <+
    "(\{x0}, \{x1}, \{x2}, \{x3}, \{x4}, \{x5}, \{x6}, \{x7}, \{x8}, \{x9}, \{x10})"
}

///|
#deprecated("Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md")
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
] Show for (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11)

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
] Show for (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11) with fn output(
  self,
  logger,
) {
  let (x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11) = self
  logger <+
    "(\{x0}, \{x1}, \{x2}, \{x3}, \{x4}, \{x5}, \{x6}, \{x7}, \{x8}, \{x9}, \{x10}, \{x11})"
}

///|
#deprecated("Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md")
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
] Show for (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12)

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
] Show for (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12) with fn output(
  self,
  logger,
) {
  let (x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12) = self
  logger <+
    "(\{x0}, \{x1}, \{x2}, \{x3}, \{x4}, \{x5}, \{x6}, \{x7}, \{x8}, \{x9}, \{x10}, \{x11}, \{x12})"
}

///|
#deprecated("Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md")
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
] Show for (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13)

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
] Show for (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13) with fn output(
  self,
  logger,
) {
  let (x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13) = self
  logger <+
    "(\{x0}, \{x1}, \{x2}, \{x3}, \{x4}, \{x5}, \{x6}, \{x7}, \{x8}, \{x9}, \{x10}, \{x11}, \{x12}, \{x13})"
}

///|
#deprecated("Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md")
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
] Show for (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14)

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
] Show for (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14) with fn output(
  self,
  logger,
) {
  let (x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14) = self
  logger <+
    "(\{x0}, \{x1}, \{x2}, \{x3}, \{x4}, \{x5}, \{x6}, \{x7}, \{x8}, \{x9}, \{x10}, \{x11}, \{x12}, \{x13}, \{x14})"
}

///|
#deprecated("Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md")
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
)

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
) with fn output(self, logger) {
  let (x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15) = self
  logger <+
    "(\{x0}, \{x1}, \{x2}, \{x3}, \{x4}, \{x5}, \{x6}, \{x7}, \{x8}, \{x9}, \{x10}, \{x11}, \{x12}, \{x13}, \{x14}, \{x15})"
}
