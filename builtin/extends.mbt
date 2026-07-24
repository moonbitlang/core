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

// Private aliases so tuple extends can name the (unnameable) tuple types.

///|
type Tuple2[A, B] = (A, B)

///|
type Tuple3[A, B, C] = (A, B, C)

///|
type Tuple4[A, B, C, D] = (A, B, C, D)

///|
type Tuple5[A, B, C, D, E] = (A, B, C, D, E)

///|
type Tuple6[A, B, C, D, E, F] = (A, B, C, D, E, F)

///|
type Tuple7[A, B, C, D, E, F, G] = (A, B, C, D, E, F, G)

///|
type Tuple8[A, B, C, D, E, F, G, H] = (A, B, C, D, E, F, G, H)

///|
type Tuple9[A, B, C, D, E, F, G, H, I] = (A, B, C, D, E, F, G, H, I)

///|
type Tuple10[A, B, C, D, E, F, G, H, I, J] = (A, B, C, D, E, F, G, H, I, J)

///|
type Tuple11[A, B, C, D, E, F, G, H, I, J, K] = (
  A,
  B,
  C,
  D,
  E,
  F,
  G,
  H,
  I,
  J,
  K,
)

///|
type Tuple12[A, B, C, D, E, F, G, H, I, J, K, L] = (
  A,
  B,
  C,
  D,
  E,
  F,
  G,
  H,
  I,
  J,
  K,
  L,
)

///|
type Tuple13[A, B, C, D, E, F, G, H, I, J, K, L, M] = (
  A,
  B,
  C,
  D,
  E,
  F,
  G,
  H,
  I,
  J,
  K,
  L,
  M,
)

///|
type Tuple14[A, B, C, D, E, F, G, H, I, J, K, L, M, N] = (
  A,
  B,
  C,
  D,
  E,
  F,
  G,
  H,
  I,
  J,
  K,
  L,
  M,
  N,
)

///|
type Tuple15[A, B, C, D, E, F, G, H, I, J, K, L, M, N, O] = (
  A,
  B,
  C,
  D,
  E,
  F,
  G,
  H,
  I,
  J,
  K,
  L,
  M,
  N,
  O,
)

///|
type Tuple16[A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P] = (
  A,
  B,
  C,
  D,
  E,
  F,
  G,
  H,
  I,
  J,
  K,
  L,
  M,
  N,
  O,
  P,
)

// --- promoted: kept as regular methods (blessed public API) ---

///|
pub extend ArgsLoc with Show::{to_string}

///|
pub extend Array with Add::{add}

///|
pub extend Array with Compare::{compare}

///|
pub extend Array with Eq::{equal, not_equal}

///|
pub extend Array with Hash::{hash}

///|
pub extend Array with ToJson::{to_json}

///|
pub extend ArrayView with Add::{add}

///|
pub extend ArrayView with Compare::{compare}

///|
pub extend ArrayView with Eq::{equal, not_equal}

///|
pub extend ArrayView with Hash::{hash}

///|
pub extend ArrayView with ToJson::{to_json}

///|
pub extend Bool with Compare::{compare}

///|
pub extend Bool with Eq::{equal, not_equal}

///|
pub extend Bool with Hash::{hash}

///|
pub extend Bool with Show::{to_string}

///|
pub extend Bool with ToJson::{to_json}

///|
pub extend Byte with Add::{add}

///|
pub extend Byte with BitAnd::{land}

///|
pub extend Byte with BitOr::{lor}

///|
pub extend Byte with BitXOr::{lxor}

///|
pub extend Byte with Compare::{compare}

// `Byte::default()` is kept promoted (not deprecated) for now: Moon's generated
// test drivers call `FixedArray::make(512, Byte::default())`, so deprecating it
// breaks `moon test --build-only --deny-warn`. moonbitlang/moon#1938 removes that
// call; deprecate this (like the other `Default`s) once a moon release with it ships.

///|
pub extend Byte with Default::{default}

///|
pub extend Byte with Div::{div}

///|
pub extend Byte with Eq::{equal, not_equal}

///|
pub extend Byte with Hash::{hash}

///|
pub extend Byte with Mod::{mod}

///|
pub extend Byte with Mul::{mul}

///|
pub extend Byte with Shl::{shl}

///|
pub extend Byte with Shr::{shr}

///|
pub extend Byte with Sub::{sub}

///|
pub extend Byte with ToJson::{to_json}

///|
pub extend Bytes with Add::{add}

///|
pub extend Bytes with Compare::{compare}

///|
pub extend Bytes with Eq::{equal, not_equal}

///|
pub extend Bytes with Hash::{hash}

///|
pub extend Bytes with Show::{to_string}

///|
pub extend Bytes with ToJson::{to_json}

