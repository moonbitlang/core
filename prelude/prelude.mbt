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
pub typealias @builtin.(
  ArgsLoc,
  Array[X],
  ArrayView[X],
  UninitializedArray[X],
  BigInt,
  Failure,
  Hasher,
  Iter[X],
  Iter2[X, Y],
  IterResult,
  Json,
  Map[K, V],
  Set[X],
  InspectError,
  SnapshotError,
  SourceLoc,
  StringBuilder
)

///|
pub traitalias @builtin.(Eq, Compare, Hash, Logger, Show, ToJson, Default)

///|
pub fnalias @builtin.(
  abort,
  assert_eq,
  assert_not_eq,
  assert_true,
  assert_false,
  fail,
  ignore,
  inspect,
  panic,
  physical_equal,
  println,
  not,
  repr,
  dump
)
