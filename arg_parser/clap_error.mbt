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
/// Errors raised during parsing or decoding of arguments.
pub(all) suberror ArgumentError {
  UnknownArgument(String, String?)
  InvalidArgument(String)
  MissingValue(String)
  MissingRequired(String)
  TooFewValues(String, Int, Int)
  TooManyValues(String, Int, Int)
  TooManyPositionals
  InvalidValue(String)
  InvalidValueCount(String)
  MissingGroup(String)
  GroupConflict(String)
} derive(Show)

///|
/// Errors raised when building argument specifications.
pub suberror ArgBuildError {
  Unsupported(String)
} derive(Show)

///|
/// Errors raised when parsing command lines.
pub suberror CommandError {
  Arg(ArgumentError)
  Build(ArgBuildError)
  Help(String)
} derive(Show)