///|
pub extend BytesView with Compare::{compare}

///|
pub extend BytesView with Eq::{equal, not_equal}

///|
pub extend BytesView with Hash::{hash}

///|
pub extend BytesView with Show::{to_string}

///|
pub extend BytesView with ToJson::{to_json}

///|
pub extend Char with Compare::{compare}

///|
pub extend Char with Eq::{equal, not_equal}

///|
pub extend Char with Hash::{hash}

///|
pub extend Char with Show::{to_string}

///|
pub extend Char with ToJson::{to_json}

///|
pub extend Double with Add::{add}

///|
pub extend Double with Compare::{compare}

///|
pub extend Double with Div::{div}

///|
pub extend Double with Eq::{equal, not_equal}

///|
pub extend Double with Hash::{hash}

///|
pub extend Double with Mod::{mod}

///|
pub extend Double with Mul::{mul}

///|
pub extend Double with Neg::{neg}

///|
pub extend Double with Sub::{sub}

///|
pub extend Double with ToJson::{to_json}

///|
pub extend Failure with Show::{to_string}

///|
pub extend Failure with ToJson::{to_json}

///|
pub extend FixedArray with Add::{add}

///|
pub extend FixedArray with Compare::{compare}

///|
pub extend FixedArray with Eq::{equal, not_equal}

///|
pub extend FixedArray with Hash::{hash}

///|
pub extend FixedArray with ToJson::{to_json}

///|
pub extend Int with Add::{add}

///|
pub extend Int with BitAnd::{land}

///|
pub extend Int with BitOr::{lor}

///|
pub extend Int with BitXOr::{lxor}

///|
pub extend Int with Compare::{compare}

///|
pub extend Int with Div::{div}

///|
pub extend Int with Eq::{equal, not_equal}

///|
pub extend Int with Hash::{hash}

///|
pub extend Int with Mod::{mod}

///|
pub extend Int with Mul::{mul}

///|
pub extend Int with Neg::{neg}

///|
pub extend Int with Sub::{sub}

///|
pub extend Int with ToJson::{to_json}

///|
pub extend Int64 with Add::{add}

///|
pub extend Int64 with BitAnd::{land}

///|
pub extend Int64 with BitOr::{lor}

///|
pub extend Int64 with BitXOr::{lxor}

///|
pub extend Int64 with Compare::{compare}

///|
pub extend Int64 with Div::{div}

///|
pub extend Int64 with Eq::{equal, not_equal}

///|
pub extend Int64 with Hash::{hash}

///|
pub extend Int64 with Mod::{mod}

///|
pub extend Int64 with Mul::{mul}

///|
pub extend Int64 with Neg::{neg}

///|
pub extend Int64 with Sub::{sub}

///|
pub extend Int64 with ToJson::{to_json}

///|
pub extend Iter with Add::{add}

///|
pub extend Iter with ToJson::{to_json}

///|
pub extend Json with Eq::{equal, not_equal}

///|
pub extend Map with Eq::{equal, not_equal}

///|
pub extend Map with ToJson::{to_json}

///|
pub extend MutArrayView with Compare::{compare}

///|
pub extend MutArrayView with Eq::{equal, not_equal}

///|
pub extend MutArrayView with Hash::{hash}

///|
pub extend Option with Compare::{compare}

///|
pub extend Option with Eq::{equal, not_equal}

///|
pub extend Option with Hash::{hash}

///|
pub extend Option with ToJson::{to_json}

///|
pub extend ReadOnlyArray with Compare::{compare}

///|
pub extend ReadOnlyArray with Eq::{equal, not_equal}

///|
pub extend ReadOnlyArray with Hash::{hash}

///|
pub extend ReadOnlyArray with ToJson::{to_json}

///|
pub extend Result with Compare::{compare}

///|
pub extend Result with Eq::{equal, not_equal}

///|
pub extend Result with Hash::{hash}

///|
pub extend Result with ToJson::{to_json}

///|
pub extend SourceLoc with Show::{to_string}

///|
pub extend String with Add::{add}

///|
pub extend String with Compare::{compare}

///|
pub extend String with Eq::{equal, not_equal}

///|
pub extend String with Hash::{hash}

///|
pub extend String with Show::{to_string}

///|
pub extend String with ToJson::{to_json}

///|
pub extend String with ToStringView::{to_string_view}

///|
pub extend StringBuilder with Logger::{
  write_char,
  write_string,
  write_substring,
  write_view,
}

///|
pub extend StringView with Add::{add}

///|
pub extend StringView with Compare::{compare}

///|
pub extend StringView with Eq::{equal, not_equal}

///|
pub extend StringView with Hash::{hash}

///|
pub extend StringView with ToJson::{to_json}

