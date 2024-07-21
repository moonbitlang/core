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
  logger.write_string("(")
  a.output(logger)
  logger.write_string(", ")
  b.output(logger)
  logger.write_string(")")
}

pub fn to_string[A : Show, B : Show](self : (A, B)) -> String {
  Show::to_string(self)
}

pub impl[A : Show, B : Show, C : Show] Show for (A, B, C) with output(
  self,
  logger
) {
  let (a, b, c) = self
  logger.write_string("(")
  a.output(logger)
  logger.write_string(", ")
  b.output(logger)
  logger.write_string(", ")
  c.output(logger)
  logger.write_string(")")
}

pub fn to_string[A : Show, B : Show, C : Show](self : (A, B, C)) -> String {
  Show::to_string(self)
}

pub impl[A : Show, B : Show, C : Show, D : Show] Show for (A, B, C, D) with output(
  self,
  logger
) {
  let (a, b, c, d) = self
  logger.write_string("(")
  a.output(logger)
  logger.write_string(", ")
  b.output(logger)
  logger.write_string(", ")
  c.output(logger)
  logger.write_string(", ")
  d.output(logger)
  logger.write_string(")")
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
  logger.write_string("(")
  a.output(logger)
  logger.write_string(", ")
  b.output(logger)
  logger.write_string(", ")
  c.output(logger)
  logger.write_string(", ")
  d.output(logger)
  logger.write_string(", ")
  e.output(logger)
  logger.write_string(")")
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
  logger.write_string("(")
  a.output(logger)
  logger.write_string(", ")
  b.output(logger)
  logger.write_string(", ")
  c.output(logger)
  logger.write_string(", ")
  d.output(logger)
  logger.write_string(", ")
  e.output(logger)
  logger.write_string(", ")
  f.output(logger)
  logger.write_string(")")
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
  logger.write_string("(")
  a.output(logger)
  logger.write_string(", ")
  b.output(logger)
  logger.write_string(", ")
  c.output(logger)
  logger.write_string(", ")
  d.output(logger)
  logger.write_string(", ")
  e.output(logger)
  logger.write_string(", ")
  f.output(logger)
  logger.write_string(", ")
  g.output(logger)
  logger.write_string(")")
}

pub fn to_string[A : Show, B : Show, C : Show, D : Show, E : Show, F : Show, G : Show](
  self : (A, B, C, D, E, F, G)
) -> String {
  Show::to_string(self)
}
