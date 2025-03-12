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
pub fnalias abort = @builtin.abort

///|
pub fnalias assert_eq = @builtin.assert_eq

///|
pub fnalias assert_not_eq = @builtin.assert_not_eq

///|
pub fnalias assert_true = @builtin.assert_true

///|
pub fnalias assert_false = @builtin.assert_false

///|
pub fnalias fail = @builtin.fail

///|
pub fnalias ignore = @builtin.ignore

///|
pub fnalias inspect = @builtin.inspect

///|
pub fnalias panic = @builtin.panic

///|
pub fnalias physical_equal = @builtin.physical_equal

///|
pub fnalias println = @builtin.println

///|
pub fnalias not = @builtin.not

///|
pub fnalias repr = @builtin.repr

///|
pub fnalias dump = @builtin.dump