///|
pub extend StringView with ToStringView::{to_string_view}

///|
#doc(hidden)
pub extend Tuple10 with Compare::{compare}

///|
#doc(hidden)
pub extend Tuple10 with Eq::{equal, not_equal}

///|
#doc(hidden)
pub extend Tuple11 with Compare::{compare}

///|
#doc(hidden)
pub extend Tuple11 with Eq::{equal, not_equal}

///|
#doc(hidden)
pub extend Tuple12 with Compare::{compare}

///|
#doc(hidden)
pub extend Tuple12 with Eq::{equal, not_equal}

///|
#doc(hidden)
pub extend Tuple13 with Compare::{compare}

///|
#doc(hidden)
pub extend Tuple13 with Eq::{equal, not_equal}

///|
#doc(hidden)
pub extend Tuple14 with Compare::{compare}

///|
#doc(hidden)
pub extend Tuple14 with Eq::{equal, not_equal}

///|
#doc(hidden)
pub extend Tuple15 with Compare::{compare}

///|
#doc(hidden)
pub extend Tuple15 with Eq::{equal, not_equal}

///|
#doc(hidden)
pub extend Tuple16 with Compare::{compare}

///|
#doc(hidden)
pub extend Tuple16 with Eq::{equal, not_equal}

///|
#doc(hidden)
pub extend Tuple2 with Compare::{compare}

///|
#doc(hidden)
pub extend Tuple2 with Eq::{equal, not_equal}

///|
#doc(hidden)
pub extend Tuple2 with Hash::{hash}

///|
#doc(hidden)
pub extend Tuple3 with Compare::{compare}

///|
#doc(hidden)
pub extend Tuple3 with Eq::{equal, not_equal}

///|
#doc(hidden)
pub extend Tuple3 with Hash::{hash}

///|
#doc(hidden)
pub extend Tuple4 with Compare::{compare}

///|
#doc(hidden)
pub extend Tuple4 with Eq::{equal, not_equal}

///|
#doc(hidden)
pub extend Tuple4 with Hash::{hash}

///|
#doc(hidden)
pub extend Tuple5 with Compare::{compare}

///|
#doc(hidden)
pub extend Tuple5 with Eq::{equal, not_equal}

///|
#doc(hidden)
pub extend Tuple5 with Hash::{hash}

///|
#doc(hidden)
pub extend Tuple6 with Compare::{compare}

///|
#doc(hidden)
pub extend Tuple6 with Eq::{equal, not_equal}

///|
#doc(hidden)
pub extend Tuple6 with Hash::{hash}

///|
#doc(hidden)
pub extend Tuple7 with Compare::{compare}

///|
#doc(hidden)
pub extend Tuple7 with Eq::{equal, not_equal}

///|
#doc(hidden)
pub extend Tuple7 with Hash::{hash}

///|
#doc(hidden)
pub extend Tuple8 with Compare::{compare}

///|
#doc(hidden)
pub extend Tuple8 with Eq::{equal, not_equal}

///|
#doc(hidden)
pub extend Tuple9 with Compare::{compare}

///|
#doc(hidden)
pub extend Tuple9 with Eq::{equal, not_equal}

///|
pub extend UInt with Add::{add}

///|
pub extend UInt with BitAnd::{land}

///|
pub extend UInt with BitOr::{lor}

///|
pub extend UInt with BitXOr::{lxor}

///|
pub extend UInt with Compare::{compare}

///|
pub extend UInt with Div::{div}

///|
pub extend UInt with Eq::{equal, not_equal}

///|
pub extend UInt with Hash::{hash}

///|
pub extend UInt with Mod::{mod}

///|
pub extend UInt with Mul::{mul}

///|
pub extend UInt with Sub::{sub}

///|
pub extend UInt with ToJson::{to_json}

///|
pub extend UInt16 with Add::{add}

///|
pub extend UInt16 with BitAnd::{land}

///|
pub extend UInt16 with BitOr::{lor}

///|
pub extend UInt16 with BitXOr::{lxor}

///|
pub extend UInt16 with Compare::{compare}

///|
pub extend UInt16 with Div::{div}

///|
pub extend UInt16 with Eq::{equal, not_equal}

///|
pub extend UInt16 with Hash::{hash}

///|
pub extend UInt16 with Mod::{mod}

///|
pub extend UInt16 with Mul::{mul}

///|
pub extend UInt16 with Shl::{shl}

///|
pub extend UInt16 with Shr::{shr}

///|
pub extend UInt16 with Sub::{sub}

///|
pub extend UInt16 with ToJson::{to_json}

///|
pub extend UInt64 with Add::{add}

///|
pub extend UInt64 with BitAnd::{land}

///|
pub extend UInt64 with BitOr::{lor}

///|
pub extend UInt64 with BitXOr::{lxor}

///|
pub extend UInt64 with Compare::{compare}

///|
pub extend UInt64 with Div::{div}

///|
pub extend UInt64 with Eq::{equal, not_equal}

///|
pub extend UInt64 with Hash::{hash}

///|
pub extend UInt64 with Mod::{mod}

///|
pub extend UInt64 with Mul::{mul}

///|
pub extend UInt64 with Sub::{sub}

///|
pub extend UInt64 with ToJson::{to_json}

///|
pub extend Unit with Compare::{compare}

///|
pub extend Unit with Eq::{equal, not_equal}

///|
pub extend Unit with Hash::{hash}

///|
pub extend Unit with Show::{to_string}

///|
pub extend Unit with ToJson::{to_json}

// --- deprecated: hidden from the generated interface ---

///|
#deprecated("Use `Show::output` via the trait or `to_string` instead", skip_current_package=true)
#doc(hidden)
pub extend ArgsLoc with Show::{output}

///|
#deprecated("Use the comparison operators (`<`, `<=`, `>=`, `>`) instead", skip_current_package=true)
#doc(hidden)
pub extend Array with Compare::{op_lt, op_le, op_ge, op_gt}

///|
#deprecated("Use `Default::default` instead", skip_current_package=true)
#doc(hidden)
pub extend Array with Default::{default}

///|
#deprecated("Use `Hash::hash_combine` instead", skip_current_package=true)
#doc(hidden)
pub extend Array with Hash::{hash_combine}

///|
#deprecated("Use `@debug.Debug` instead of `Show` for collections", skip_current_package=true)
#doc(hidden)
pub extend Array with Show::{to_string, output}

///|
#deprecated("Use the comparison operators (`<`, `<=`, `>=`, `>`) instead", skip_current_package=true)
#doc(hidden)
pub extend ArrayView with Compare::{op_lt, op_le, op_ge, op_gt}

///|
#deprecated("Use `Hash::hash_combine` instead", skip_current_package=true)
#doc(hidden)
pub extend ArrayView with Hash::{hash_combine}

///|
#deprecated("Use `@debug.Debug` instead of `Show` for collections", skip_current_package=true)
#doc(hidden)
pub extend ArrayView with Show::{to_string, output}

///|
#deprecated("Use the comparison operators (`<`, `<=`, `>=`, `>`) instead", skip_current_package=true)
#doc(hidden)
pub extend Bool with Compare::{op_lt, op_le, op_ge, op_gt}

///|
#deprecated("Use `Default::default` instead", skip_current_package=true)
#doc(hidden)
pub extend Bool with Default::{default}

///|
#deprecated("Use `Hash::hash_combine` instead", skip_current_package=true)
#doc(hidden)
pub extend Bool with Hash::{hash_combine}

///|
#deprecated("Use `Show::output` via the trait or `to_string` instead", skip_current_package=true)
#doc(hidden)
pub extend Bool with Show::{output}

///|
#deprecated("Use the comparison operators (`<`, `<=`, `>=`, `>`) instead", skip_current_package=true)
#doc(hidden)
pub extend Byte with Compare::{op_lt, op_le, op_ge, op_gt}

///|
#deprecated("Use `Hash::hash_combine` instead", skip_current_package=true)
#doc(hidden)
pub extend Byte with Hash::{hash_combine}

///|
#deprecated("Use `Show::output` via the trait or `to_string` instead", skip_current_package=true)
#doc(hidden)
pub extend Byte with Show::{output}

///|
#deprecated("Use the comparison operators (`<`, `<=`, `>=`, `>`) instead", skip_current_package=true)
#doc(hidden)
pub extend Bytes with Compare::{op_lt, op_le, op_ge, op_gt}

///|
#deprecated("Use `Default::default` instead", skip_current_package=true)
#doc(hidden)
pub extend Bytes with Default::{default}

///|
#deprecated("Use `Hash::hash_combine` instead", skip_current_package=true)
#doc(hidden)
pub extend Bytes with Hash::{hash_combine}

///|
#deprecated("Use `Show::output` via the trait or `to_string` instead", skip_current_package=true)
#doc(hidden)
pub extend Bytes with Show::{output}

///|
#deprecated("Use the comparison operators (`<`, `<=`, `>=`, `>`) instead", skip_current_package=true)
#doc(hidden)
pub extend BytesView with Compare::{op_lt, op_le, op_ge, op_gt}

///|
#deprecated("Use `Hash::hash_combine` instead", skip_current_package=true)
#doc(hidden)
pub extend BytesView with Hash::{hash_combine}

///|
#deprecated("Use `Show::output` via the trait or `to_string` instead", skip_current_package=true)
#doc(hidden)
pub extend BytesView with Show::{output}

///|
#deprecated("Use the comparison operators (`<`, `<=`, `>=`, `>`) instead", skip_current_package=true)
#doc(hidden)
pub extend Char with Compare::{op_lt, op_le, op_ge, op_gt}

///|
#deprecated("Use `Default::default` instead", skip_current_package=true)
#doc(hidden)
pub extend Char with Default::{default}

///|
#deprecated("Use `Hash::hash_combine` instead", skip_current_package=true)
#doc(hidden)
pub extend Char with Hash::{hash_combine}

///|
#deprecated("Use `Show::output` via the trait or `to_string` instead", skip_current_package=true)
#doc(hidden)
pub extend Char with Show::{output}

///|
#deprecated("Use the comparison operators (`<`, `<=`, `>=`, `>`) instead", skip_current_package=true)
#doc(hidden)
pub extend Double with Compare::{op_lt, op_le, op_ge, op_gt}

///|
#deprecated("Use `Default::default` instead", skip_current_package=true)
#doc(hidden)
pub extend Double with Default::{default}

///|
#deprecated("Use `Hash::hash_combine` instead", skip_current_package=true)
#doc(hidden)
pub extend Double with Hash::{hash_combine}

///|
#deprecated("Use `Show::output` via the trait or `to_string` instead", skip_current_package=true)
#doc(hidden)
pub extend Double with Show::{output}

///|
#deprecated("Use `Show::output` via the trait or `to_string` instead", skip_current_package=true)
#doc(hidden)
pub extend Failure with Show::{output}

///|
#deprecated("Use the comparison operators (`<`, `<=`, `>=`, `>`) instead", skip_current_package=true)
#doc(hidden)
pub extend FixedArray with Compare::{op_lt, op_le, op_ge, op_gt}

///|
#deprecated("Use `Default::default` instead", skip_current_package=true)
#doc(hidden)
pub extend FixedArray with Default::{default}

///|
#deprecated("Use `Hash::hash_combine` instead", skip_current_package=true)
#doc(hidden)
pub extend FixedArray with Hash::{hash_combine}

///|
#deprecated("Use `@debug.Debug` instead of `Show` for collections", skip_current_package=true)
#doc(hidden)
pub extend FixedArray with Show::{to_string, output}

///|
#deprecated("Use the comparison operators (`<`, `<=`, `>=`, `>`) instead", skip_current_package=true)
#doc(hidden)
pub extend Int with Compare::{op_lt, op_le, op_ge, op_gt}

///|
#deprecated("Use `Default::default` instead", skip_current_package=true)
#doc(hidden)
pub extend Int with Default::{default}

///|
#deprecated("Use `Hash::hash_combine` instead", skip_current_package=true)
#doc(hidden)
pub extend Int with Hash::{hash_combine}

///|
#deprecated("Use `Show::output` via the trait or `to_string` instead", skip_current_package=true)
#doc(hidden)
pub extend Int with Show::{output}

///|
#deprecated("Use the comparison operators (`<`, `<=`, `>=`, `>`) instead", skip_current_package=true)
#doc(hidden)
pub extend Int64 with Compare::{op_lt, op_le, op_ge, op_gt}

///|
#deprecated("Use `Default::default` instead", skip_current_package=true)
#doc(hidden)
pub extend Int64 with Default::{default}

///|
#deprecated("Use `Hash::hash_combine` instead", skip_current_package=true)
#doc(hidden)
pub extend Int64 with Hash::{hash_combine}

///|
#deprecated("Use `Show::output` via the trait or `to_string` instead", skip_current_package=true)
#doc(hidden)
pub extend Int64 with Show::{output}

///|
#deprecated("Use `@debug.Debug` instead of `Show` for collections", skip_current_package=true)
#doc(hidden)
pub extend Iter with Show::{to_string, output}

///|
#deprecated("Use `@debug.Debug` instead of `Show` for collections", skip_current_package=true)
#doc(hidden)
pub extend Iter2 with Show::{to_string, output}

///|
#deprecated("Use `Default::default` instead", skip_current_package=true)
#doc(hidden)
pub extend Json with Default::{default}

///|
#deprecated("Use `Default::default` instead", skip_current_package=true)
#doc(hidden)
pub extend Map with Default::{default}

///|
#deprecated("Use `@debug.Debug` instead of `Show` for collections", skip_current_package=true)
#doc(hidden)
pub extend Map with Show::{to_string, output}

///|
#deprecated("Use the comparison operators (`<`, `<=`, `>=`, `>`) instead", skip_current_package=true)
#doc(hidden)
pub extend MutArrayView with Compare::{op_lt, op_le, op_ge, op_gt}

///|
#deprecated("Use `Hash::hash_combine` instead", skip_current_package=true)
#doc(hidden)
pub extend MutArrayView with Hash::{hash_combine}

///|
#deprecated("Use `@debug.Debug` instead of `Show` for collections", skip_current_package=true)
#doc(hidden)
pub extend MutArrayView with Show::{to_string, output}

///|
#deprecated("Use the comparison operators (`<`, `<=`, `>=`, `>`) instead", skip_current_package=true)
#doc(hidden)
pub extend Option with Compare::{op_lt, op_le, op_ge, op_gt}

///|
#deprecated("Use `Default::default` instead", skip_current_package=true)
#doc(hidden)
pub extend Option with Default::{default}

///|
#deprecated("Use `Hash::hash_combine` instead", skip_current_package=true)
#doc(hidden)
pub extend Option with Hash::{hash_combine}

///|
#deprecated("Use `Show::output` via the trait or `to_string` instead", skip_current_package=true)
#doc(hidden)
pub extend Option with Show::{output}

///|
#deprecated("Use the comparison operators (`<`, `<=`, `>=`, `>`) instead", skip_current_package=true)
#doc(hidden)
pub extend ReadOnlyArray with Compare::{op_lt, op_le, op_ge, op_gt}

///|
#deprecated("Use `Default::default` instead", skip_current_package=true)
#doc(hidden)
pub extend ReadOnlyArray with Default::{default}

///|
#deprecated("Use `Hash::hash_combine` instead", skip_current_package=true)
#doc(hidden)
pub extend ReadOnlyArray with Hash::{hash_combine}

///|
#deprecated("Use `@debug.Debug` instead of `Show` for collections", skip_current_package=true)
#doc(hidden)
pub extend ReadOnlyArray with Show::{to_string, output}

///|
#deprecated("Use the comparison operators (`<`, `<=`, `>=`, `>`) instead", skip_current_package=true)
#doc(hidden)
pub extend Result with Compare::{op_lt, op_le, op_ge, op_gt}

///|
#deprecated("Use `Hash::hash_combine` instead", skip_current_package=true)
#doc(hidden)
pub extend Result with Hash::{hash_combine}

///|
#deprecated("Use `@debug.Debug` instead of `Show` for collections", skip_current_package=true)
#doc(hidden)
pub extend Result with Show::{to_string, output}

///|
#deprecated("Use `Show::output` via the trait or `to_string` instead", skip_current_package=true)
#doc(hidden)
pub extend SourceLoc with Show::{output}

///|
#deprecated("Use the comparison operators (`<`, `<=`, `>=`, `>`) instead", skip_current_package=true)
#doc(hidden)
pub extend String with Compare::{op_lt, op_le, op_ge, op_gt}

///|
#deprecated("Use `Default::default` instead", skip_current_package=true)
#doc(hidden)
pub extend String with Default::{default}

///|
#deprecated("Use `Hash::hash_combine` instead", skip_current_package=true)
#doc(hidden)
pub extend String with Hash::{hash_combine}

///|
#deprecated("Use `Show::output` via the trait or `to_string` instead", skip_current_package=true)
#doc(hidden)
pub extend String with Show::{output}

///|
#deprecated("Use `Show::output` via the trait or `to_string` instead", skip_current_package=true)
#doc(hidden)
pub extend StringBuilder with Show::{output}

///|
#deprecated("Use the comparison operators (`<`, `<=`, `>=`, `>`) instead", skip_current_package=true)
#doc(hidden)
pub extend StringView with Compare::{op_lt, op_le, op_ge, op_gt}

///|
#deprecated("Use `Default::default` instead", skip_current_package=true)
#doc(hidden)
pub extend StringView with Default::{default}

///|
#deprecated("Use `Hash::hash_combine` instead", skip_current_package=true)
#doc(hidden)
pub extend StringView with Hash::{hash_combine}

///|
#deprecated("Use `Show::output` via the trait or `to_string` instead", skip_current_package=true)
#doc(hidden)
pub extend StringView with Show::{output}

///|
#deprecated("Use the comparison operators (`<`, `<=`, `>=`, `>`) instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple10 with Compare::{op_lt, op_le, op_ge, op_gt}

///|
#deprecated("Use `@debug.Debug` instead of `Show` for collections", skip_current_package=true)
#doc(hidden)
pub extend Tuple10 with Show::{to_string, output}

///|
#deprecated("Use `ToJson::to_json` instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple10 with ToJson::{to_json}

///|
#deprecated("Use the comparison operators (`<`, `<=`, `>=`, `>`) instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple11 with Compare::{op_lt, op_le, op_ge, op_gt}

///|
#deprecated("Use `@debug.Debug` instead of `Show` for collections", skip_current_package=true)
#doc(hidden)
pub extend Tuple11 with Show::{to_string, output}

///|
#deprecated("Use `ToJson::to_json` instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple11 with ToJson::{to_json}

///|
#deprecated("Use the comparison operators (`<`, `<=`, `>=`, `>`) instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple12 with Compare::{op_lt, op_le, op_ge, op_gt}

///|
#deprecated("Use `@debug.Debug` instead of `Show` for collections", skip_current_package=true)
#doc(hidden)
pub extend Tuple12 with Show::{to_string, output}

///|
#deprecated("Use `ToJson::to_json` instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple12 with ToJson::{to_json}

///|
#deprecated("Use the comparison operators (`<`, `<=`, `>=`, `>`) instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple13 with Compare::{op_lt, op_le, op_ge, op_gt}

///|
#deprecated("Use `@debug.Debug` instead of `Show` for collections", skip_current_package=true)
#doc(hidden)
pub extend Tuple13 with Show::{to_string, output}

///|
#deprecated("Use `ToJson::to_json` instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple13 with ToJson::{to_json}

///|
#deprecated("Use the comparison operators (`<`, `<=`, `>=`, `>`) instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple14 with Compare::{op_lt, op_le, op_ge, op_gt}

///|
#deprecated("Use `@debug.Debug` instead of `Show` for collections", skip_current_package=true)
#doc(hidden)
pub extend Tuple14 with Show::{to_string, output}

///|
#deprecated("Use `ToJson::to_json` instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple14 with ToJson::{to_json}

///|
#deprecated("Use the comparison operators (`<`, `<=`, `>=`, `>`) instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple15 with Compare::{op_lt, op_le, op_ge, op_gt}

///|
#deprecated("Use `@debug.Debug` instead of `Show` for collections", skip_current_package=true)
#doc(hidden)
pub extend Tuple15 with Show::{to_string, output}

///|
#deprecated("Use `ToJson::to_json` instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple15 with ToJson::{to_json}

///|
#deprecated("Use the comparison operators (`<`, `<=`, `>=`, `>`) instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple16 with Compare::{op_lt, op_le, op_ge, op_gt}

///|
#deprecated("Use `@debug.Debug` instead of `Show` for collections", skip_current_package=true)
#doc(hidden)
pub extend Tuple16 with Show::{to_string, output}

///|
#deprecated("Use `ToJson::to_json` instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple16 with ToJson::{to_json}

///|
#deprecated("Use the comparison operators (`<`, `<=`, `>=`, `>`) instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple2 with Compare::{op_lt, op_le, op_ge, op_gt}

///|
#deprecated("Use `Hash::hash_combine` instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple2 with Hash::{hash_combine}

///|
#deprecated("Use `@debug.Debug` instead of `Show` for collections", skip_current_package=true)
#doc(hidden)
pub extend Tuple2 with Show::{to_string, output}

///|
#deprecated("Use `ToJson::to_json` instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple2 with ToJson::{to_json}

///|
#deprecated("Use the comparison operators (`<`, `<=`, `>=`, `>`) instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple3 with Compare::{op_lt, op_le, op_ge, op_gt}

///|
#deprecated("Use `Hash::hash_combine` instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple3 with Hash::{hash_combine}

///|
#deprecated("Use `@debug.Debug` instead of `Show` for collections", skip_current_package=true)
#doc(hidden)
pub extend Tuple3 with Show::{to_string, output}

///|
#deprecated("Use `ToJson::to_json` instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple3 with ToJson::{to_json}

///|
#deprecated("Use the comparison operators (`<`, `<=`, `>=`, `>`) instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple4 with Compare::{op_lt, op_le, op_ge, op_gt}

///|
#deprecated("Use `Hash::hash_combine` instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple4 with Hash::{hash_combine}

///|
#deprecated("Use `@debug.Debug` instead of `Show` for collections", skip_current_package=true)
#doc(hidden)
pub extend Tuple4 with Show::{to_string, output}

///|
#deprecated("Use `ToJson::to_json` instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple4 with ToJson::{to_json}

///|
#deprecated("Use the comparison operators (`<`, `<=`, `>=`, `>`) instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple5 with Compare::{op_lt, op_le, op_ge, op_gt}

///|
#deprecated("Use `Hash::hash_combine` instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple5 with Hash::{hash_combine}

///|
#deprecated("Use `@debug.Debug` instead of `Show` for collections", skip_current_package=true)
#doc(hidden)
pub extend Tuple5 with Show::{to_string, output}

///|
#deprecated("Use `ToJson::to_json` instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple5 with ToJson::{to_json}

///|
#deprecated("Use the comparison operators (`<`, `<=`, `>=`, `>`) instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple6 with Compare::{op_lt, op_le, op_ge, op_gt}

///|
#deprecated("Use `Hash::hash_combine` instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple6 with Hash::{hash_combine}

///|
#deprecated("Use `@debug.Debug` instead of `Show` for collections", skip_current_package=true)
#doc(hidden)
pub extend Tuple6 with Show::{to_string, output}

///|
#deprecated("Use `ToJson::to_json` instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple6 with ToJson::{to_json}

///|
#deprecated("Use the comparison operators (`<`, `<=`, `>=`, `>`) instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple7 with Compare::{op_lt, op_le, op_ge, op_gt}

///|
#deprecated("Use `Hash::hash_combine` instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple7 with Hash::{hash_combine}

///|
#deprecated("Use `@debug.Debug` instead of `Show` for collections", skip_current_package=true)
#doc(hidden)
pub extend Tuple7 with Show::{to_string, output}

///|
#deprecated("Use `ToJson::to_json` instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple7 with ToJson::{to_json}

///|
#deprecated("Use the comparison operators (`<`, `<=`, `>=`, `>`) instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple8 with Compare::{op_lt, op_le, op_ge, op_gt}

///|
#deprecated("Use `@debug.Debug` instead of `Show` for collections", skip_current_package=true)
#doc(hidden)
pub extend Tuple8 with Show::{to_string, output}

///|
#deprecated("Use `ToJson::to_json` instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple8 with ToJson::{to_json}

///|
#deprecated("Use the comparison operators (`<`, `<=`, `>=`, `>`) instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple9 with Compare::{op_lt, op_le, op_ge, op_gt}

///|
#deprecated("Use `@debug.Debug` instead of `Show` for collections", skip_current_package=true)
#doc(hidden)
pub extend Tuple9 with Show::{to_string, output}

///|
#deprecated("Use `ToJson::to_json` instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple9 with ToJson::{to_json}

///|
#deprecated("Use the comparison operators (`<`, `<=`, `>=`, `>`) instead", skip_current_package=true)
#doc(hidden)
pub extend UInt with Compare::{op_lt, op_le, op_ge, op_gt}

///|
#deprecated("Use `Hash::hash_combine` instead", skip_current_package=true)
#doc(hidden)
pub extend UInt with Hash::{hash_combine}

///|
#deprecated("Use `Show::output` via the trait or `to_string` instead", skip_current_package=true)
#doc(hidden)
pub extend UInt with Show::{output}

///|
#deprecated("Use the comparison operators (`<`, `<=`, `>=`, `>`) instead", skip_current_package=true)
#doc(hidden)
pub extend UInt16 with Compare::{op_lt, op_le, op_ge, op_gt}

///|
#deprecated("Use `Default::default` instead", skip_current_package=true)
#doc(hidden)
pub extend UInt16 with Default::{default}

///|
#deprecated("Use `Hash::hash_combine` instead", skip_current_package=true)
#doc(hidden)
pub extend UInt16 with Hash::{hash_combine}

///|
#deprecated("Use `Show::output` via the trait or `to_string` instead", skip_current_package=true)
#doc(hidden)
pub extend UInt16 with Show::{output}

///|
#deprecated("Use the comparison operators (`<`, `<=`, `>=`, `>`) instead", skip_current_package=true)
#doc(hidden)
pub extend UInt64 with Compare::{op_lt, op_le, op_ge, op_gt}

///|
#deprecated("Use `Default::default` instead", skip_current_package=true)
#doc(hidden)
pub extend UInt64 with Default::{default}

///|
#deprecated("Use `Hash::hash_combine` instead", skip_current_package=true)
#doc(hidden)
pub extend UInt64 with Hash::{hash_combine}

///|
#deprecated("Use `Show::output` via the trait or `to_string` instead", skip_current_package=true)
#doc(hidden)
pub extend UInt64 with Show::{output}

///|
#deprecated("Use the comparison operators (`<`, `<=`, `>=`, `>`) instead", skip_current_package=true)
#doc(hidden)
pub extend Unit with Compare::{op_lt, op_le, op_ge, op_gt}

///|
#deprecated("Use `Default::default` instead", skip_current_package=true)
#doc(hidden)
pub extend Unit with Default::{default}

///|
#deprecated("Use `Hash::hash_combine` instead", skip_current_package=true)
#doc(hidden)
pub extend Unit with Hash::{hash_combine}

///|
#deprecated("Use `Show::output` via the trait or `to_string` instead", skip_current_package=true)
#doc(hidden)
pub extend Unit with Show::{output}
